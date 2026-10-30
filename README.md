# LDB Remote

Turn your iPhone into a remote for your iPad. One universal SwiftUI app: it's the **remote** on iPhone and the **receiver** on iPad.

- **Glass remote** — black background, Liquid Glass bubbles on iOS 26 (frosted glass on iOS 18), LDB mark
- **Direct link** — iPhone ⇄ iPad over your own Wi-Fi with Network.framework + Bonjour. No servers, no accounts
- **Home Screen widget** — interactive buttons (small and medium sizes) that send without opening the app
- **Control Center controls** — Play/Pause, Next, Previous, Volume ±, Screen Off (also Lock Screen and Action Button)
- **Siri and Shortcuts** — "Next on iPad with LDB Remote"
- **iPad screen** — connection status, clock, last button pressed, recent presses, screen-off mode

Long-press the LDB mark to switch a device between remote and receiver.

## What it can and can't control

iOS doesn't let any app send commands into other apps. So this app **does not** control Netflix, HBO Max, Prime Video, Spotify or YouTube on the iPad by itself — those go through the Focus + Shortcuts setup in the companion guide. The receiver currently handles screen-off and logs every press; its own player is next on the roadmap.

## Build and install (no Mac needed)

Every push to `main` builds the app on GitHub's free Mac runners.

1. Open the repo's **Actions** tab → latest **Build IPA** run → download **LDBRemote-ipa** (unzip it to get `LDBRemote.ipa`).
2. Install with [SideStore](https://sidestore.io) (or AltStore) on the iPhone and the iPad using your free Apple ID.
3. Open LDB Remote on the iPad first, then on the iPhone. Allow **Local Network** access on both.

Free Apple ID installs expire after 7 days; SideStore refreshes them in the background.

### With a Mac instead

```
brew install xcodegen
xcodegen generate
open LDBRemote.xcodeproj
```

Pick your team under Signing for both targets, then run on each device.

## Project layout

| Folder | What's in it |
| --- | --- |
| `App/` | SwiftUI app: glass styling, remote screen, iPad receiver, networking client and server |
| `Shared/` | Commands, wire protocol, one-shot sender, App Intents (used by app and widgets) |
| `Widgets/` | Home Screen widget and Control Center controls |
| `project.yml` | XcodeGen project definition (the `.xcodeproj` is generated, not committed) |
| `.github/workflows/build.yml` | Unsigned IPA build on GitHub Actions |

## Roadmap

- [ ] Built-in player on the iPad (YouTube queue, local videos) that obeys every button
- [ ] Optional Apple Music control from the receiver
- [ ] Pairing code so only your iPhone can connect
- [ ] App icon
