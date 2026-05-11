# 🔑 Jarvis API Keys Setup Guide

## ⚠️ Important Security Notice

**NEVER** commit the `.env` file to git. It contains sensitive API keys that should remain private.

✅ The `.env` file is already in `.gitignore`

---

## 🚀 Quick Start

You need **at least one API key** to use Jarvis. The easiest option is **OpenRouter**.

### Option 1: OpenRouter (Recommended) ⭐

**Why OpenRouter?**
- ✅ Supports multiple models (Claude, GPT-4, Llama, etc.)
- ✅ Simple pricing - pay per request
- ✅ No monthly subscription required
- ✅ Can use multiple providers through one API

**Steps:**

1. **Go to OpenRouter**: https://openrouter.ai/keys

2. **Create Account** (free)
   - Sign up with email or GitHub
   - Verify email

3. **Get Your API Key**
   - Go to https://openrouter.ai/keys
   - Click "Create New Key"
   - Copy the key (looks like: `sk-or-v1-...`)

4. **Add to .env**
   ```bash
   # Edit /Users/felipechaux/Developer/jarvis-personal/.env
   OPENROUTER_API_KEY=sk-or-v1-YOUR-KEY-HERE
   ```

5. **Add Credits** (optional but recommended)
   - Add $5-$10 credit to avoid rate limiting
   - https://openrouter.ai/account/billing/limits

---

## 🔄 Other Options

### Option 2: NVIDIA API (Free Tier Available)

**For NVIDIA RTX models:**

1. Go to: https://build.nvidia.com/
2. Create account
3. Get API key from dashboard
4. Add to `.env`:
   ```
   NVIDIA_API_KEY=nvapi-...
   ```

### Option 3: Local Ollama (No API Key Needed)

**For running models locally:**

1. Download Ollama: https://ollama.ai
2. Run: `ollama pull llama2`
3. Ollama runs on `http://localhost:11434` by default
4. Update `.env`:
   ```
   OLLAMA_HOST=http://localhost:11434
   ```

---

## 📝 .env File Structure

### Complete Example

```bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# REQUIRED
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OPENROUTER_API_KEY=sk-or-v1-YOUR-ACTUAL-KEY-HERE

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OPTIONAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NVIDIA_API_KEY=
OLLAMA_HOST=http://localhost:11434
BACKEND_URL=http://127.0.0.1:8000
DEBUG=false
```

---

## ✅ Verify Setup

After adding your API key, test it:

```bash
cd /Users/felipechaux/Developer/jarvis-personal
source venv/bin/activate
python backend/main.py
```

**In another terminal:**

```bash
curl http://127.0.0.1:8000/health
```

Expected response:
```json
{
  "status": "ok",
  "providers": {
    "openrouter": true,
    "ollama": false,
    "nvidia": false
  }
}
```

The provider with `true` means it's configured and ready! ✅

---

## 🚀 Run the Full Application

### Terminal 1: Backend

```bash
cd /Users/felipechaux/Developer/jarvis-personal
source venv/bin/activate
python backend/main.py
```

### Terminal 2: Frontend (Xcode)

```bash
cd /Users/felipechaux/Developer/jarvis-personal/frontend
open -a Xcode Jarvis.xcodeproj
```

Then press **Cmd+R** to compile and run.

---

## 💡 Available Models

Once you have an API key configured, you can use these models:

### OpenRouter (via OPENROUTER_API_KEY)
- Claude 3 Opus
- Claude 3 Sonnet
- GPT-4 Turbo
- Llama 2
- And many more...

### NVIDIA (via NVIDIA_API_KEY)
- NVIDIA Nemotron
- Other RTX optimized models

### Ollama (Local)
- Llama 2
- Mistral
- Neural Chat
- And any model you download

---

## 🆘 Troubleshooting

### "Failed to load models"
```
✗ No API key configured
✗ API key is invalid/expired
✗ No internet connection
```

**Solution:**
1. Check `.env` file has `OPENROUTER_API_KEY=sk-or-v1-...` (not empty)
2. Test the key: Copy it to OpenRouter dashboard and verify
3. Check internet connection

### "Connection refused"
```
✗ Backend not running
```

**Solution:**
```bash
# Terminal 1
cd /Users/felipechaux/Developer/jarvis-personal
source venv/bin/activate
python backend/main.py
```

### "Invalid API key"
```
✗ Key expired
✗ Wrong key format
✗ Credits exhausted
```

**Solution:**
1. Go to https://openrouter.ai/keys - verify key is valid
2. Check key format starts with `sk-or-v1-`
3. Add $5 credit if needed

---

## 📦 Deployment

### For macOS App Store Distribution

1. Get your valid API keys
2. Create a `.env` file with your keys (don't commit!)
3. Update the app to read from `.env` file at launch
4. Test thoroughly

### For Docker/Cloud Deployment

1. Pass environment variables securely:
   ```bash
   export OPENROUTER_API_KEY=sk-or-v1-...
   python backend/main.py
   ```

2. Or use `.env` file mounted as volume:
   ```bash
   docker run -e OPENROUTER_API_KEY=sk-or-v1-... myapp
   ```

---

## 🔒 Security Best Practices

✅ **DO:**
- Keep `.env` file private (it's in .gitignore)
- Use different keys for dev/prod
- Rotate keys periodically
- Add rate limiting on backend
- Monitor API usage

❌ **DON'T:**
- Commit `.env` to git
- Share API keys in messages/Slack
- Hardcode keys in code
- Use production keys for testing

---

## 📞 Support

If you have issues:

1. Check this guide again
2. Verify `.env` file exists and is readable
3. Check backend logs: `tail -f /tmp/jarvis-backend.log`
4. Test API manually: `curl http://127.0.0.1:8000/health`

---

**Ready to use Jarvis! 🚀**

Add your API key to `.env` and run:
```bash
./launch-simple.sh
```
