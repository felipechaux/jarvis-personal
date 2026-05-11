import SwiftUI

@main
struct JarvisApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var voiceManager = VoiceManager()
    @StateObject private var screenManager = ScreenCaptureManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(chatManager)
                .environmentObject(voiceManager)
                .environmentObject(screenManager)
                .frame(minWidth: 500, idealWidth: 600, maxWidth: 700, minHeight: 600, idealHeight: 800, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
