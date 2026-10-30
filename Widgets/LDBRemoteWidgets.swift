import SwiftUI
import WidgetKit

@main
struct LDBRemoteWidgets: WidgetBundle {
    var body: some Widget {
        RemoteWidget()
        PlayPauseControl()
        NextControl()
        PreviousControl()
        VolumeUpControl()
        VolumeDownControl()
        ScreenOffControl()
    }
}
