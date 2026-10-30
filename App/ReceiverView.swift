import SwiftUI

/// The iPad screen: shows it's ready, what was pressed last, and handles screen-off.
struct ReceiverView: View {
    var onLogoLongPress: () -> Void

    @StateObject private var server = ReceiverServer()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 24) {
                header
                clock
                lastCommandCard
                recentList
                Spacer(minLength: 0)
            }
            .padding(32)
            .foregroundStyle(.white)

            if server.asleep {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture { server.wake() }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: server.asleep)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            server.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { server.start() }
        }
    }

    private var header: some View {
        HStack {
            LDBMark(size: 28)
                .onLongPressGesture(perform: onLogoLongPress)
            Spacer()
            StatusPill(text: statusText, isGood: server.isListening)
        }
    }

    private var statusText: String {
        if !server.isListening { return "Starting…" }
        return server.connectedRemotes > 0 ? "iPhone connected" : "Ready for your iPhone"
    }

    private var clock: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 72, weight: .thin))
                    .monospacedDigit()
                Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var lastCommandCard: some View {
        HStack(spacing: 16) {
            Image(systemName: server.lastCommand?.symbol ?? "appletvremote.gen4.fill")
                .font(.system(size: 26, weight: .semibold))
                .frame(width: 60, height: 60)
                .ldbGlass(Circle())
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 2) {
                Text("Last button")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                Text(server.lastCommand?.title ?? "Waiting for a press")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: 460)
        .ldbGlass(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private var recentList: some View {
        if !server.log.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                ForEach(server.log) { entry in
                    HStack(spacing: 10) {
                        Image(systemName: entry.command.symbol)
                            .frame(width: 20)
                        Text(entry.command.title)
                        Spacer()
                        Text(entry.date, format: .dateTime.hour().minute().second())
                            .foregroundStyle(.white.opacity(0.45))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
            .padding(16)
            .frame(maxWidth: 460)
            .ldbGlass(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
