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
    static let coralPrimary = Color(red: 0.847, green: 0.353, blue: 0.188)
    static let coralLight = Color(red: 0.941, green: 0.600, blue: 0.482)
    static let coralDark = Color(red: 0.600, green: 0.235, blue: 0.114)
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
    @State private var modelSearchQuery: String = ""
    @State private var showModelSearch: Bool = false

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
            chatManager.setScreenManager(screenManager)
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

            // Model Selection with Search
            VStack(alignment: .leading, spacing: 10) {
                Text("Model")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.7))

                VStack(alignment: .leading, spacing: 8) {
                    // Selected model display
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(0.5)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(getProviderColor(chatManager.selectedModel))
                                .frame(width: 5, height: 5)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(chatManager.selectedModel.split(separator: "/").last.map(String.init) ?? chatManager.selectedModel)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)

                                Text(chatManager.selectedModel.split(separator: "/").first.map(String.init) ?? "")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(6)
                    }

                    // Search field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        TextField("Search models...", text: $modelSearchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white)

                        if !modelSearchQuery.isEmpty {
                            Button(action: { modelSearchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)

                    // Filtered models list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredModels(), id: \.self) { model in
                                Button(action: {
                                    chatManager.selectedModel = model
                                    modelSearchQuery = ""
                                    showModelSearch = false
                                }) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(getProviderColor(model))
                                            .frame(width: 4, height: 4)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(model.split(separator: "/").last.map(String.init) ?? model)
                                                .font(.system(size: 11, weight: .medium))
                                                .lineLimit(1)

                                            Text(model.split(separator: "/").first.map(String.init) ?? "")
                                                .font(.system(size: 9, weight: .regular))
                                                .foregroundColor(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        if chatManager.selectedModel == model {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(chatManager.selectedModel == model ? Color.white.opacity(0.15) : Color.clear)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }

                            if filteredModels().isEmpty {
                                Text("No models found")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 180)
                }
                .padding(10)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
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

    private func filteredModels() -> [String] {
        let allModels = chatManager.availableModels.values.flatMap { $0 }

        if modelSearchQuery.isEmpty {
            return allModels
        }

        let query = modelSearchQuery.lowercased()
        return allModels.filter { model in
            let modelName = model.lowercased()
            let provider = model.split(separator: "/").first.map(String.init)?.lowercased() ?? ""
            let displayName = model.split(separator: "/").last.map(String.init)?.lowercased() ?? ""

            return modelName.contains(query) ||
                   provider.contains(query) ||
                   displayName.contains(query)
        }
    }

    private func getProviderColor(_ model: String) -> Color {
        let provider = model.split(separator: "/").first.map(String.init) ?? ""
        switch provider.lowercased() {
        case "gemini":
            return Color(red: 0.847, green: 0.353, blue: 0.188)
        case "openrouter":
            return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "nvidia":
            return Color(red: 0.76, green: 0.80, blue: 0.24)
        case "ollama":
            return Color(red: 0.34, green: 0.34, blue: 0.34)
        default:
            return Color.white
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

// MARK: - Waveform Bar

struct WaveformBar: View {
    let index: Int
    let state: AgentState
    let volume: Double

    @State private var height: CGFloat = 4

    var timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.coralPrimary.opacity(state == .listening ? 0.55 : 1.0))
            .frame(width: 2.5, height: height)
            .animation(.easeInOut(duration: 0.04), value: height)
            .onReceive(timer) { _ in
                updateHeight()
            }
    }

    private func updateHeight() {
        guard state == .listening || state == .talking else {
            height = 4; return
        }
        let maxH: Double = state == .talking ? 28 : 14
        let v = max(volume, 0.25)
        let phase = Double(index) * 0.45 + Date().timeIntervalSinceReferenceDate * 4.5
        let raw = 4 + abs(sin(phase)) * maxH * v + Double.random(in: 0...3) * v
        height = CGFloat(raw)
    }
}

// MARK: - Rotating Arc Ring

struct ArcRing: View {
    let radius: CGFloat
    let dashLen: Double
    let speed: Double
    let color: Color
    let lineWidth: CGFloat
    let state: AgentState

    @State private var rotation: Double = 0

    var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    var effectiveSpeed: Double {
        state == .thinking ? speed * 2.2 : speed
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: dashLen)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(rotation))
            .onReceive(timer) { _ in
                rotation += effectiveSpeed * 360 / 60
            }
    }
}

