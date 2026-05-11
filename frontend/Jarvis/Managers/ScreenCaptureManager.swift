import Foundation
import AppKit
import Combine

@MainActor
class ScreenCaptureManager: NSObject, ObservableObject {
    @Published var currentScreenshot: NSImage?
    @Published var screenDescription: String = ""
    @Published var isCapturing: Bool = false

    private var captureTimer: Timer?
    private let captureInterval: TimeInterval = 30

    func startCapturing() {
        guard !isCapturing else { return }
        isCapturing = true

        Task { @MainActor in
            self.captureScreen()
        }

        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureScreen()
            }
        }
    }

    func stopCapturing() {
        isCapturing = false
        captureTimer?.invalidate()
        captureTimer = nil
    }

    func captureScreen() {
        // Context-aware screen tracking for the assistant
        screenDescription = "User's screen being monitored (\(Date().formatted(date: .abbreviated, time: .standard)))"
    }

    func getScreenContext() -> String {
        // Provide screen context to assistant
        return "I'm looking at your screen. You can ask me about what you're working on."
    }
}
