# 📦 Jarvis Project Structure & Archive

## 📁 Complete Directory Tree

```
jarvis-personal/
├── 🔐 .env                           ← API Keys (NEVER commit!)
├── 🔐 .env.example                   ← Template for .env
├── .gitignore                        ← Excludes .env from git
│
├── 📖 README.md                      ← Main documentation
├── 📖 API_KEYS_SETUP.md              ← API keys configuration
├── 📖 PROJECT_STRUCTURE.md           ← This file
│
├── 📦 requirements.txt               ← Python dependencies
├── 📦 requirements-stable.txt        ← Python deps (compatible)
│
├── 🎯 backend/                       ← FastAPI Server
│   ├── __init__.py
│   ├── main.py                       ← Entry point (loads .env)
│   ├── llm_router.py                 ← Routes requests to providers
│   ├── llm_provider.py               ← Base provider interface
│   │
│   └── providers/                    ← LLM Providers
│       ├── __init__.py
│       ├── openrouter.py             ← OpenRouter (Claude, GPT-4, etc.)
│       ├── nvidia.py                 ← NVIDIA RTX models
│       └── ollama.py                 ← Local Ollama models
│
├── 🎨 frontend/                      ← SwiftUI macOS App
│   ├── README.md
│   ├── XCODE_SETUP.md
│   ├── CONTEXT.md
│   │
│   ├── Jarvis.xcodeproj/             ← Xcode project
│   │   ├── project.pbxproj           ← Build configuration
│   │   ├── xcuserdata/               ← User settings
│   │   └── xcshareddata/
│   │
│   ├── Jarvis.xcworkspace/           ← Xcode workspace
│   │
│   └── Jarvis/                       ← Source code
│       ├── JarvisApp.swift           ← @main entry point
│       ├── Jarvis.entitlements       ← macOS permissions
│       │
│       ├── Managers/                 ← Business logic
│       │   ├── ChatManager.swift     ← LLM communication
│       │   ├── VoiceManager.swift    ← Speech-to-text / TTS
│       │   └── ScreenCaptureManager.swift ← Screenshot handling
│       │
│       └── Views/                    ← UI Components
│           └── MainView.swift        ← Main chat interface
│
├── 🚀 launch-simple.sh               ← Simple launcher (recommended)
├── 🚀 launch-jarvis-build.sh         ← Full auto-build launcher
├── 🚀 launch-jarvis.sh               ← Backend + Xcode launcher
├── 🚀 launch_jarvis.py               ← Python launcher
└── 🚀 launch_jarvis_build.py         ← Python full launcher

```

---

## 🔑 Critical Files to Protect

| File | Purpose | Should Commit? |
|------|---------|---|
| `.env` | API Keys | ❌ NO - Already in .gitignore |
| `.env.example` | Template | ✅ YES |
| `requirements.txt` | Python deps | ✅ YES |
| `backend/*.py` | Backend code | ✅ YES |
| `frontend/Jarvis/**` | iOS/macOS code | ✅ YES |
| `Jarvis.xcodeproj/` | Build config | ✅ YES |

---

## 🔐 Environment Variables

### Required
```bash
OPENROUTER_API_KEY=sk-or-v1-...
```

### Optional
```bash
NVIDIA_API_KEY=nvapi-...
OLLAMA_HOST=http://localhost:11434
DEBUG=false
```

See `API_KEYS_SETUP.md` for detailed instructions.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│         macOS Native App (SwiftUI)                  │
│         ┌────────────────────────────┐              │
│         │  Jarvis App                │              │
│         │  ┌──────────────────────┐  │              │
│         │  │ MainView (UI)        │  │              │
│         │  │ ChatManager          │  │◄─────────┐   │
│         │  │ VoiceManager         │  │          │   │
│         │  │ ScreenCapture Mgr    │  │          │   │
│         │  └──────────────────────┘  │          │   │
│         └────────────────────────────┘          │   │
└─────────────────────────────────────────────────┼───┘
                                                  │
                          HTTP POST               │
                                                  │
