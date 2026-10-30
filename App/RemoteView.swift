import SwiftUI

/// The iPhone remote: compact glass layout on an 8-point grid.
struct RemoteView: View {
    var onLogoLongPress: () -> Void

    @StateObject private var client = RemoteClient()
    @Environment(\.scenePhase) private var scenePhase
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 16) {
            header
            Spacer(minLength: 0)
            dPad
            navRow
            transportBar
            volumeBar
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: 420)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .onAppear { client.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { client.start() } else if phase == .background { client.stop() }
        }
    }

    private func press(_ command: RemoteCommand) {
        taps += 1
        client.send(command)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            LDBMark()
                .onLongPressGesture(perform: onLogoLongPress)
            Spacer()
            StatusPill(text: statusText, isGood: client.isConnected)
        }
        .frame(height: 32)
    }

    private var statusText: String {
        switch client.state {
        case .searching: "Looking for iPad…"
        case .connecting: "Connecting…"
        case .connected(let name): client.status?.asleep == true ? "\(name) · screen off" : name
        }
    }

    // MARK: D-pad

    private var dPad: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .ldbGlass(Circle())
            VStack {
                arrow(.up)
                Spacer()
                arrow(.down)
            }
            .padding(.vertical, 8)
            HStack {
                arrow(.left)
                Spacer()
                arrow(.right)
            }
            .padding(.horizontal, 8)
            Button { press(.select) } label: {
                Text("OK")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1)
                    .frame(width: 76, height: 76)
                    .contentShape(Circle())
            }
            .buttonStyle(PressStyle())
            .ldbGlass(Circle(), interactive: true)
        }
        .frame(width: 216, height: 216)
        .foregroundStyle(.white)
    }

    private func arrow(_ command: RemoteCommand) -> some View {
        Button { press(command) } label: {
            Image(systemName: command.symbol)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(command.title)
    }

    // MARK: Rows

    private var navRow: some View {
        HStack {
            roundButton(.back)
            Spacer()
            roundButton(.home)
            Spacer()
            roundButton(.mute)
            Spacer()
            roundButton(.sleep)
        }
        .padding(.horizontal, 8)
    }

    private var transportBar: some View {
        HStack {
            barButton(.seekBackward)
            Spacer()
            barButton(.previous)
            Spacer()
            Button { press(.playPause) } label: {
                Image(systemName: RemoteCommand.playPause.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.white.opacity(0.16)))
                    .contentShape(Circle())
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel(RemoteCommand.playPause.title)
            Spacer()
            barButton(.next)
            Spacer()
            barButton(.seekForward)
        }
        .padding(8)
        .ldbGlass(Capsule())
        .foregroundStyle(.white)
    }

    private var volumeBar: some View {
        HStack {
            barButton(.volumeDown)
            Spacer()
            Label("Volume", systemImage: "speaker.wave.2.fill")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            barButton(.volumeUp)
        }
        .padding(8)
        .ldbGlass(Capsule())
        .foregroundStyle(.white)
    }

    private func roundButton(_ command: RemoteCommand) -> some View {
        Button { press(command) } label: {
            Image(systemName: command.symbol)
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
        .ldbGlass(Circle(), interactive: true)
        .foregroundStyle(command == .sleep ? Color(red: 1, green: 0.42, blue: 0.42) : .white)
        .accessibilityLabel(command.title)
    }

    private func barButton(_ command: RemoteCommand) -> some View {
        Button { press(command) } label: {
            Image(systemName: command.symbol)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(command.title)
    }
}
