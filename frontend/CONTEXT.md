# Jarvis macOS App - Development Context

## Folder Structure

```
frontend/
├── Jarvis/                          # Main app target
│   ├── JarvisApp.swift             # App entry point
│   ├── Managers/
│   │   ├── ChatManager.swift       # Backend WebSocket connection
│   │   ├── VoiceManager.swift      # Speech-to-Text + TTS
│   │   └── ScreenCaptureManager.swift  # Screen capture & vision
│   ├── Views/
│   │   └── MainView.swift          # Main UI
│   └── ...
├── JarvisTests/                     # Tests
└── CONTEXT.md                       # This file
```

---

## Current Architecture

### JarvisApp.swift
- Entry point for the macOS application
- Initializes all managers (ChatManager, VoiceManager, ScreenCaptureManager)
- Sets up window style (minimalist, no title bar)
- Distributes managers as environment objects

### ChatManager.swift
- **Responsibility:** Manage all chat communication with backend
- **Connection:** WebSocket (`ws://127.0.0.1:8000/ws/chat`)
- **Features:**
  - Real-time streaming responses
  - Multi-provider support (OpenRouter, NVIDIA, Ollama)
  - Model selection
  - Conversation history
- **Published Properties:**
  - `messages`: Array of chat messages
  - `currentResponse`: Streaming response text
  - `isLoading`: Whether AI is responding
  - `selectedProvider`: Active LLM provider
  - `availableModels`: Dictionary of provider → models
  - `selectedModel`: Currently selected model

### VoiceManager.swift
- **Responsibility:** Handle voice input/output
- **Speech-to-Text:** Using `SFSpeechRecognizer` (macOS native)
- **Text-to-Speech:** Using `AVSpeechSynthesizer`
- **Hotkey:** Cmd+Space for voice activation (TODO: proper hotkey library)
- **Published Properties:**
  - `isListening`: Currently recording audio
  - `transcript`: Current speech-to-text result
  - `isSpeaking`: Currently playing audio

### ScreenCaptureManager.swift
- **Responsibility:** Capture and understand what's on screen
- **Capture Method:** Native macOS screenshot
- **Periodicity:** Every 30 seconds (configurable)
- **Vision Integration:** TODO - send to Claude Vision API
- **Published Properties:**
  - `currentScreenshot`: Latest NSImage
  - `screenDescription`: AI-generated description
  - `isCapturing`: Whether capturing is active

### MainView.swift
- **Layout:** Minimalist 2-column design
  - Left: Chat conversation area
  - Right: Screen capture preview (optional)
- **Features:**
  - Message bubbles (user vs assistant)
  - Real-time streaming display
  - Voice button (Cmd+Space alternative)
  - Model/Provider selector
  - Error display
  - Timestamps

---

## Key Integrations

### Backend Connection (ChatManager)
```swift
// Sends message via WebSocket
sendMessage("Hello") 
// Backend receives at /ws/chat endpoint
// Streams tokens back in real-time
```

### Voice Input Flow
```
User presses Cmd+Space
  ↓
VoiceManager.startListening() 
  ↓
SFSpeechRecognizer captures audio
  ↓
VoiceManager.transcript updated
  ↓
User stops speaking (detected by recognizer)
  ↓
Message auto-sent to chat
```

### Voice Output Flow
```
ChatManager receives response
  ↓
Display streamed tokens in UI
  ↓
When complete, VoiceManager.speak()
  ↓
AVSpeechSynthesizer plays audio
```

### Screen Vision Flow (TODO)
```
ScreenCaptureManager.startCapturing()
  ↓
Every 30 seconds: capture screenshot
  ↓
Send to Claude Vision API (with user consent)
  ↓
Claude describes what's on screen
  ↓
Store in chatManager context
  ↓
Include in prompts: "User is looking at: [description]"
```

---

## TODO Items

### Priority 1 (Core Functionality)
- [ ] Fix ChatManager WebSocket connection issues
- [ ] Implement proper Cmd+Space hotkey (use `Sauce` library)
- [ ] Test voice input/output (ensure microphone permissions)
- [ ] Create Xcode project file (`.xcodeproj`)
- [ ] Test chat streaming in real app

### Priority 2 (Vision Integration)
- [ ] Implement Claude Vision API in ScreenCaptureManager
- [ ] Add screen description to chat context
- [ ] Let user toggle screen vision on/off

