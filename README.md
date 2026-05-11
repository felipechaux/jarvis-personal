# Jarvis Personal Assistant

A sophisticated macOS AI assistant with multi-provider LLM support, voice interaction, and beautiful UI design.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)
![macOS](https://img.shields.io/badge/macOS-12.0+-black.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

🤖 **Multi-Provider LLM Support**
- Google Gemini (free tier)
- OpenRouter (366+ models)
- NVIDIA Nemotron
- Ollama (local & cloud)

🎤 **Voice Interaction**
- Real-time speech recognition
- Natural language response generation
- Text-to-speech output
- Wake word detection

🎨 **Beautiful macOS UI**
- OS1-inspired design with clean typography
- Samantha Orb animation (60fps CADisplayLink)
- Split-view layout with sidebar navigation
- Semantic color palette (cream, beige, coral)

📊 **Smart Routing**
- Automatic provider selection based on availability
- Intelligent fallback system
- Provider priority configuration
- Per-request provider override

🖥️ **Screen Integration**
- Real-time screen capture
- Context-aware assistance
- Screenshot annotation support

## Architecture

### Frontend (macOS/SwiftUI)
```
frontend/
├── Jarvis/
│   ├── Views/
│   │   ├── MainView.swift          # Primary UI with split layout
│   │   ├── SamanthaOrb.swift       # Animated orb component
│   │   └── MessageBubble.swift     # Chat message display
│   ├── Managers/
│   │   ├── ChatManager.swift       # Backend communication
│   │   ├── VoiceManager.swift      # Speech I/O
│   │   └── ScreenCaptureManager.swift
│   └── JarvisApp.swift             # App entry point
└── Jarvis.xcodeproj/
```

### Backend (Python/FastAPI)
```
backend/
├── main.py                 # FastAPI app & endpoints
├── llm_router.py          # Multi-provider routing logic
├── llm_provider.py        # Abstract provider interface
└── providers/
    ├── gemini.py          # Google Gemini
    ├── openrouter.py      # OpenRouter
    ├── nvidia.py          # NVIDIA API
    └── ollama.py          # Ollama local/cloud
```

## Getting Started

### Prerequisites
- macOS 12.0 or later
- Xcode 15.0+
- Python 3.10+
- API keys for desired providers (optional for Ollama)

### Installation

1. **Clone repository**
```bash
git clone https://github.com/felipechaux/jarvis-personal.git
cd jarvis-personal
```

2. **Setup backend**
```bash
cd backend
pip install -r requirements.txt
```

3. **Configure environment variables**
```bash
cp .env.example .env
```

Edit `.env` with your API keys:
```bash
GEMINI_API_KEY=your_key_here
OPENROUTER_API_KEY=your_key_here
NVIDIA_API_KEY=your_key_here
OLLAMA_HOST=http://localhost:11434
```

4. **Start backend server**
```bash
python -m backend.main
# Server runs on http://127.0.0.1:8000
```

5. **Build and run frontend**
- Open `frontend/Jarvis.xcodeproj` in Xcode
- Select scheme `Jarvis` and target `macOS`
- Press `Cmd + R` to build and run

## API Endpoints

### Chat (Non-streaming)
```
POST /chat
Content-Type: application/json

{
  "messages": [
    {"role": "user", "content": "Hello Jarvis"},
    {"role": "assistant", "content": "Hi!"}
  ],
  "model": "openrouter/anthropic/claude-sonnet-4-6",
  "provider": "openrouter",
  "temperature": 0.7,
  "max_tokens": 2048
}
```

### Chat (Streaming)
```
POST /chat/stream
Returns: text/plain stream
```

### List Models
```
GET /models
Returns: {
  "gemini": ["gemini/gemini-2.5-flash", ...],
  "openrouter": ["openrouter/anthropic/claude-sonnet-4-6", ...],
  "nvidia": ["nvidia/nemotron-4-340b-instruct", ...],
  "ollama": [...]
}
```

### Health Check
```
GET /health
Returns: {
  "status": "ok",
  "providers": {
    "gemini": true,
    "openrouter": true,
    "nvidia": true,
    "ollama": true
  }
}
```

### WebSocket
```
WS /ws/chat
Real-time conversational interface
```

## Configuration

### Provider Priority
Change provider selection order:
```swift
await router.set_provider_priority(["nvidia", "openrouter", "gemini", "ollama"])
```

### Model Selection
The app automatically loads all available models from each provider. Select from the dropdown in the sidebar.

### Voice Settings
Configure in VoiceManager:
- `speechRate`: Speech synthesis speed (0.0-2.0)
- `volume`: Output volume (0.0-1.0)
- `language`: Speech recognition language

## Performance

- **Orb Animation**: 60fps smooth rendering via CADisplayLink
- **Chat Latency**: <200ms provider selection, varies by model
- **Memory**: ~120MB average (frontend), ~80MB (backend)
- **Network**: Minimal (WebSocket streaming reduces bandwidth)

## Dependencies

### Frontend
- SwiftUI (native)
- AppKit (native)
- AVFoundation (speech)
- Combine (state management)

### Backend
- FastAPI
- httpx (async HTTP)
- python-dotenv
- Uvicorn

## Troubleshooting

### Backend connection issues
```bash
# Test backend health
curl http://127.0.0.1:8000/health | jq

# Check logs
tail -f /tmp/backend.log
```

### Models not loading
- Verify API keys in `.env`
- Ensure backend is running: `curl http://127.0.0.1:8000/health`
- Check provider health status in app

### Voice not working
- Grant microphone permissions: System Preferences → Security & Privacy → Microphone
- Check audio device: System Preferences → Sound

### 404 Errors on Model Selection
- Provider extraction should work automatically
- Verify model names in `/models` endpoint
- Check backend logs for routing details

## Architecture Highlights

### Provider Routing
The `LLMRouter` class intelligently routes requests:
1. Extracts provider from model name (e.g., "openrouter/" prefix)
2. Checks provider health via `/health` endpoint
3. Falls back to priority order if preferred unavailable
4. Each provider handles its own API format

### Voice Pipeline
- **Listen**: Speech recognition → text
- **Process**: Text → LLM routing
- **Respond**: LLM output → speech synthesis

### UI Design
Following macOS best practices:
- Semantic color palette for consistency
- System fonts (SF Pro Display/Text)
- Respects system preferences (dark/light mode)
- Keyboard navigation support

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Author

**Felipe Chaux** - [@felipechaux](https://github.com/felipechaux)

## Acknowledgments

- OS1 Design System for macOS UI inspiration
- Samantha Orb animation framework
- FastAPI for robust backend
- SwiftUI for beautiful native UI

---

**Status**: Production Ready  
**Last Updated**: May 2026  
**Version**: 1.0.0
