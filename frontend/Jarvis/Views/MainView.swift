import SwiftUI
import AppKit
import AVFoundation

enum AgentState: String {
    case idle       = "idle"
    case listening  = "listening"
    case thinking   = "thinking"
    case talking    = "talking"
}

extension Color {
    static let bgCream = Color(red: 0.85, green: 0.79, blue: 0.68)
    static let bgBeige = Color(red: 0.81, green: 0.75, blue: 0.65)
    static let coralPrimary = Color(red: 0.78, green: 0.35, blue: 0.26)
    static let textOnCream = Color(red: 0.22, green: 0.16, blue: 0.12)
    static let textSecondary = Color(red: 0.28, green: 0.22, blue: 0.17)
    static let accentWarm = Color(red: 0.85, green: 0.47, blue: 0.30)
}

struct MainView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var voiceManager: VoiceManager
    @EnvironmentObject var screenManager: ScreenCaptureManager

    @State private var userInput: String = ""
    @State private var agentState: AgentState = .idle
    @State private var orbVolume: Double = 0.0

    var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR
            sidebar
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
                .background(Color.coralPrimary)

            // DETAIL
            VStack(spacing: 0) {
                // Main content area
                VStack(spacing: 16) {
                    // Orb
                    SamanthaOrb(state: $agentState, volume: $orbVolume)
                        .frame(height: 200)

                    // Messages
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(message: message)
                            }
                            if chatManager.isLoading {
                                Text("Thinking...")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Input at bottom
                inputArea
                    .background(Color.bgBeige)
            }
            .background(Color.bgCream)
        }
        .onChange(of: voiceManager.isListening) { _ in updateAgentState() }
        .onChange(of: voiceManager.isSpeaking) { _ in updateAgentState() }
        .onChange(of: chatManager.isLoading) { _ in updateAgentState() }
        .onChange(of: voiceManager.audioLevel) { newValue in
            orbVolume = Double(newValue)
        }
        .onAppear {
            chatManager.setVoiceManager(voiceManager)
            chatManager.observeWakeWord()
            screenManager.startCapturing()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                voiceManager.playStartupChime()
            }
            updateAgentState()
        }
        .onDisappear {
            screenManager.stopCapturing()
            voiceManager.stopListening()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Logo/Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Jarvis")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white.opacity(0.95))
                Text("Agent")
                    .font(.system(size: 13, weight: .regular))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 24)

            // Model Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Model")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.7))

                Picker("", selection: $chatManager.selectedModel) {
                    ForEach(["gemini", "openrouter", "nvidia", "ollama"], id: \.self) { provider in
                        if let models = chatManager.availableModels[provider], !models.isEmpty {
                            Section(provider.uppercased()) {
                                ForEach(models, id: \.self) { model in
                                    Text(model.split(separator: "/").last.map(String.init) ?? model)
                                        .font(.system(size: 12, weight: .regular))
                                        .tag(model)
                                }
                            }
                        }
                    }
                }
                .font(.system(size: 12, weight: .regular))
                .accentColor(.white.opacity(0.8))
            }
            .padding(12)
            .background(Color.black.opacity(0.15))
            .cornerRadius(8)

            // Status
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(agentState == .idle ? Color.white.opacity(0.3) : Color.white)
                        .frame(width: 6, height: 6)
                    Text(agentState.rawValue.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)

            Spacer()

            // Voice button
            Button(action: {
                if voiceManager.isListening {
                    userInput = voiceManager.transcript
                    voiceManager.stopListening()
                } else {
                    voiceManager.startListening()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Voice")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(8)
            }
            .foregroundColor(.white)
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var inputArea: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $userInput)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textOnCream)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(6)
                .onSubmit {
                    if !userInput.trimmingCharacters(in: .whitespaces).isEmpty {
                        chatManager.sendMessage(userInput)
                        userInput = ""
                    }
                }

            Button(action: {
                if !userInput.trimmingCharacters(in: .whitespaces).isEmpty {
                    chatManager.sendMessage(userInput)
                    userInput = ""
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentWarm)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }

    private func updateAgentState() {
        if voiceManager.isSpeaking {
            agentState = .talking
        } else if chatManager.isLoading {
            agentState = .thinking
        } else if voiceManager.isListening {
            agentState = .listening
        } else {
            agentState = .idle
        }
    }
}

