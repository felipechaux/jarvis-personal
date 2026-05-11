# Jarvis Xcode Setup — Guía Rápida

✅ **El proyecto Xcode está 100% configurado y listo para usar.**

## Abrir en Xcode

```bash
cd /Users/felipechaux/Developer/jarvis-personal/frontend
./open-xcode.sh
```

O manualmente:
```bash
open Jarvis.xcodeproj
```

## Estructura del Proyecto

```
frontend/
├── Jarvis/
│   ├── JarvisApp.swift          ← Entry point (@main)
│   ├── Jarvis.entitlements      ← Permisos (micrófono, pantalla)
│   ├── Managers/
│   │   ├── ChatManager.swift    ← WebSocket + LLM routing
│   │   ├── VoiceManager.swift   ← Speech-to-text + text-to-speech
│   │   └── ScreenCaptureManager.swift ← Captura de pantalla periódica
│   └── Views/
│       └── MainView.swift       ← UI principal (chat + controles)
├── Jarvis.xcodeproj/            ← Configuración Xcode
└── Jarvis.xcworkspace/          ← Workspace
```

## Checklist Antes de Build

- [ ] Backend corriendo: `python backend/main.py`
- [ ] Xcode 15+ instalado: `xcode-select --install`
- [ ] Frameworks linked: Foundation, AppKit, SwiftUI, Combine, AVFoundation, Speech
- [ ] Permisos en Info.plist: 
  - `NSMicrophoneUsageDescription`
  - `NSScreenCaptureUsageDescription`

## Pasos para Compilar y Ejecutar

### 1️⃣ Abre Xcode
```bash
./open-xcode.sh
```

### 2️⃣ Xcode indexará (~20-30 segundos)
Espera a que el ícono en la parte superior derecha deje de girar.

### 3️⃣ Selecciona Target
- En la parte superior izquierda: **Jarvis** (proyecto) > **Jarvis** (target)

### 4️⃣ Selecciona Esquema
- En la barra superior: **Jarvis** (dropdown)

### 5️⃣ Presiona Cmd+R
O haz clic en el botón Play ▶️ en Xcode.

## Qué Pasará

```
1. Compilación Swift (5-10s)
2. Linking de frameworks (2-3s)
3. Jarvis.app se abre
4. MainView aparece en pantalla
5. Se conecta a WebSocket (ws://127.0.0.1:8000/ws/chat)
```

Si el backend no está corriendo, verás un error de conexión.

## Pruebas Iniciales

### ✅ Test 1: UI Renderiza
- Deberías ver la ventana principal con:
  - Titulo "Jarvis" + "Personal Assistant"
  - Dropdown de provider (top-right)
  - Dropdown de modelo
  - Chat area vacía
  - Input field con botón de micrófono

### ✅ Test 2: WebSocket Conecta
- Si backend está corriendo: sin errores en la consola
- Si backend NO está corriendo: "Connection refused" en error panel

### ✅ Test 3: Envía Mensaje
- Escribe algo en el input field
- Presiona Enter
- Deberías ver el mensaje en el chat
- El asistente debería responder

### ✅ Test 4: Voz (opcional)
- Haz clic en el botón del micrófono
- Habla (en inglés)
- El transcript debería aparecer en el input field

## Common Issues

### ❌ "Command not found: xcode-select"
```bash
# Instala Xcode command line tools
xcode-select --install
```

### ❌ "Symbol not found" en build
- Product → Clean Build Folder (Cmd+Shift+K)
- Close Xcode
- rm -rf ~/Library/Developer/Xcode/DerivedData
- Abre Xcode nuevamente

### ❌ "WebSocket: Connection refused"
- Backend no está corriendo
- `python backend/main.py` desde otra terminal

### ❌ "Microphone not working"
- System Settings → Privacy & Security → Microphone → ✅ Jarvis
- Verifica que `NSMicrophoneUsageDescription` esté en Info.plist

### ❌ "Cannot open Jarvis.xcodeproj"
- Verifica que exists: `Jarvis.xcodeproj/project.pbxproj`
- Comprueba permisos: `chmod -R 755 Jarvis.xcodeproj`

## Build Settings Importantes

| Setting | Valor |
|---------|-------|
| Product Name | Jarvis |
| Bundle Identifier | com.felipechaux.jarvis |
| macOS Deployment Target | 12.0 |
| Swift Language Version | 5.0 |
| Code Sign Identity | - (automatic) |

## Próximos Pasos (Nivel 2)

Una vez que el proyecto compile y la UI funcione:

1. **Hotkey Global (Cmd+Space)**
   - Agregar dependencia: `Sauce` vía SPM
   - Implementar global hotkey en VoiceManager
   - Test: Cmd+Space desde cualquier app

2. **Settings Window**
   - Crear SettingsView
   - Guardar preferencias en UserDefaults

3. **Dark Mode**
   - @Environment(\.colorScheme) var colorScheme
   - Adaptar colores en MainView y MessageBubble

4. **App Menu**
   - Archivo → Exportar chat
   - Editar → Preferencias
   - Ayuda → Documentación

## Debugging

### Console Output
En Xcode: View → Debug Area → Activate Console (Cmd+Shift+Y)

### Variables de entorno
En Xcode:
- Product → Scheme → Edit Scheme
- Run → Arguments Passed On Launch
- Agregar: `-com.felipechaux.jarvis DEBUG true`

### LLDB Breakpoints
Haz clic en el número de línea para agregar breakpoints.

---

**¡Listo para programar! 🚀**

Si algo no funciona, verifica primero que el backend esté corriendo.