// MARK: - Liquid Orb Canvas (NSView-backed for CADisplayLink)

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
            DispatchQueue.main.async { view.tick() }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(dl)
    }

    deinit {
        if let dl = displayLink { CVDisplayLinkStop(dl) }
    }

    private func tick() {
        t += 1
        setNeedsDisplay(bounds)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width, h = bounds.height
        let cx = w / 2, cy = h / 2
        let baseR = min(w, h) * 0.30

        let pulse: Double
        switch state {
        case .idle:      pulse = 1 + sin(t * 0.018) * 0.012
        case .listening: pulse = 1 + sin(t * 0.04) * 0.025 + volume * 0.06
        case .thinking:  pulse = 1 + sin(t * 0.025) * 0.018
        case .talking:   pulse = 1 + sin(t * 0.055) * 0.04 + volume * 0.09
        }
        let r = baseR * pulse

        let glowAlpha = state == .idle ? 0.06 : 0.12 + volume * 0.08
        for i in stride(from: 3, through: 1, by: -1) {
            let gr = r + Double(i) * 18 + volume * 12
            drawRadialGlow(ctx: ctx, cx: cx, cy: cy, r: r, outerR: gr, alpha: glowAlpha * Double(4 - i) * 0.28)
        }

        let blobPts = makeBlobPoints(cx: cx, cy: cy, r: r, n: 80)
        let path = CGMutablePath()
        path.move(to: blobPts[0])
        for i in 1..<blobPts.count {
            let prev = blobPts[i - 1]
            let curr = blobPts[i]
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
        }
        path.closeSubpath()

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        drawOrbGradient(ctx: ctx, cx: cx, cy: cy, r: r)
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        drawSpecular(ctx: ctx, cx: cx, cy: cy, r: r)
        ctx.restoreGState()
    }

    private func makeBlobPoints(cx: CGFloat, cy: CGFloat, r: CGFloat, n: Int) -> [CGPoint] {
        (0...n).map { i in
            let angle = Double(i) / Double(n) * .pi * 2
            var dist = Double(r)
            switch state {
            case .idle:
                dist += sin(angle * 2.3 + t * 0.015) * Double(r) * 0.012
                dist += sin(angle * 3.7 + t * 0.009) * Double(r) * 0.008
            case .listening:
                dist += sin(angle * 3 + t * 0.03) * Double(r) * 0.022
                dist += sin(angle * 5 + t * 0.02) * Double(r) * 0.012
                dist += volume * Double(r) * 0.04 * sin(angle * 4 + t * 0.08)
            case .thinking:
                dist += sin(angle * 2 + t * 0.022) * Double(r) * 0.03
                dist += sin(angle * 4 - t * 0.016) * Double(r) * 0.02
                dist += sin(angle * 6 + t * 0.011) * Double(r) * 0.012
            case .talking:
                dist += sin(angle * 3 + t * 0.06) * Double(r) * (0.03 + volume * 0.05)
                dist += sin(angle * 5 + t * 0.05) * Double(r) * (0.02 + volume * 0.04)
                dist += sin(angle * 7 + t * 0.08) * Double(r) * volume * 0.03
            }
            return CGPoint(
                x: cx + CGFloat(cos(angle) * dist),
                y: cy + CGFloat(sin(angle) * dist)
            )
        }
    }

    private func drawRadialGlow(ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, outerR: Double, alpha: Double) {
        let colors = [CGColor(red: 0.847, green: 0.353, blue: 0.188, alpha: CGFloat(alpha)),
                      CGColor(red: 0.847, green: 0.353, blue: 0.188, alpha: 0)]
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors as CFArray,
                                    locations: [0, 1]) else { return }
        ctx.drawRadialGradient(grad,
                               startCenter: CGPoint(x: cx, y: cy), startRadius: r * 0.5,
                               endCenter: CGPoint(x: cx, y: cy), endRadius: CGFloat(outerR),
                               options: [])
    }

    private func drawOrbGradient(ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        let (c0, c1, c2): (CGColor, CGColor, CGColor)
        switch state {
        case .idle:
            c0 = CGColor(red: 0.961, green: 0.690, blue: 0.565, alpha: 1)
            c1 = CGColor(red: 0.878, green: 0.439, blue: 0.231, alpha: 1)
            c2 = CGColor(red: 0.545, green: 0.180, blue: 0.055, alpha: 1)
        case .listening:
            c0 = CGColor(red: 0.973, green: 0.773, blue: 0.659, alpha: 1)
            c1 = CGColor(red: 0.910, green: 0.502, blue: 0.314, alpha: 1)
            c2 = CGColor(red: 0.612, green: 0.227, blue: 0.082, alpha: 1)
        case .thinking:
            c0 = CGColor(red: 0.925, green: 0.659, blue: 0.518, alpha: 1)
            c1 = CGColor(red: 0.784, green: 0.376, blue: 0.188, alpha: 1)
            c2 = CGColor(red: 0.478, green: 0.141, blue: 0.031, alpha: 1)
        case .talking:
            let v = min(volume * 1.2, 1.0)
            let r0 = 0.961 + v * 0.039
            let g0 = 0.690 + v * 0.118
            c0 = CGColor(red: r0, green: g0, blue: 0.706, alpha: 1)
            c1 = CGColor(red: 0.910 + v * 0.09, green: 0.502 + v * 0.125, blue: 0.392, alpha: 1)
            c2 = CGColor(red: 0.545, green: 0.180, blue: 0.055, alpha: 1)
        }
        let colors = [c0, c1, c2] as CFArray
        let locs: [CGFloat] = [0, 0.45, 1]
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors, locations: locs) else { return }
        let startPt = CGPoint(x: cx - r * 0.28, y: cy - r * 0.25)
        ctx.drawRadialGradient(grad,
                               startCenter: startPt, startRadius: r * 0.05,
                               endCenter: CGPoint(x: cx, y: cy), endRadius: r * 1.05,
                               options: [])
    }

    private func drawSpecular(ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        let colors = [CGColor(red: 1, green: 0.941, blue: 0.902, alpha: 0.38),
                      CGColor(red: 1, green: 0.863, blue: 0.784, alpha: 0.10),
                      CGColor(red: 1, green: 0.863, blue: 0.784, alpha: 0)] as CFArray
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors, locations: [0, 0.5, 1]) else { return }
        let sc = CGPoint(x: cx - r * 0.32, y: cy - r * 0.30)
        ctx.drawRadialGradient(grad,
                               startCenter: sc, startRadius: 0,
                               endCenter: sc, endRadius: r * 0.6,
                               options: [])
    }
}

