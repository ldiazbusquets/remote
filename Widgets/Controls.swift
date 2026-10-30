import SwiftUI
import WidgetKit
import AppIntents

/// Control Center / Lock Screen / Action Button controls (iOS 18+).
/// Each one is a separate control so you can place them individually.

private func remoteControl(_ command: RemoteCommand, kind: String) -> some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.ldiazbusquets.ldbremote.control.\(kind)") {
        ControlWidgetButton(action: SendRemoteCommandIntent(command)) {
            Label(command.title, systemImage: command.symbol)
        }
    }
    .displayName(LocalizedStringResource(stringLiteral: "iPad \(command.title)"))
    .description("Sends \(command.title) to your iPad.")
}

struct PlayPauseControl: ControlWidget {
    var body: some ControlWidgetConfiguration { remoteControl(.playPause, kind: "playpause") }
}

struct NextControl: ControlWidget {
    var body: some ControlWidgetConfiguration { remoteControl(.next, kind: "next") }
}

struct PreviousControl: ControlWidget {
    var body: some ControlWidgetConfiguration { remoteControl(.previous, kind: "previous") }
}

struct VolumeUpControl: ControlWidget {
    var body: some ControlWidgetConfiguration { remoteControl(.volumeUp, kind: "volumeup") }
}

struct VolumeDownControl: ControlWidget {
    var body: some ControlWidgetConfiguration { remoteControl(.volumeDown, kind: "volumedown") }
}

struct ScreenOffControl: ControlWidget {
    var body: some ControlWidgetConfiguration { remoteControl(.sleep, kind: "screenoff") }
}
