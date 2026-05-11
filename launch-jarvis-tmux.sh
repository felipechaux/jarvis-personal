#!/bin/bash

# Advanced version using tmux for better terminal management
# Run: ./launch-jarvis-tmux.sh

PROJECT_ROOT="/Users/felipechaux/Developer/jarvis-personal"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Lanzando Jarvis con tmux...${NC}"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${YELLOW}⚠️  tmux no está instalado. Instalando con Homebrew...${NC}"
    brew install tmux
fi

# Kill existing tmux session if exists
tmux kill-session -t jarvis 2>/dev/null

# Create new tmux session with two windows
tmux new-session -d -s jarvis -x 200 -y 50

# Window 0: Backend
tmux send-keys -t jarvis:0 "cd $PROJECT_ROOT && source venv/bin/activate && python backend/main.py" Enter
tmux set-window-option -t jarvis:0 -g window-status-current-style "bg=red"

# Wait for backend to be ready
sleep 5

# Window 1: Xcode (just open it)
tmux new-window -t jarvis:1 -n "xcode"
tmux send-keys -t jarvis:1 "cd $FRONTEND_DIR && open -a Xcode Jarvis.xcodeproj && echo 'Xcode abierto. Para compilar: Cmd+R' && sleep 999999" Enter

# Window 2: Logs
tmux new-window -t jarvis:2 -n "logs"
tmux send-keys -t jarvis:2 "cd $PROJECT_ROOT && tail -f /tmp/jarvis-backend.log" Enter

# Display instructions
echo ""
echo -e "${GREEN}✅ Sesión tmux 'jarvis' creada${NC}"
echo ""
echo -e "${YELLOW}Windows:${NC}"
echo "  [0] Backend (FastAPI) - RED si está activo"
echo "  [1] Xcode - App native"
echo "  [2] Logs - Real-time logs"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  tmux attach -t jarvis        # Adjuntar a la sesión"
echo "  tmux select-window -t jarvis:0  # Ver backend"
echo "  tmux kill-session -t jarvis   # Detener todo"
echo ""
echo "Adjuntando a la sesión..."
tmux attach -t jarvis
