import Foundation
import AVFoundation
import Combine
import AudioToolbox

@MainActor
class VoiceManager: NSObject, ObservableObject {
    @Published var isListening: Bool = false
    @Published var transcript: String = ""
    @Published var isSpeaking: Bool = false
    @Published var errorMessage: String?
    @Published var wakeWordDetected: Bool = false
    @Published var audioLevel: Float = 0.0  // For waveform visualization

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var globalMonitor: Any?
    private var audioMeterTimer: Timer?

    private let wakeWords = ["hey jarvis", "jarvis", "ok jarvis"]

    override init() {
        super.init()
        setupSpeechRecognizer()
        setupGlobalHotkey()
    }

    private func setupSpeechRecognizer() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    break
                case .denied, .notDetermined, .restricted:
                    self.errorMessage = "Speech recognition not authorized"
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Global Hotkey (Cmd+Space)

    private func setupGlobalHotkey() {
        // For production, use a proper hotkey library like Sauce
        // For now, this is a placeholder
        // We'll implement proper hotkey detection in MainView
    }

    // MARK: - Voice Input

    func startListening() {
        guard !isListening else { return }

        isListening = true
        transcript = ""
        errorMessage = nil

        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest
        else {
            errorMessage = "Failed to initialize speech recognition"
            isListening = false
            return
        }

        do {
            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(
                with: recognitionRequest
            ) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        let transcript = result.bestTranscription.formattedString.lowercased()
                        self?.transcript = transcript

                        // Check for wake word
                        let hasWakeWord = self?.wakeWords.contains { transcript.contains($0) } ?? false
                        if hasWakeWord {
                            self?.wakeWordDetected = true
                        }

                        if result.isFinal {
                            self?.stopListening()
                        }
                    }
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.stopListening()
                    }
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
                buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start listening: \(error.localizedDescription)"
            stopListening()
        }
    }

    func stopListening() {
        isListening = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }

    // MARK: - Voice Output (Text-to-Speech)

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)

        // Try premium voices in order of quality
        let voicePreferences = [
            "com.apple.speech.synthesis.voice.Victoria.premium",
            "com.apple.speech.synthesis.voice.Daniel.premium",
            "com.apple.speech.synthesis.voice.Samantha",
            "com.apple.speech.synthesis.voice.Moira",
            "com.apple.speech.synthesis.voice.Fiona"
        ]

        var voiceSet = false
        for voiceId in voicePreferences {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                utterance.voice = voice
                voiceSet = true
                print("[VoiceManager] Using voice: \(voiceId)")
                break
            }
        }

        if !voiceSet {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        // Optimize speech parameters for clarity
        utterance.rate = 0.45  // Slightly slower for better clarity
        utterance.pitchMultiplier = 1.05  // Slightly higher pitch for clarity
        utterance.volume = 1.0

        isSpeaking = true
        speechSynthesizer.delegate = self
        speechSynthesizer.speak(utterance)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - Startup Sound

    func playStartupChime() {
        // Play a minimalist startup chime using system sound
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
            // System alert sound (minimalist chime)
            AudioServicesPlaySystemSound(1104)  // "Ping" sound
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

@MainActor
extension VoiceManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _: AVSpeechSynthesizer,
        didFinish _: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            Task { @MainActor in
                self.isSpeaking = false
            }
        }
    }

    nonisolated func speechSynthesizer(
        _: AVSpeechSynthesizer,
        didCancel _: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            Task { @MainActor in
                self.isSpeaking = false
            }
        }
    }
}

// Import Speech Framework
import Speech
