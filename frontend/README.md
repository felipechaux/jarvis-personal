# Jarvis macOS App - Frontend

Native SwiftUI application for macOS with real-time voice and LLM integration.

## Quick Start

### 1. Open in Xcode

```bash
cd /Users/felipechaux/Developer/jarvis-personal/frontend
open .  # Opens Finder, drag Jarvis folder to Xcode
```

Or create new project:
```bash
xcode-select --install
# File → New → Project → macOS → App
# Copy contents of Jarvis/ folder into new project
```

### 2. Ensure Backend is Running

```bash
cd /Users/felipechaux/Developer/jarvis-personal
source venv/bin/activate
python backend/main.py
```

### 3. Add Required Permissions

In Xcode:
- Select **Jarvis** → **Info**
- Add to **Info.plist**:
  ```
  NSMicrophoneUsageDescription = "Jarvis needs microphone access for voice input"
  NSScreenCaptureUsageDescription = "Jarvis needs to capture your screen to understand context"
  ```

### 4. Build & Run

Press `Cmd+R` or click Play button in Xcode.

---

## Architecture Overview

### Managers (in `Managers/`)
- **ChatManager** — WebSocket connection to backend, handles all chat
- **VoiceManager** — Speech-to-text (listen) + Text-to-speech (speak)
- **ScreenCaptureManager** — Periodic screenshot capture

### Views (in `Views/`)
- **MainView** — Main UI with chat + screen preview
- **MessageBubble** — Individual message display

### Entry Point
- **JarvisApp.swift** — App initialization

---

## Key Features

✅ Real-time chat streaming  
✅ Voice input (Cmd+Space)  
✅ Voice output (automatic read-aloud)  
✅ Screen capture & context  
✅ Multi-provider LLM switching  
✅ Minimalist UI  

---

## Development Notes

### WebSocket Connection
The app connects to `ws://127.0.0.1:8000/ws/chat` automatically.
If backend is not running, you'll see connection errors in the error panel.

### Voice Hotkey
Currently uses a button in the UI. For global Cmd+Space hotkey:
1. Add `Sauce` package (SPM)
2. Uncomment hotkey setup in VoiceManager
3. Test with `Cmd+Space` from any app

### Screen Vision
Currently just captures screenshots. To enable AI description:
1. Add ANTHROPIC_API_KEY to environment
2. Implement Claude Vision API call in ScreenCaptureManager
3. Uncomment vision integration in ChatManager

---

## Testing

### Test Chat Without Backend
Uncomment `mockResponse()` in MainView for UI testing.

### Test Voice
1. Click microphone button
2. Speak clearly
3. Check transcript appears in text field

### Test Provider Switching
1. Click provider dropdown (top right)
2. Select different provider
3. Verify models list updates

---

## Common Issues

### "Connection refused" errors
- Make sure backend is running: `python backend/main.py`
- Verify it's on port 8000: `lsof -i :8000`

### Microphone not working
- System Settings → Privacy & Security → Microphone → Allow Jarvis
- Test in System Preferences → Sound

### Can't build
- Xcode 15+
- macOS 12.0+
- All frameworks linked (Build Settings → Frameworks)

---

## Next Steps

1. **Hotkey Support** — Add Sauce library for Cmd+Space detection
2. **Vision Integration** — Implement Claude Vision API calls
3. **Settings Window** — User preferences (hotkey customization, etc)
4. **Persistence** — Save chat history to local DB
5. **App Distribution** — Code signing, notarization for Mac App Store

---

## Full Context

See `CONTEXT.md` for detailed development notes, architecture decisions, and debugging tips.
