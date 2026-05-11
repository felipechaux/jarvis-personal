# Jarvis Launcher Guide 🚀

Este documento explica todos los scripts de lanzamiento disponibles.

## ⚡ Opción Recomendada (Más Rápido)

```bash
./launch-jarvis-build.sh
```

Este script:
1. ✅ Inicia el backend (Python FastAPI)
2. ✅ Espera a que esté listo
3. ✅ **Compila** la app con `xcodebuild`
4. ✅ **Ejecuta** la app compilada automáticamente
5. ✅ Muestra logs en tiempo real

**Ventajas:**
- Todo en un comando
- No necesitas interactuar con Xcode
- Compila en ~10-20 segundos
- La app se abre automáticamente

---

## 📚 Comparativa de Scripts

### 1. `launch-jarvis-build.sh` (Recomendado)
**Tipo:** Bash  
**Función:** Backend + Build + Run automático

```bash
./launch-jarvis-build.sh
```

**Flujo:**
```
Backend start ➜ Wait for health ➜ xcodebuild ➜ open Jarvis.app ➜ Show logs
```

**Cuándo usar:**
- Quieres compilar y ejecutar TODO automáticamente
- No quieres tocar Xcode
- Quieres ver logs en tiempo real

**Requisitos:**
- xcodebuild instalado (viene con Xcode)
- Python venv configurado

---

### 2. `launch_jarvis_build.py` (Alternativa Python)
**Tipo:** Python 3  
**Función:** Backend + Build + Run (versión Python)

```bash
python3 launch_jarvis_build.py
# o
./launch_jarvis_build.py
```

**Ventajas sobre la versión Bash:**
- Mejor manejo de errores
- Más portable (funciona en macOS, Linux, etc.)
- Mejor detección de problemas

---

### 3. `launch-jarvis.sh` (Solo Backend + Xcode)
**Tipo:** Bash  
**Función:** Inicia backend y abre Xcode (manual build)

```bash
./launch-jarvis.sh
```

**Flujo:**
```
Backend start ➜ Wait for health ➜ open Xcode ➜ Manual: Cmd+R
```

**Cuándo usar:**
- Quieres compilar manualmente en Xcode
- Preferes la UI de Xcode para debugging
- Necesitas ver el console output de Xcode

**Pasos después de ejecutar:**
1. Espera a que Xcode indexe (20-30 segundos)
2. Presiona Cmd+R para compilar y ejecutar

---

### 4. `launch_jarvis.py` (Python: Backend + Xcode)
**Tipo:** Python 3  
**Función:** Backend + Xcode (versión Python)

```bash
python3 launch_jarvis.py
# o
./launch_jarvis.py
```

---

### 5. `launch-jarvis-tmux.sh` (Avanzado)
**Tipo:** Bash + tmux  
**Función:** Backend + Xcode en sesión tmux (modo desarrollador)

```bash
./launch-jarvis-tmux.sh
```

**Requiere:** `brew install tmux`

**Flujo:**
```
tmux session:
  [0] Backend (logs)
  [1] Xcode
  [2] Realtime logs
```

**Cuándo usar:**
- Desarrollo avanzado
- Quieres múltiples ventanas de terminal
- Necesitas monitoreo en tiempo real del backend

---

## 🎯 Guía de Selección

### Soy nuevo, quiero lo más fácil
➜ **`./launch-jarvis-build.sh`**

### Prefiero usar Xcode para compilar
➜ **`./launch-jarvis.sh`** → Cmd+R en Xcode

### Uso desarrollo activo (debugging)
➜ **`./launch-jarvis-tmux.sh`**

### Prefiero Python a Bash
➜ **`./launch_jarvis_build.py`**

---

## 📊 Tiempo de Ejecución

| Script | Backend | Build | Total | App Abierta |
|--------|---------|-------|-------|-------------|
| `launch-jarvis-build.sh` | ~3s | ~10-20s | **~25s** | ✅ Automático |
| `launch-jarvis.sh` | ~3s | Manual | **~3s** | ✅ Xcode |
| `launch-jarvis-tmux.sh` | ~3s | Manual | **~3s** | ✅ Tmux |

---

## ⚙️ Configuración Requerida

### Python venv (Necesario para todos)
```bash
cd /Users/felipechaux/Developer/jarvis-personal
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Xcode (Necesario para todos)
```bash
xcode-select --install
# o
# Descarga desde App Store
```

### tmux (Solo para `launch-jarvis-tmux.sh`)
```bash
brew install tmux
```

---

## 🔍 Troubleshooting

### "command not found: xcodebuild"
Solución:
```bash
xcode-select --install
# o
sudo xcode-select --reset
```

### "Port 8000 already in use"
El script preguntará si usar el backend existente:
- Presiona `y` para usar el que ya corre
- Presiona `n` para detenerlo y reiniciar

### "Build failed"
Mira los logs:
```bash
tail -50 /tmp/jarvis-build.log
```

### Backend no responde
Verifica logs:
```bash
tail -f /tmp/jarvis-backend.log
```

---

## 🛑 Detener la Aplicación

### Si usas `launch-jarvis-build.sh` o `launch_jarvis_build.py`
Presiona **Ctrl+C** en la terminal

### Si usas `launch-jarvis-tmux.sh`
Presiona **Ctrl+C** o:
```bash
tmux kill-session -t jarvis
```

### Matar backend si sigue corriendo
```bash
lsof -ti:8000 | xargs kill -9
```

---

## 📍 Archivos de Log

| Archivo | Contenido |
|---------|-----------|
| `/tmp/jarvis-backend.log` | Output del servidor FastAPI |
| `/tmp/jarvis-build.log` | Output del xcodebuild |

Ver logs en tiempo real:
```bash
tail -f /tmp/jarvis-backend.log
```

---

## 💡 Tips Útiles

### Build más rápido
Usa `launch-jarvis-build.sh` - compila en ~15 segundos

### Debugging
Usa `launch-jarvis.sh` + Cmd+R en Xcode para máximo control

### Desarrollo avanzado
Usa `launch-jarvis-tmux.sh` para múltiples ventanas

### Verificar que backend corre
```bash
curl http://127.0.0.1:8000/health
# Debería responder: {"status": "ok"}
```

### Verificar WebSocket
```bash
# En otra terminal
python3 -c "
import websocket
try:
    ws = websocket.create_connection('ws://127.0.0.1:8000/ws/chat')
    print('✅ WebSocket conectado')
    ws.close()
except:
    print('❌ WebSocket no disponible')
"
```

---

## 🚀 Mi Flujo de Trabajo Recomendado

```bash
# Terminal 1: Lancer todo (backend + build + app)
./launch-jarvis-build.sh

# La app se abre automáticamente y ves logs del backend

# Para cambios:
# Terminal 2 (opcional): Ver logs más detallados
tail -f /tmp/jarvis-backend.log

# Para recompilar después de cambios:
# Presiona Ctrl+C en Terminal 1 y ejecuta nuevamente
```

---

## 📞 Soporte

Si algo no funciona:

1. Verifica que backend está corriendo: `curl http://127.0.0.1:8000/health`
2. Verifica logs: `tail -50 /tmp/jarvis-build.log`
3. Limpia build: `rm -rf /tmp/jarvis-build`
4. Reintenta: `./launch-jarvis-build.sh`

---

**¡Listo para desarrollar! 🎉**

Recomendación: Usa `./launch-jarvis-build.sh` para la mejor experiencia.