// MARK: - NSView wrapper for SwiftUI

struct OrbCanvas: NSViewRepresentable {
    let state: AgentState
    let volume: Double

    func makeNSView(context: Context) -> OrbView { OrbView() }

    func updateNSView(_ view: OrbView, context: Context) {
        view.state = state
        view.volume = volume
    }
}

// MARK: - Main SamanthaOrb View

struct SamanthaOrb: View {
    @Binding var state: AgentState
    @Binding var volume: Double

    @State private var glowOpacity: Double = 0.0
    @State private var dotOn = false

    var dotTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.bgCream.ignoresSafeArea()

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
                Text("Jarvis")
                    .font(.system(size: 10, weight: .regular))
                    .kerning(3.5)
                    .foregroundColor(Color.textSecondary.opacity(0.55))
                    .padding(.bottom, 20)

                ZStack {
                    ArcRing(radius: 110, dashLen: 0.18, speed: 0.06, color: Color.coralPrimary.opacity(0.22), lineWidth: 1.2, state: state)
                    ArcRing(radius: 110, dashLen: 0.10, speed: -0.04, color: Color.coralPrimary.opacity(0.14), lineWidth: 1.0, state: state)
                    ArcRing(radius: 125, dashLen: 0.13, speed: -0.05, color: Color.coralLight.opacity(0.15), lineWidth: 0.8, state: state)
                    ArcRing(radius: 125, dashLen: 0.07, speed: 0.035, color: Color.coralLight.opacity(0.10), lineWidth: 0.7, state: state)

                    OrbCanvas(state: state, volume: volume)
                        .frame(width: 160, height: 160)
                }
                .frame(width: 240, height: 240)

                HStack(spacing: 3.5) {
                    ForEach(0..<9, id: \.self) { i in
                        WaveformBar(index: i, state: state, volume: volume)
                    }
                }
                .frame(height: 32)
                .opacity((state == .listening || state == .talking) ? 1 : 0.2)
                .animation(.easeInOut(duration: 0.3), value: state)
                .padding(.top, 12)
            }
            .padding(32)
        }
        .onReceive(dotTimer) { _ in
            if state != .idle { dotOn.toggle() }
        }
    }
}
