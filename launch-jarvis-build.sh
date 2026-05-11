#!/bin/bash

# Full auto-build and run version
# This script:
# 1. Starts the backend
# 2. Compiles the Xcode project
# 3. Runs the built app

PROJECT_ROOT="/Users/felipechaux/Developer/jarvis-personal"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_DIR="$PROJECT_ROOT/backend"
BUILD_DIR="/tmp/jarvis-build"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Limpiando...${NC}"
    # Try to kill backend
    if [ ! -z "$BACKEND_PID" ] && ps -p $BACKEND_PID > /dev/null 2>&1; then
        kill $BACKEND_PID 2>/dev/null
        sleep 1
        kill -9 $BACKEND_PID 2>/dev/null
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 JARVIS FULL AUTO-BUILD & RUN                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Verify venv
echo -e "${YELLOW}[1/6]${NC} Verificando Python environment..."
if [ ! -d "$PROJECT_ROOT/venv" ]; then
    echo -e "${RED}❌ venv no encontrado${NC}"
    echo -e "${YELLOW}Crea con: python3 -m venv $PROJECT_ROOT/venv${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python venv OK${NC}"
echo ""

# Step 2: Start backend
echo -e "${YELLOW}[2/6]${NC} Iniciando backend (FastAPI)..."

# Check if already running
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Backend ya está corriendo en puerto 8000${NC}"
else
    source "$PROJECT_ROOT/venv/bin/activate"
    cd "$PROJECT_ROOT"
    python "$BACKEND_DIR/main.py" > /tmp/jarvis-backend.log 2>&1 &
    BACKEND_PID=$!
    echo -e "${GREEN}✅ Backend iniciado (PID: $BACKEND_PID)${NC}"
    sleep 3
fi
echo ""

# Step 3: Wait for backend to be healthy
echo -e "${YELLOW}[3/6]${NC} Esperando a que backend esté listo..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend listo (http://127.0.0.1:8000)${NC}"
        break
    fi
    attempt=$((attempt + 1))
    if [ $((attempt % 5)) -eq 0 ]; then
        echo -e "${YELLOW}  Esperando... $attempt/$max_attempts${NC}"
    fi
    sleep 1
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}❌ Backend no respondió${NC}"
    tail -20 /tmp/jarvis-backend.log
    exit 1
fi
echo ""

# Step 4: Verify Xcode project
echo -e "${YELLOW}[4/6]${NC} Verificando proyecto Xcode..."
cd "$FRONTEND_DIR"

if [ ! -f "Jarvis.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Proyecto Xcode no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Proyecto encontrado${NC}"
echo ""

# Step 5: Build with xcodebuild
echo -e "${YELLOW}[5/6]${NC} Compilando con xcodebuild..."
echo -e "${CYAN}xcodebuild -project Jarvis.xcodeproj -target Jarvis -configuration Debug${NC}"

mkdir -p "$BUILD_DIR"

xcodebuild \
    -project Jarvis.xcodeproj \
    -scheme Jarvis \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_STYLE=Automatic \
    -quiet \
    2>&1 | tee /tmp/jarvis-build.log

BUILD_EXIT_CODE=${PIPESTATUS[0]}

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}❌ Build falló${NC}"
    echo -e "${YELLOW}Mostrando últimas líneas del log:${NC}"
    tail -30 /tmp/jarvis-build.log
    exit 1
fi
echo -e "${GREEN}✅ Build exitoso${NC}"
echo ""

# Step 6: Run the app
echo -e "${YELLOW}[6/6]${NC} Ejecutando Jarvis..."

APP_PATH="$BUILD_DIR/Build/Products/Debug/Jarvis.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App compilada no encontrada en: $APP_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}Lanzando: open '$APP_PATH'${NC}"
open "$APP_PATH"

sleep 2

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ TODO LISTO                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Backend:${NC}   http://127.0.0.1:8000"
echo -e "${CYAN}WebSocket:${NC}  ws://127.0.0.1:8000/ws/chat"
echo -e "${CYAN}App:${NC}        Jarvis (abierta)"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "  Backend: tail -f /tmp/jarvis-backend.log"
echo "  Build:   tail -f /tmp/jarvis-build.log"
echo ""
echo -e "${YELLOW}Para detener:${NC}"
echo "  Presiona Ctrl+C en esta terminal"
echo "  O: kill $BACKEND_PID"
echo ""
echo -e "${BLUE}📋 Logs del backend (Ctrl+C para salir):${NC}"
echo ""

# Show backend logs
tail -f /tmp/jarvis-backend.log
