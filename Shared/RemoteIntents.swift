import AppIntents

extension RemoteCommand: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Remote Command"

    static var caseDisplayRepresentations: [RemoteCommand: DisplayRepresentation] = [
        .playPause: DisplayRepresentation(title: "Play/Pause", image: .init(systemName: "playpause.fill")),
        .next: DisplayRepresentation(title: "Next", image: .init(systemName: "forward.end.fill")),
        .previous: DisplayRepresentation(title: "Previous", image: .init(systemName: "backward.end.fill")),
        .seekForward: DisplayRepresentation(title: "Forward 10s", image: .init(systemName: "goforward.10")),
        .seekBackward: DisplayRepresentation(title: "Back 10s", image: .init(systemName: "gobackward.10")),
        .volumeUp: DisplayRepresentation(title: "Volume Up", image: .init(systemName: "plus")),
        .volumeDown: DisplayRepresentation(title: "Volume Down", image: .init(systemName: "minus")),
        .mute: DisplayRepresentation(title: "Mute", image: .init(systemName: "speaker.slash.fill")),
        .up: DisplayRepresentation(title: "Up", image: .init(systemName: "chevron.up")),
        .down: DisplayRepresentation(title: "Down", image: .init(systemName: "chevron.down")),
        .left: DisplayRepresentation(title: "Left", image: .init(systemName: "chevron.left")),
        .right: DisplayRepresentation(title: "Right", image: .init(systemName: "chevron.right")),
        .select: DisplayRepresentation(title: "Select", image: .init(systemName: "circle.fill")),
        .back: DisplayRepresentation(title: "Back", image: .init(systemName: "arrow.uturn.backward")),
        .home: DisplayRepresentation(title: "Home", image: .init(systemName: "house.fill")),
        .sleep: DisplayRepresentation(title: "Screen Off", image: .init(systemName: "power")),
    ]
}

/// The one action every widget, Control Center button and Shortcut runs.
struct SendRemoteCommandIntent: AppIntent {
    static var title: LocalizedStringResource = "Send to iPad"
    static var description = IntentDescription("Presses a button on your iPad running LDB Remote.")
    static var openAppWhenRun = false

    @Parameter(title: "Command", default: .playPause)
    var command: RemoteCommand

    init() {}

    init(_ command: RemoteCommand) {
        self.command = command
    }

    func perform() async throws -> some IntentResult {
        try await RemoteLink.sendOnce(command)
        return .result()
    }
}
