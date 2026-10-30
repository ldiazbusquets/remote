import SwiftUI

enum DeviceRole: String {
    case remote, receiver

    static var defaultForDevice: DeviceRole {
        UIDevice.current.userInterfaceIdiom == .pad ? .receiver : .remote
    }
}

struct RootView: View {
    @AppStorage("deviceRole") private var roleRaw = DeviceRole.defaultForDevice.rawValue
    @State private var showRolePicker = false

    private var role: DeviceRole { DeviceRole(rawValue: roleRaw) ?? .defaultForDevice }

    var body: some View {
        ZStack {
            BlobBackground()
            switch role {
            case .remote: RemoteView(onLogoLongPress: { showRolePicker = true })
            case .receiver: ReceiverView(onLogoLongPress: { showRolePicker = true })
            }
        }
        .confirmationDialog("Use this device as", isPresented: $showRolePicker, titleVisibility: .visible) {
            Button("Remote (iPhone)") { roleRaw = DeviceRole.remote.rawValue }
            Button("Receiver (iPad)") { roleRaw = DeviceRole.receiver.rawValue }
            Button("Cancel", role: .cancel) {}
        }
    }
}
