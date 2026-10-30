import Foundation

/// Every button the remote can press. Sent over the wire by its raw value.
enum RemoteCommand: String, Codable, CaseIterable, Sendable {
    case playPause, next, previous, seekForward, seekBackward
    case volumeUp, volumeDown, mute
    case up, down, left, right, select, back, home
    case sleep

    var title: String {
        switch self {
        case .playPause: "Play/Pause"
        case .next: "Next"
        case .previous: "Previous"
        case .seekForward: "Forward 10s"
        case .seekBackward: "Back 10s"
        case .volumeUp: "Volume Up"
        case .volumeDown: "Volume Down"
        case .mute: "Mute"
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .select: "Select"
        case .back: "Back"
        case .home: "Home"
        case .sleep: "Screen Off"
        }
    }

    var symbol: String {
        switch self {
        case .playPause: "playpause.fill"
        case .next: "forward.end.fill"
        case .previous: "backward.end.fill"
        case .seekForward: "goforward.10"
        case .seekBackward: "gobackward.10"
        case .volumeUp: "plus"
        case .volumeDown: "minus"
        case .mute: "speaker.slash.fill"
        case .up: "chevron.up"
        case .down: "chevron.down"
        case .left: "chevron.left"
        case .right: "chevron.right"
        case .select: "circle.fill"
        case .back: "arrow.uturn.backward"
        case .home: "house.fill"
        case .sleep: "power"
        }
    }
}

/// What the iPad reports back to the iPhone.
struct ReceiverStatus: Codable, Sendable, Equatable {
    var deviceName: String
    var asleep: Bool
    var lastCommand: RemoteCommand?
}

/// One newline-delimited JSON message on the TCP connection.
struct WireMessage: Codable, Sendable {
    enum Kind: String, Codable, Sendable { case command, status, ping }
    var kind: Kind
    var command: RemoteCommand? = nil
    var status: ReceiverStatus? = nil
}

enum Wire {
    /// Bonjour service type. Must match NSBonjourServices in project.yml.
    static let serviceType = "_ldbremote._tcp"

    static func frame(_ message: WireMessage) -> Data {
        var data = (try? JSONEncoder().encode(message)) ?? Data()
        data.append(0x0A)
        return data
    }
}

/// Splits an incoming byte stream into WireMessages at newlines.
final class LineReader {
    private var buffer = Data()

    func feed(_ data: Data) -> [WireMessage] {
        buffer.append(data)
        var messages: [WireMessage] = []
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<newline]
            buffer.removeSubrange(buffer.startIndex...newline)
            if let message = try? JSONDecoder().decode(WireMessage.self, from: Data(line)) {
                messages.append(message)
            }
        }
        return messages
    }
}
