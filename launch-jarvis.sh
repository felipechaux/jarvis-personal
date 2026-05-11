#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/felipechaux/Developer/jarvis-personal"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🚀 JARVIS AUTO-LAUNCHER                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Verify Python and venv
echo -e "${YELLOW}[1/4]${NC} Verificando Python environment..."
if [ ! -d "$PROJECT_ROOT/venv" ]; then
    echo -e "${RED}❌ venv no encontrado en: $PROJECT_ROOT/venv${NC}"
    echo -e "${YELLOW}Crea con: python3 -m venv $PROJECT_ROOT/venv${NC}"
    exit 1
fi
echo -e "${GREEN}✅ venv encontrado${NC}"

# Step 2: Activate venv and start backend
echo ""
echo -e "${YELLOW}[2/4]${NC} Iniciando backend (FastAPI)..."

# Source venv
source "$PROJECT_ROOT/venv/bin/activate"

# Check if backend is already running
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Puerto 8000 ya está en uso${NC}"
    read -p "¿Usar el backend que ya está corriendo? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKEND_RUNNING=true
    else
        echo -e "${RED}Detén el backend actual y vuelve a intentar${NC}"
        exit 1
    fi
else
    # Start backend in background
    echo -e "${BLUE}Iniciando: python $BACKEND_DIR/main.py${NC}"
    cd "$PROJECT_ROOT"
    python "$BACKEND_DIR/main.py" > /tmp/jarvis-backend.log 2>&1 &
    BACKEND_PID=$!
    echo -e "${GREEN}✅ Backend iniciado (PID: $BACKEND_PID)${NC}"
    BACKEND_RUNNING=false
fi

# Step 3: Wait for backend to be healthy
echo ""
echo -e "${YELLOW}[3/4]${NC} Esperando a que el backend esté listo..."

max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend listo en http://127.0.0.1:8000${NC}"
        break
    fi

    attempt=$((attempt + 1))
    if [ $((attempt % 5)) -eq 0 ]; then
        echo -e "${YELLOW}  Intento $attempt/$max_attempts...${NC}"
    fi
    sleep 1
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}❌ Backend no respondió en 30 segundos${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        echo -e "${YELLOW}Logs del backend:${NC}"
        tail -20 /tmp/jarvis-backend.log
        kill $BACKEND_PID 2>/dev/null
    fi
    exit 1
fi

# Step 4: Open Xcode
echo ""
echo -e "${YELLOW}[4/4]${NC} Abriendo Xcode..."
cd "$FRONTEND_DIR"
open -a Xcode Jarvis.xcodeproj

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ TODO LISTO                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Backend:${NC} http://127.0.0.1:8000"
echo -e "${BLUE}WebSocket:${NC} ws://127.0.0.1:8000/ws/chat"
echo ""
echo -e "${YELLOW}En Xcode:${NC}"
echo "  1. Espera a que indexe (30 segundos)"
echo "  2. Selecciona 'Jarvis' como target"
echo "  3. Presiona Cmd+R para compilar y ejecutar"
echo ""
echo -e "${YELLOW}Para detener backend:${NC}"
echo "  kill $BACKEND_PID"
echo "  OR: lsof -ti:8000 | xargs kill -9"
echo ""

# Show backend logs in real-time (optional)
echo -e "${BLUE}📋 Logs del backend:${NC}"
tail -f /tmp/jarvis-backend.log &
TAIL_PID=$!

# Cleanup on exit
trap "kill $TAIL_PID 2>/dev/null; [ ! -z '$BACKEND_PID' ] && kill $BACKEND_PID 2>/dev/null" EXIT

# Keep script running
wait
