import Foundation
import AppKit
import Combine

@MainActor
class ScreenCaptureManager: NSObject, ObservableObject {
    @Published var currentScreenshot: NSImage?
    @Published var screenDescription: String = ""
    @Published var isCapturing: Bool = false

    private var captureTimer: Timer?
    private let captureInterval: TimeInterval = 30 // Capture every 30 seconds

    func startCapturing() {
        guard !isCapturing else { return }
        isCapturing = true

        // Capture immediately
        Task { @MainActor in
            self.captureScreen()
        }

        // Then capture periodically
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

    private func captureScreen() {
        // Screen capture placeholder
        // In production, use ScreenCaptureKit for modern macOS
        // For now, just update the description timestamp
        describeScreen(NSImage())
    }

    private func describeScreen(_ image: NSImage) {
        // TODO: Send to Claude Vision API
        screenDescription = "Screen captured at \(Date().formatted())"
    }
}
