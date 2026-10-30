import Foundation
import Network
import UIKit

/// Runs on the iPad: advertises itself on the local network and handles incoming commands.
@MainActor
final class ReceiverServer: ObservableObject {
    struct LogEntry: Identifiable {
        let id = UUID()
        let command: RemoteCommand
        let date: Date
    }

    @Published private(set) var isListening = false
    @Published private(set) var connectedRemotes = 0
    @Published private(set) var lastCommand: RemoteCommand?
    @Published private(set) var log: [LogEntry] = []
    @Published private(set) var asleep = false

    private let queue = DispatchQueue(label: "ldb.remote.receiver")
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private var readers: [ObjectIdentifier: LineReader] = [:]
    private var savedBrightness: CGFloat = 0.6

    func start() {
        guard listener == nil else { return }
        do {
            let listener = try NWListener(using: .tcp)
            listener.service = NWListener.Service(name: UIDevice.current.name, type: Wire.serviceType)
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in self?.listenerChanged(state) }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.accept(connection) }
            }
            self.listener = listener
            listener.start(queue: queue)
        } catch {
            retryLater()
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
        readers.removeAll()
        isListening = false
        connectedRemotes = 0
    }

    /// Wakes the screen from a tap on the iPad itself.
    func wake() {
        guard asleep else { return }
        asleep = false
        UIScreen.main.brightness = savedBrightness
        broadcastStatus()
    }

    // MARK: - Listener

    private func listenerChanged(_ state: NWListener.State) {
        switch state {
        case .ready:
            isListening = true
        case .failed, .cancelled:
            isListening = false
            listener?.cancel()
            listener = nil
            retryLater()
        default:
            break
        }
    }

    private func retryLater() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.start() }
    }

    // MARK: - Connections

    private func accept(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        connections[id] = connection
        readers[id] = LineReader()
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .failed, .cancelled:
                    self.remove(id)
                default:
                    break
                }
                self.connectedRemotes = self.connections.count
            }
        }
        connection.start(queue: queue)
        receive(on: connection, id: id)
        connectedRemotes = connections.count
    }

    private func receive(on connection: NWConnection, id: ObjectIdentifier) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self, let reader = self.readers[id] else { return }
                if let data, !data.isEmpty {
                    for message in reader.feed(data) {
                        self.handle(message, from: connection)
                    }
                }
                if isComplete || error != nil {
                    self.remove(id)
                } else {
                    self.receive(on: connection, id: id)
                }
            }
        }
    }

    private func remove(_ id: ObjectIdentifier) {
        connections[id]?.cancel()
        connections[id] = nil
        readers[id] = nil
        connectedRemotes = connections.count
    }

    // MARK: - Commands

    private func handle(_ message: WireMessage, from connection: NWConnection) {
        if message.kind == .command, let command = message.command {
            perform(command)
        }
        reply(to: connection)
    }

    private func perform(_ command: RemoteCommand) {
        lastCommand = command
        log.insert(LogEntry(command: command, date: Date()), at: 0)
        if log.count > 6 { log.removeLast(log.count - 6) }

        // Any button wakes the screen.
        if asleep {
            wake()
            return
        }

        switch command {
        case .sleep:
            savedBrightness = UIScreen.main.brightness
            asleep = true
            UIScreen.main.brightness = 0
        default:
            // Media and navigation commands are handled by the receiver's player
            // in a later version. Netflix, Spotify, etc. run through the Shortcuts setup.
            break
        }
        broadcastStatus()
    }

    private var currentStatus: ReceiverStatus {
        ReceiverStatus(deviceName: UIDevice.current.name, asleep: asleep, lastCommand: lastCommand)
    }

    private func reply(to connection: NWConnection) {
        let data = Wire.frame(WireMessage(kind: .status, status: currentStatus))
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    private func broadcastStatus() {
        connections.values.forEach { reply(to: $0) }
    }
}
