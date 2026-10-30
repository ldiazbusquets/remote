import SwiftUI
import AppIntents

@main
struct LDBRemoteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

/// Makes the commands available to Siri and the Shortcuts app.
struct LDBRemoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendRemoteCommandIntent(),
            phrases: [
                "\(\.$command) on iPad with \(.applicationName)",
                "Send \(\.$command) with \(.applicationName)",
            ],
            shortTitle: "Send to iPad",
            systemImageName: "appletvremote.gen4.fill"
        )
    }
}
