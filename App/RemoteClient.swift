import Foundation
import Network

/// Keeps a live connection from the iPhone to the iPad while the remote screen is open.
@MainActor
final class RemoteClient: ObservableObject {
    enum State: Equatable {
        case searching
        case connecting
        case connected(String)
    }

    @Published private(set) var state: State = .searching
    @Published private(set) var status: ReceiverStatus?

    private let queue = DispatchQueue(label: "ldb.remote.client")
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var reader = LineReader()
    private var heartbeat: Timer?
    private var lastHeard = Date.distantPast

    var isConnected: Bool {
        if case .connected = state { return true }
        return false
    }

    func start() {
        guard browser == nil else { return }
        state = .searching
        let browser = NWBrowser(for: .bonjour(type: Wire.serviceType, domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in self?.pick(from: results) }
        }
        browser.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                Task { @MainActor in self?.restartBrowser() }
            }
        }
        self.browser = browser
        browser.start(queue: queue)

        heartbeat = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        heartbeat?.invalidate()
        heartbeat = nil
        browser?.cancel()
        browser = nil
        connection?.cancel()
        connection = nil
        state = .searching
    }

    func send(_ command: RemoteCommand) {
        guard isConnected, let connection else {
            // Not connected yet: fall back to the one-shot path so the press isn't lost.
            Task { try? await RemoteLink.sendOnce(command) }
            return
        }
        connection.send(content: Wire.frame(WireMessage(kind: .command, command: command)),
                        completion: .contentProcessed { _ in })
    }

    // MARK: - Private

    private func pick(from results: Set<NWBrowser.Result>) {
        guard connection == nil, let result = results.first else { return }
        var name = "iPad"
        if case let .service(serviceName, _, _, _) = result.endpoint { name = serviceName }
        connect(to: result.endpoint, name: name)
    }

    private func connect(to endpoint: NWEndpoint, name: String) {
        state = .connecting
        reader = LineReader()
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] newState in
            Task { @MainActor in
                guard let self, self.connection === connection else { return }
                switch newState {
                case .ready:
                    self.lastHeard = Date()
                    self.state = .connected(name)
                    connection.send(content: Wire.frame(WireMessage(kind: .ping)), completion: .contentProcessed { _ in })
                case .failed, .cancelled, .waiting:
                    self.dropConnection()
                default:
                    break
                }
            }
        }
        self.connection = connection
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self, self.connection === connection else { return }
                if let data, !data.isEmpty {
                    self.lastHeard = Date()
                    for message in self.reader.feed(data) where message.kind == .status {
                        self.status = message.status
                    }
                }
                if isComplete || error != nil {
                    self.dropConnection()
                } else {
                    self.receive(on: connection)
                }
            }
        }
    }

    private func tick() {
        guard let connection else {
            if let results = browser?.browseResults { pick(from: results) }
            return
        }
        if isConnected {
            connection.send(content: Wire.frame(WireMessage(kind: .ping)), completion: .contentProcessed { _ in })
            if Date().timeIntervalSince(lastHeard) > 9 { dropConnection() }
        }
    }

    private func dropConnection() {
        connection?.cancel()
        connection = nil
        status = nil
        state = .searching
    }

    private func restartBrowser() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.start() }
    }
}
