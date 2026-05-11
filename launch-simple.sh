#!/bin/bash

# Simple launcher - just open Xcode and compile there
# This is the most reliable way since Xcode handles all the project details

PROJECT_ROOT="/Users/felipechaux/Developer/jarvis-personal"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 JARVIS LAUNCHER (Xcode Build)                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Verify venv
echo -e "${YELLOW}[1/3]${NC} Verificando Python environment..."
if [ ! -d "$PROJECT_ROOT/venv" ]; then
    echo -e "${RED}❌ venv no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python venv OK${NC}"
echo ""

# Step 2: Start backend if not running
echo -e "${YELLOW}[2/3]${NC} Iniciando backend (FastAPI)..."

if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Backend ya está corriendo${NC}"
else
    source "$PROJECT_ROOT/venv/bin/activate"
    cd "$PROJECT_ROOT"
    python "$PROJECT_ROOT/backend/main.py" > /tmp/jarvis-backend.log 2>&1 &
    BACKEND_PID=$!
    echo -e "${GREEN}✅ Backend iniciado (PID: $BACKEND_PID)${NC}"
    sleep 2
fi
echo ""

# Step 3: Wait for backend
echo -e "${YELLOW}[3/3]${NC} Esperando a que backend esté listo..."
max_attempts=15
for attempt in $(seq 1 $max_attempts); do
    if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend listo (http://127.0.0.1:8000)${NC}"
        break
    fi
    if [ $((attempt % 5)) -eq 0 ]; then
        echo -e "${YELLOW}  Esperando... $attempt/$max_attempts${NC}"
    fi
    sleep 1
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ LISTO                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Backend:${NC}   http://127.0.0.1:8000"
echo -e "${BLUE}WebSocket:${NC}  ws://127.0.0.1:8000/ws/chat"
echo ""
echo -e "${YELLOW}Abriendo Xcode...${NC}"
echo ""

cd "$FRONTEND_DIR"
open -a Xcode Jarvis.xcodeproj

echo -e "${YELLOW}📋 En Xcode:${NC}"
echo "  1. Espera a que indexe (20-30 segundos)"
echo "  2. Selecciona 'Jarvis' como target (arriba a la izquierda)"
echo "  3. Presiona Cmd+R para compilar y ejecutar"
echo ""
echo -e "${YELLOW}Logs del backend:${NC}"
echo "  tail -f /tmp/jarvis-backend.log"
echo ""
echo -e "${BLUE}📋 Mostrando logs (Ctrl+C para salir):${NC}"
echo ""

# Show backend logs
tail -f /tmp/jarvis-backend.log