#Preview {
    MainView()
        .environmentObject(ChatManager())
        .environmentObject(VoiceManager())
        .environmentObject(ScreenCaptureManager())
        .preferredColorScheme(.light)
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == "user" {
                Spacer()
            }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 3) {
                Text(message.content)
                    .textSelection(.enabled)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(nil)
                    .padding(10)
                    .background(
                        message.role == "user"
                            ? Color.accentWarm
                            : Color.white.opacity(0.5)
                    )
                    .cornerRadius(8)
                    .foregroundColor(message.role == "user" ? .white : .textOnCream)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 3)
            }

            if message.role == "assistant" {
                Spacer()
            }
        }
    }
}

// MARK: - SamanthaOrb Components

struct SamanthaOrb: View {
    @Binding var state: AgentState
    @Binding var volume: Double

    @State private var glowOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Background
            Color.bgCream.ignoresSafeArea()

            // Ambient glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.coralPrimary.opacity(state == .talking ? 0.10 : 0.04),
                    Color.clear
                ]),
                center: .center,
                startRadius: 60,
                endRadius: 260
            )
            .animation(.easeInOut(duration: 0.8), value: state)

            VStack(spacing: 0) {
                // Wordmark
                Text("Jarvis")
                    .font(.system(size: 12, weight: .light))
                    .kerning(2)
                    .foregroundColor(Color.textSecondary.opacity(0.55))
                    .padding(.bottom, 20)

                // Orb + rings
                ZStack {
                    // Arc rings
                    ArcRing(radius: 80, dashLen: 0.18, speed: 0.06, color: Color.coralPrimary.opacity(0.22), lineWidth: 1.2, state: state)
                    ArcRing(radius: 80, dashLen: 0.10, speed: -0.04, color: Color.coralPrimary.opacity(0.14), lineWidth: 1.0, state: state)

                    // Canvas orb
                    OrbCanvas(state: state, volume: volume)
                        .frame(width: 140, height: 140)
                }
                .frame(width: 200, height: 200)
            }
        }
    }
}

struct ArcRing: View {
    let radius: CGFloat
    let dashLen: Double
    let speed: Double
    let color: Color
    let lineWidth: CGFloat
    let state: AgentState

    @State private var rotation: Double = 0

    private var effectiveSpeed: Double {
        state == .thinking ? speed * 2.2 : speed
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: dashLen)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(rotation))
            .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
                rotation += effectiveSpeed * 360 / 60
            }
    }
}

final class OrbView: NSView {
    var state: AgentState = .idle { didSet { setNeedsDisplay(bounds) } }
    var volume: Double = 0

    private var t: Double = 0
    private var displayLink: CVDisplayLink?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupDisplayLink()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDisplayLink()
    }

    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let dl = displayLink else { return }
        CVDisplayLinkSetOutputCallback(dl, { _, _, _, _, _, userInfo in
            let view = Unmanaged<OrbView>.fromOpaque(userInfo!).takeUnretainedValue()
            DispatchQueue.main.async { view.setNeedsDisplay(view.bounds) }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(dl)
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)
        t += 0.016

        let w = rect.width, h = rect.height
        let centerX = w / 2, centerY = h / 2
        let baseR: CGFloat = min(w, h) * 0.15

        let path = NSBezierPath()
        let points = makeBlobPoints(center: CGPoint(x: centerX, y: centerY), baseR: baseR)

        guard points.count > 0 else { return }

        path.move(to: points[0])
        for i in 1..<points.count {
            let p1 = points[i - 1]
            let p2 = points[i]
            let cp = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
            path.curve(to: p2, controlPoint1: CGPoint(x: (p1.x + cp.x) / 2, y: (p1.y + cp.y) / 2), controlPoint2: CGPoint(x: (cp.x + p2.x) / 2, y: (cp.y + p2.y) / 2))
        }
        path.close()

        NSColor(red: 0.78, green: 0.35, blue: 0.26, alpha: 0.9).setFill()
        path.fill()
    }

    private func makeBlobPoints(center: CGPoint, baseR: CGFloat) -> [CGPoint] {
        let numPts = 8
        return (0..<numPts).map { i in
            let angle = Double(i) * 2 * .pi / Double(numPts)
            let wobble = 0.03 + 0.05 * sin(t * 2.5 + Double(i)) + 0.04 * volume
            let r = baseR * (1 + wobble)
            return CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
        }
    }
}

struct OrbCanvas: NSViewRepresentable {
    let state: AgentState
    let volume: Double

    func makeNSView(context: Context) -> OrbView { OrbView() }

    func updateNSView(_ view: OrbView, context: Context) {
        view.state = state
        view.volume = volume
    }
}
