import SwiftUI
import WidgetKit
import AppIntents

struct RemoteEntry: TimelineEntry {
    let date: Date
}

struct RemoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemoteEntry { RemoteEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (RemoteEntry) -> Void) {
        completion(RemoteEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemoteEntry>) -> Void) {
        completion(Timeline(entries: [RemoteEntry(date: .now)], policy: .never))
    }
}

/// Interactive Home Screen widget: every button sends straight to the iPad without opening the app.
struct RemoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.ldiazbusquets.ldbremote.widget", provider: RemoteProvider()) { _ in
            RemoteWidgetView()
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("iPad Remote")
        .description("Play, skip and volume for your iPad.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RemoteWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    WidgetButton(command: .previous)
                    WidgetButton(command: .next)
                }
                HStack(spacing: 8) {
                    WidgetButton(command: .playPause, prominent: true)
                    WidgetButton(command: .mute)
                }
            }
        default:
            VStack(spacing: 10) {
                HStack {
                    Text("LDB")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("iPad")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                HStack(spacing: 10) {
                    WidgetButton(command: .previous)
                    WidgetButton(command: .playPause, prominent: true)
                    WidgetButton(command: .next)
                    WidgetButton(command: .sleep)
                }
                HStack(spacing: 10) {
                    WidgetButton(command: .volumeDown)
                    WidgetButton(command: .mute)
                    WidgetButton(command: .volumeUp)
                    WidgetButton(command: .home)
                }
            }
        }
    }
}

struct WidgetButton: View {
    let command: RemoteCommand
    var prominent = false

    var body: some View {
        Button(intent: SendRemoteCommandIntent(command)) {
            Image(systemName: command.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(command == .sleep ? Color(red: 1, green: 0.42, blue: 0.42) : .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Circle()
                        .fill(.white.opacity(prominent ? 0.2 : 0.08))
                        .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(command.title)
    }
}