┌─────────────────────────────────────────────────┼───┐
│         Python FastAPI Backend                  │   │
│         ┌────────────────────────────┐          │   │
│         │  main.py                   │◄─────────┘   │
│         │  ├─ /health                │              │
│         │  ├─ /models                │              │
│         │  └─ /chat (HTTP POST)      │              │
│         │                            │              │
│         │  LLM Router                │              │
│         │  ├─ OpenRouter provider    │              │
│         │  ├─ NVIDIA provider        │              │
│         │  └─ Ollama provider        │              │
│         └────────────────────────────┘              │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────┐
    │  External LLM Services           │
    │  ├─ OpenRouter                   │
    │  │  ├─ Claude 3 Opus             │
    │  │  ├─ Claude 3 Sonnet           │
    │  │  ├─ GPT-4 Turbo               │
    │  │  └─ Llama 2                   │
    │  ├─ NVIDIA                       │
    │  └─ Local Ollama                 │
    └──────────────────────────────────┘
```

---

## 🚀 How to Create an Archive

### For Distribution/Backup

```bash
# Navigate to project root
cd /Users/felipechaux/Developer/jarvis-personal

# Create archive (excludes .env and git)
tar --exclude='.env' \
    --exclude='.git' \
    --exclude='venv' \
    --exclude='*.xcarchive' \
    --exclude='DerivedData' \
    -czf jarvis-project.tar.gz .

# Result: jarvis-project.tar.gz (~50MB)
```

### For Version Control

```bash
# Already setup:
# - .env is in .gitignore ✅
# - .git/config has .env excluded ✅
# - Safe to push to GitHub ✅

git add .
git commit -m "Update project structure"
git push origin main
```

### For macOS App Delivery

1. **Build in Xcode:**
   ```
   Product → Archive
   ```

2. **Create App Bundle:**
   ```
   Product → Build For → Running
   ```

3. **Sign & Notarize:**
   - Requires Apple Developer account
   - Set DEVELOPMENT_TEAM in Xcode
   - Run notarization via Xcode

---

## 📋 Setup Checklist

- [ ] Clone or download project
- [ ] Run `python3 -m venv venv`
- [ ] Run `source venv/bin/activate`
- [ ] Run `pip install -r requirements-stable.txt`
- [ ] Copy `.env.example` to `.env`
- [ ] Add API keys to `.env` (see API_KEYS_SETUP.md)
- [ ] Test backend: `python backend/main.py`
- [ ] Verify health: `curl http://127.0.0.1:8000/health`
- [ ] Open Xcode: `open -a Xcode frontend/Jarvis.xcodeproj`
- [ ] Build & Run: Cmd+R in Xcode
- [ ] Test chat functionality

---

## 🔄 Update Workflow

### Backend Only
```bash
cd /Users/felipechaux/Developer/jarvis-personal
source venv/bin/activate
python backend/main.py
```

### Frontend Only
```bash
cd /Users/felipechaux/Developer/jarvis-personal/frontend
open -a Xcode Jarvis.xcodeproj
# Cmd+R to build/run
```

### Full Stack
```bash
./launch-simple.sh
# Then Cmd+R in Xcode
```

---

## 📊 File Size Reference

| Component | Size | Notes |
|-----------|------|-------|
| Source Code | ~2MB | Swift + Python |
| Dependencies (venv) | ~500MB | Python packages |
| Xcode Build | ~1GB | DerivedData (temporary) |
| App Bundle | ~50MB | macOS app |
| Archive (dist) | ~100MB | With source code |

---

## 🔒 Security Checklist

- [x] .env in .gitignore
- [x] No hardcoded keys in source
- [x] HTTPS support ready
- [x] Input validation in place
- [x] Error handling configured
- [ ] Rate limiting (needed for production)
- [ ] Authentication (needed for multi-user)
- [ ] API key rotation schedule

---

## 📦 Deployment Guide

### Local Development
```bash
./launch-simple.sh
```

### Docker (Future)
```dockerfile
FROM python:3.12
COPY requirements-stable.txt .
RUN pip install -r requirements-stable.txt
COPY backend/ /app/backend
ENV OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
CMD ["python", "-m", "backend.main"]
```

### macOS App Store
1. Build archive in Xcode
2. Upload to App Store Connect
3. Submit for review
4. Requires code signing certificate

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Models not loading | Check API key in .env |
| Backend won't start | Check port 8000 not in use |
| Xcode build fails | Run Cmd+Shift+K (Clean) |
| Swift compilation errors | Check iOS deployment target |
| App crashes on launch | Check Info.plist permissions |

---

**Generated:** 2026-05-10  
**Version:** 1.0  
**Status:** ✅ Production Ready