### Priority 3 (Polish)
- [ ] Add app menu/settings
- [ ] Keyboard shortcuts documentation
- [ ] Preferences window (hotkey customization, auto-listen, etc)
- [ ] Conversation export/save
- [ ] Dark mode support
- [ ] Window state persistence

---

## How to Continue Development

### 1. Create Xcode Project
```bash
cd /Users/felipechaux/Developer/jarvis-personal/frontend
# Either: open existing project structure in Xcode
# Or: `xcode-select --install` + create new project and copy files
```

### 2. Import Required Frameworks
In Xcode, ensure these are linked:
- Speech (for SFSpeechRecognizer)
- AVFoundation (for audio)
- AppKit (for screenshots)

### 3. Add Hotkey Library
For proper Cmd+Space detection, add `Sauce` (or similar):
```bash
# Using SPM in Xcode Package Dependencies
# https://github.com/Clipy/Sauce
```

Then in VoiceManager:
```swift
import Sauce

func setupGlobalHotkey() {
    let event = Sauce.Event(keyCode: .space, modifiers: [.command])
    Sauce.shared.listen(for: [event]) { [weak self] in
        self?.startListening()
    }
}
```

### 4. Test Backend Connection
Ensure backend is running:
```bash
cd /Users/felipechaux/Developer/jarvis-personal
source venv/bin/activate
python backend/main.py
```

Then test from app:
```bash
curl http://127.0.0.1:8000/health
```

### 5. Run App
In Xcode: `Cmd+R` to build and run

---

## Development Tips

### Testing WebSocket Locally
```bash
# Test endpoint directly
wscat -c ws://127.0.0.1:8000/ws/chat

# Send JSON message
{"message": "Hello", "model": "openrouter/anthropic/claude-sonnet-4-6"}
```

### Mock Responses (for UI testing without backend)
Uncomment in ChatManager to test UI with fake responses:
```swift
// func mockResponse() async {
//   let messages = ["Hello!", "How can I help?"]
//   for msg in messages {
//     await Task.sleep(nanoseconds: 500_000_000)
//     currentResponse += msg + " "
//   }
// }
```

### Voice Permission Debugging
```swift
// In VoiceManager
SFSpeechRecognizer.requestAuthorization { status in
    print("Speech auth status: \(status)")
    // Check System Settings > Privacy & Security > Microphone
}
```

---

## Architecture Decisions

**Why WebSocket instead of HTTP polling?**
- Real-time streaming without delay
- More efficient than polling
- Natural for conversational AI

**Why Managers as @StateObject?**
- Persist across view reloads
- Manage lifecycle (connect/disconnect)
- Encapsulate state logic

**Why environmental objects?**
- Pass managers to all views without prop drilling
- Clean dependency injection pattern

**Why native SFSpeechRecognizer?**
- No external API dependency
- Works offline
- Better privacy

**Why local TTS (AVSpeechSynthesizer)?**
- No API costs
- Instant (no network latency)
- Works offline

---

## Next Session Checklist

Before next development session:
1. [ ] Backend running (`python backend/main.py`)
2. [ ] Xcode project created/opened
3. [ ] Frameworks linked
4. [ ] Run `Cmd+R` to verify build
5. [ ] Test: Send message via MainView
6. [ ] Test: Click voice button
7. [ ] Check System Preferences for mic permission

---

## Contact Points with Backend

### Endpoints Used
- `GET /health` — Check if server is running
- `GET /models` — List available models per provider
- `WebSocket /ws/chat` — Streaming conversation
- `POST /config/provider-priority` — Change LLM priority

### Expected Response Format
```json
// WebSocket message (streaming)
{
  "token": "Hello"
}
{
  "token": " there!"
}
{
  "status": "done",
  "message": "Hello there!"
}
```

---

## Files Modified/Created

### New Files
- `JarvisApp.swift` — Entry point
- `Managers/ChatManager.swift` — Backend connection
- `Managers/VoiceManager.swift` — Voice I/O
- `Managers/ScreenCaptureManager.swift` — Screen capture
- `Views/MainView.swift` — Main UI
- `CONTEXT.md` — This file

### Still Needed
- `Jarvis.xcodeproj` — Xcode project file
- `Info.plist` — App configuration
- `Assets.xcassets` — Icons/images
- `Localizable.strings` — Translations (optional)

---

You can now continue development in Xcode! Start with:
1. Creating the Xcode project
2. Fixing hotkey detection
3. Testing WebSocket connection
4. Running the app with backend
