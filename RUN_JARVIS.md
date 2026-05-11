# 🚀 RUN JARVIS - Quick Start Guide

## ⚡ 3 Comandos para Empezar

### Opción 1: TODO AUTOMÁTICO (Recomendado)
```bash
cd /Users/felipechaux/Developer/jarvis-personal
./launch-jarvis-build.sh
```

✅ **Lo que pasa:**
- Backend inicia automáticamente
- Compila la app
- La app se abre automáticamente
- Ves logs en tiempo real

⏱️ **Tiempo:** ~25 segundos

---

### Opción 2: Backend + Xcode Manual
```bash
./launch-jarvis.sh
```

Luego en Xcode:
1. Espera indexing (20-30s)
2. Presiona **Cmd+R**

✅ **Ventaja:** Más control con la UI de Xcode

---

### Opción 3: Python Version
```bash
python3 launch_jarvis_build.py
```

✅ **Mismo resultado que Opción 1** en Python puro

---

## 📊 Comparativa

| Aspecto | Opción 1 (Bash) | Opción 2 (Xcode) | Opción 3 (Python) |
|---------|---|---|---|
| Esfuerzo | ⭐ Ninguno | ⭐⭐ Manual Cmd+R | ⭐ Ninguno |
| Velocidad | ⭐⭐⭐ 25s | ⭐⭐⭐ 30s | ⭐⭐⭐ 25s |
| Control | ⭐⭐ Logs | ⭐⭐⭐ Xcode IDE | ⭐⭐ Logs |
| Complejidad | Simple | Media | Simple |

---

## ✅ Lo que se Configuró

### 1. Xcode Project (Ya Hecho)
```
frontend/Jarvis.xcodeproj/
├── project.pbxproj       ← Configuración de build
├── xcuserdata/           ← Esquemas
└── Jarvis/               ← Código fuente
    ├── JarvisApp.swift
    ├── Managers/
    ├── Views/
    └── Jarvis.entitlements
```

### 2. Auto-Launchers (Ya Creados)
```
launch-jarvis-build.sh      ← Opción 1 (Recomendada)
launch-jarvis.sh            ← Opción 2
launch-jarvis-tmux.sh       ← Opción avanzada
launch_jarvis.py            ← Opción 2 en Python
launch_jarvis_build.py      ← Opción 1 en Python
```

### 3. Documentación
```
LAUNCHER_GUIDE.md           ← Guía detallada
XCODE_SETUP.md              ← Setup de Xcode
frontend/XCODE_SETUP.md     ← Setup frontend
```

---

## 🔧 Requisitos Previos

### ✅ Python venv
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### ✅ Xcode
```bash
xcode-select --install
```

### ✅ Verificar que todo funciona
```bash
# Terminal 1: Backend
source venv/bin/activate
python backend/main.py

# Terminal 2: Verificar
curl http://127.0.0.1:8000/health
# Debería responder: {"status": "ok"}
```

---

## 🎯 Mi Flujo Diario Recomendado

### Desarrollo Rápido
```bash
./launch-jarvis-build.sh
# La app se abre automáticamente
# Ves los logs del backend
```

### Debugging Profundo
```bash
./launch-jarvis.sh
# Luego Cmd+R en Xcode
# Tienes toda la UI de debugging de Xcode
```

### Monitoreo en Tiempo Real
```bash
./launch-jarvis-tmux.sh
# Backend, Xcode y Logs en ventanas separadas
```

---

## 📋 Logs y Monitoreo

Ver logs del backend:
```bash
tail -f /tmp/jarvis-backend.log
```

Ver logs de compilación:
```bash
tail -f /tmp/jarvis-build.log
```

---

## 🛑 Detener la Aplicación

### Desde la terminal
```bash
Ctrl+C
```

### Manualmente
```bash
# Matar backend
lsof -ti:8000 | xargs kill -9

# O específicamente
kill -9 <PID>
```

---

## ❌ Problemas Comunes

### "command not found: xcodebuild"
```bash
xcode-select --install
sudo xcode-select --reset
```

### "Port 8000 already in use"
```bash
# El script pregunta automáticamente
# Responde 'y' para usar el backend existente
# O mata el proceso:
lsof -ti:8000 | xargs kill -9
```

### "venv not found"
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### "Build failed"
```bash
# Ver errores
tail -100 /tmp/jarvis-build.log

# Limpiar y reintentar
rm -rf /tmp/jarvis-build
./launch-jarvis-build.sh
```

---

## 📊 Arquitectura

```
Jarvis Project
│
├── Backend (Python FastAPI)
│   ├── WebSocket: ws://127.0.0.1:8000/ws/chat
│   ├── REST: http://127.0.0.1:8000/models
│   └── Health: http://127.0.0.1:8000/health
│
├── Frontend (Swift/SwiftUI - macOS)
│   ├── ChatManager       (WebSocket client)
│   ├── VoiceManager      (Speech-to-text, TTS)
│   ├── ScreenCaptureManager (Screenshots)
│   └── MainView          (UI)
│
└── Auto-Launchers (Bash/Python)
    ├── launch-jarvis-build.sh    (Recomendado)
    ├── launch-jarvis.sh          (Manual Xcode)
    └── launch_jarvis_build.py    (Python)
```

---

## 🎮 Próximos Pasos

Una vez que todo funcione:

1. ✅ **Hotkey Global** (Cmd+Space)
   - Agregar librería `Sauce`
   - Implementar en `VoiceManager`

2. ✅ **Settings Window**
   - Crear `SettingsView`
   - Guardar en `UserDefaults`

3. ✅ **Dark Mode**
   - Agregar `@Environment(\.colorScheme)`
   - Adaptar colores

4. ✅ **Persistencia**
   - Guardar chat history
   - Cargar en startup

---

## 💡 Tips

### Desarrollo Rápido
```bash
# Terminal 1: Auto-launcher (corre todo)
./launch-jarvis-build.sh

# Terminal 2: Ver logs
tail -f /tmp/jarvis-backend.log

# Terminal 3: Otros comandos
# (curl, debugging, etc)
```

### Build Incremental
Los cambios en Swift se detectan automáticamente con:
```bash
./launch-jarvis-build.sh
# Solo recompila lo que cambió (rápido)
```

### Verificar Backend
```bash
# Health check
curl http://127.0.0.1:8000/health

# Ver modelos disponibles
curl http://127.0.0.1:8000/models

# Test WebSocket
python3 -c "
import websocket
ws = websocket.create_connection('ws://127.0.0.1:8000/ws/chat')
print('✅ WebSocket conectado')
ws.close()
"
```

---

## 📞 Soporte Rápido

| Problema | Solución |
|----------|----------|
| App no abre | `./launch-jarvis-build.sh` |
| Backend no responde | `python backend/main.py` |
| Compilación falla | `rm -rf /tmp/jarvis-build && ./launch-jarvis-build.sh` |
| Puerto ocupado | `lsof -ti:8000 \| xargs kill -9` |
| Xcode indexing lento | Espera 30 segundos |

---

## 🎉 ¡Listo!

```bash
cd /Users/felipechaux/Developer/jarvis-personal
./launch-jarvis-build.sh
```

La app se abre automáticamente en ~25 segundos.

---

**Última actualización:** 2026-05-10  
**Versión:** 1.0  
**Estado:** ✅ Completamente funcional
