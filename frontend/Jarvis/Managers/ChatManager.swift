import Foundation
import Combine

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentResponse: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedProvider: String = "gemini"
    @Published var availableModels: [String: [String]] = [:]
    @Published var selectedModel: String = "gemini/gemini-2.5-flash"
    @Published var errorMessage: String?

    private let backendURL = URL(string: "http://127.0.0.1:8000")!
    private weak var voiceManager: VoiceManager?

    func observeWakeWord() {
        // Listen for wake word detection and send a default query
        Task {
            while true {
                if voiceManager?.wakeWordDetected == true {
                    print("[ChatManager] Wake word detected! Sending query...")
                    voiceManager?.wakeWordDetected = false
                    // Auto-send a query when wake word is detected
                    sendMessage("Hi Jarvis, how can you help me?")
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000)  // Check every 0.1 seconds
            }
        }
    }

    init() {
        // Initialize with default models
        self.availableModels = [
            "gemini": ["gemini/gemini-2.5-flash", "gemini/gemini-2.5-pro", "gemini/gemini-2.0-flash"],
            "openrouter": ["openrouter/anthropic/claude-sonnet-4-6", "openrouter/google/gemini-2.5-pro", "openrouter/meta-llama/llama-3.3-70b"],
            "nvidia": ["nvidia/nemotron-4-340b-instruct"],
            "ollama": []
        ]
        self.selectedProvider = "gemini"
        self.selectedModel = "gemini/gemini-2.5-flash"
        Task {
            await loadModels()
        }
    }

    func setVoiceManager(_ manager: VoiceManager) {
        self.voiceManager = manager
    }

    func loadModels() async {
        // Load models from backend
        do {
            print("[ChatManager] Loading models from \(backendURL.appendingPathComponent("models").absoluteString)")
            let response = try await URLSession.shared.data(
                from: backendURL.appendingPathComponent("models")
            )
            let models = try JSONDecoder().decode([String: [String]].self, from: response.0)
            print("[ChatManager] Loaded models: \(models)")
            DispatchQueue.main.async {
                self.availableModels = models
                print("[ChatManager] Models updated. Selected provider: \(self.selectedProvider)")
                print("[ChatManager] Available for \(self.selectedProvider): \(self.availableModels[self.selectedProvider] ?? [])")
            }
        } catch {
            print("[ChatManager] Failed to load models: \(error)")
        }
    }

    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        messages.append(ChatMessage(role: "user", content: text))
        isLoading = true
        currentResponse = ""
        errorMessage = nil

        Task {
            do {
                let messagesArray = messages.map { ["role": $0.role, "content": $0.content] }

                // Extract provider from model name (e.g., "openrouter/anthropic/claude-sonnet" -> "openrouter")
                let provider = selectedModel.split(separator: "/").first.map(String.init) ?? selectedProvider

                let messageData: [String: Any] = [
                    "messages": messagesArray,
                    "model": selectedModel,
                    "provider": provider,
                    "temperature": 0.7,
                    "max_tokens": 2048,
                ]

                var request = URLRequest(url: backendURL.appendingPathComponent("chat"))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 60  // 60 second timeout
                request.httpBody = try JSONSerialization.data(withJSONObject: messageData)

                print("[ChatManager] Sending request to: \(request.url?.absoluteString ?? "unknown")")
                print("[ChatManager] Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "invalid")")

                let (data, response) = try await URLSession.shared.data(for: request)

                print("[ChatManager] Response status: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                print("[ChatManager] Response data: \(String(data: data, encoding: .utf8) ?? "invalid")")

                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("[ChatManager] Parsed JSON: \(jsonResponse)")
                    print("[ChatManager] JSON Keys: \(jsonResponse.keys.joined(separator: ", "))")

                    if let content = jsonResponse["content"] as? String {
                        DispatchQueue.main.async {
                            self.currentResponse = content
                            self.messages.append(ChatMessage(role: "assistant", content: content))
                            self.isLoading = false
                            // Speak the response
                            self.voiceManager?.speak(content)
                        }
                        return
                    }

                    if let error = jsonResponse["error"] as? String {
                        DispatchQueue.main.async {
                            self.errorMessage = "Backend error: \(error)"
                            self.isLoading = false
                        }
                        return
                    }

                    // Show what we got in the response
                    let responseKeys = jsonResponse.keys.joined(separator: ", ")
                    let responseStr = jsonResponse.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                    DispatchQueue.main.async {
                        self.errorMessage = "Server response missing 'content'. Got: {\(responseStr)}"
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to parse server response"
                        self.isLoading = false
                    }
                }

            } catch let error as URLError {
                print("[ChatManager] URL Error: \(error)")
                DispatchQueue.main.async {
                    switch error.code {
                    case .timedOut:
                        self.errorMessage = "Request timed out (60s). Check your connection or backend."
                    case .notConnectedToInternet:
                        self.errorMessage = "Not connected to internet"
                    case .networkConnectionLost:
                        self.errorMessage = "Network connection lost"
                    default:
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                }
            } catch {
                print("[ChatManager] General Error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func switchProvider(_ provider: String) async {
        selectedProvider = provider
        await loadModels()
        if let models = availableModels[provider]?.first {
            selectedModel = models
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp = Date()
}
