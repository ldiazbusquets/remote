import Foundation
import Network

/// Fire-and-forget sender used by widgets, Control Center buttons and Shortcuts.
/// Finds the iPad on the local network, sends one command, then closes.
enum RemoteLink {
    struct NotFound: LocalizedError {
        var errorDescription: String? { "Couldn't find your iPad. Open LDB Remote on it and make sure both are on the same Wi-Fi." }
    }

    static func sendOnce(_ command: RemoteCommand, timeout: TimeInterval = 4) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            OneShotSender(command: command, continuation: continuation).start(timeout: timeout)
        }
    }
}

private final class OneShotSender: @unchecked Sendable {
    private let command: RemoteCommand
    private let continuation: CheckedContinuation<Void, Error>
    private let queue = DispatchQueue(label: "ldb.remote.oneshot")
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var finished = false

    init(command: RemoteCommand, continuation: CheckedContinuation<Void, Error>) {
        self.command = command
        self.continuation = continuation
    }

    func start(timeout: TimeInterval) {
        queue.async {
            let browser = NWBrowser(for: .bonjour(type: Wire.serviceType, domain: nil), using: .tcp)
            browser.browseResultsChangedHandler = { results, _ in
                guard self.connection == nil, let result = results.first else { return }
                self.connect(to: result.endpoint)
            }
            browser.stateUpdateHandler = { state in
                if case .failed(let error) = state { self.finish(error) }
            }
            self.browser = browser
            browser.start(queue: self.queue)

            self.queue.asyncAfter(deadline: .now() + timeout) {
                self.finish(RemoteLink.NotFound())
            }
        }
    }

    private func connect(to endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        self.connection = connection
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let message = WireMessage(kind: .command, command: self.command)
                connection.send(content: Wire.frame(message), completion: .contentProcessed { error in
                    // Give the bytes a moment to leave before closing.
                    self.queue.asyncAfter(deadline: .now() + 0.2) { self.finish(error) }
                })
            case .failed(let error):
                self.finish(error)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func finish(_ error: Error?) {
        guard !finished else { return }
        finished = true
        browser?.cancel()
        connection?.cancel()
        browser = nil
        connection = nil
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}
