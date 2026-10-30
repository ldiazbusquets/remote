import SwiftUI

// MARK: - Glass

extension View {
    /// Apple Liquid Glass on iOS 26+, a frosted-glass look on older systems.
    @ViewBuilder
    func ldbGlass<S: Shape>(_ shape: S, interactive: Bool = false) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.legacyGlass(shape)
        }
        #else
        self.legacyGlass(shape)
        #endif
    }

    private func legacyGlass<S: Shape>(_ shape: S) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(.white.opacity(0.16), lineWidth: 1))
            .overlay(
                shape.stroke(
                    LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center),
                    lineWidth: 1
                )
            )
    }
}

/// Shrinks a button slightly while it's held.
struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Background

/// Black background with slow-drifting soft light, so the glass has something to refract.
struct BlobBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Color.black
            blob(color: Color(red: 0.15, green: 0.22, blue: 0.38), size: 320)
                .offset(x: drift ? -60 : -130, y: drift ? -260 : -330)
            blob(color: Color(white: 0.22), size: 280)
                .offset(x: drift ? 150 : 110, y: drift ? 120 : 200)
            blob(color: Color(red: 0.11, green: 0.16, blue: 0.27), size: 260)
                .offset(x: drift ? -90 : -40, y: drift ? 380 : 320)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func blob(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 70)
            .opacity(0.8)
    }
}

// MARK: - LDB mark

/// Clear-glass LDB lettering used as the top-left signature.
struct LDBMark: View {
    var size: CGFloat = 24

    var body: some View {
        Text("LDB")
            .font(.system(size: size, weight: .black))
            .tracking(-size * 0.06)
            .scaleEffect(x: 1.25, y: 1, anchor: .leading)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white.opacity(0.75), .white.opacity(0.2)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .shadow(color: .white.opacity(0.15), radius: 6)
            .accessibilityLabel("LDB")
    }
}

// MARK: - Status pill

struct StatusPill: View {
    var text: String
    var isGood: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isGood ? Color.white : Color.orange)
                .frame(width: 6, height: 6)
                .shadow(color: isGood ? .white : .orange, radius: 4)
            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .ldbGlass(Capsule())
    }
}
