#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Abriendo Jarvis en Xcode...${NC}"

# Check if Xcode is installed
if ! command -v xcode-select &> /dev/null; then
    echo -e "${YELLOW}⚠️  Xcode no está instalado. Instala con:${NC}"
    echo "xcode-select --install"
    exit 1
fi

# Open the Xcode project
open -a Xcode Jarvis.xcodeproj

echo -e "${GREEN}✅ Proyecto abierto en Xcode${NC}"
echo -e "${YELLOW}📝 Próximos pasos:${NC}"
echo "1. Espera a que Xcode indexe el proyecto (20-30s)"
echo "2. Selecciona 'Jarvis' como target activo (arriba a la izquierda)"
echo "3. Presiona Cmd+R para compilar y ejecutar"
echo ""
echo -e "${BLUE}🔧 Si necesitas el backend:${NC}"
echo "  cd /Users/felipechaux/Developer/jarvis-personal"
echo "  source venv/bin/activate"
echo "  python backend/main.py"
