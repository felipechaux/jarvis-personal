#!/usr/bin/env python3
"""
Jarvis Auto-Launcher
Inicia el backend (FastAPI) y luego abre Xcode con el proyecto frontend.
"""

import subprocess
import sys
import time
import signal
import os
from pathlib import Path
import requests
import json

# Colors
class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    RESET = '\033[0m'

PROJECT_ROOT = Path("/Users/felipechaux/Developer/jarvis-personal")
FRONTEND_DIR = PROJECT_ROOT / "frontend"
BACKEND_DIR = PROJECT_ROOT / "backend"
VENV_DIR = PROJECT_ROOT / "venv"

# Globals for cleanup
backend_process = None
xcode_process = None

def print_header():
    """Print application header"""
    print(f"\n{Color.BLUE}╔════════════════════════════════════════════════════════════╗{Color.RESET}")
    print(f"{Color.BLUE}║          🚀 JARVIS AUTO-LAUNCHER (Python)                ║{Color.RESET}")
    print(f"{Color.BLUE}╚════════════════════════════════════════════════════════════╝{Color.RESET}\n")

def check_python_venv():
    """Verify Python venv exists"""
    print(f"{Color.YELLOW}[1/5]{Color.RESET} Verificando Python environment...")

    if not VENV_DIR.exists():
        print(f"{Color.RED}❌ venv no encontrado: {VENV_DIR}{Color.RESET}")
        print(f"{Color.YELLOW}Crea con: python3 -m venv {VENV_DIR}{Color.RESET}")
        sys.exit(1)

    print(f"{Color.GREEN}✅ venv encontrado{Color.RESET}\n")

def is_port_in_use(port):
    """Check if a port is already in use"""
    try:
        response = requests.get(f"http://127.0.0.1:{port}/health", timeout=1)
        return response.status_code < 500
    except:
        return False

def start_backend():
    """Start FastAPI backend server"""
    global backend_process

    print(f"{Color.YELLOW}[2/5]{Color.RESET} Iniciando backend (FastAPI)...")

    if is_port_in_use(8000):
        print(f"{Color.YELLOW}⚠️  Puerto 8000 ya está en uso{Color.RESET}")
        response = input("¿Usar el backend que ya está corriendo? (y/n): ")
        if response.lower() != 'y':
            print(f"{Color.RED}Detén el backend actual y vuelve a intentar{Color.RESET}")
            sys.exit(1)
        print(f"{Color.GREEN}✅ Usando backend existente{Color.RESET}\n")
        return None

    # Activate venv and start backend
    venv_python = VENV_DIR / "bin" / "python"
    backend_main = BACKEND_DIR / "main.py"

    print(f"{Color.BLUE}Ejecutando: {venv_python} {backend_main}{Color.RESET}")

    try:
        backend_process = subprocess.Popen(
            [str(venv_python), str(backend_main)],
            cwd=str(PROJECT_ROOT),
            stdout=open("/tmp/jarvis-backend.log", "w"),
            stderr=subprocess.STDOUT,
            preexec_fn=os.setsid  # Create new process group
        )
        print(f"{Color.GREEN}✅ Backend iniciado (PID: {backend_process.pid}){Color.RESET}\n")
        return backend_process
    except Exception as e:
        print(f"{Color.RED}❌ Error al iniciar backend: {e}{Color.RESET}")
        sys.exit(1)

def wait_for_backend(timeout=30):
    """Wait for backend to be healthy"""
    print(f"{Color.YELLOW}[3/5]{Color.RESET} Esperando a que el backend esté listo...")

    start_time = time.time()
    attempt = 0

    while time.time() - start_time < timeout:
        try:
            response = requests.get("http://127.0.0.1:8000/health", timeout=1)
            if response.status_code == 200:
                print(f"{Color.GREEN}✅ Backend listo en http://127.0.0.1:8000{Color.RESET}\n")
                return True
        except:
            pass

        attempt += 1
        if attempt % 5 == 0:
            elapsed = int(time.time() - start_time)
            print(f"{Color.YELLOW}  Esperando... ({elapsed}s){Color.RESET}")

        time.sleep(1)

    print(f"{Color.RED}❌ Backend no respondió en {timeout} segundos{Color.RESET}")
    if backend_process:
        print(f"{Color.YELLOW}Últimas líneas de logs:{Color.RESET}")
        try:
            with open("/tmp/jarvis-backend.log", "r") as f:
                lines = f.readlines()
                print("".join(lines[-20:]))
        except:
            pass
    return False

def start_xcode():
    """Open Xcode with the project"""
    global xcode_process

    print(f"{Color.YELLOW}[4/5]{Color.RESET} Abriendo Xcode...")

    project_path = FRONTEND_DIR / "Jarvis.xcodeproj"

    if not project_path.exists():
        print(f"{Color.RED}❌ Proyecto no encontrado: {project_path}{Color.RESET}")
        sys.exit(1)

    try:
        xcode_process = subprocess.Popen(
            ["open", "-a", "Xcode", str(project_path)]
        )
        print(f"{Color.GREEN}✅ Xcode abierto{Color.RESET}\n")
        return xcode_process
    except Exception as e:
        print(f"{Color.RED}❌ Error al abrir Xcode: {e}{Color.RESET}")
        sys.exit(1)

def show_instructions():
    """Display instructions to the user"""
    print(f"{Color.GREEN}╔════════════════════════════════════════════════════════════╗{Color.RESET}")
    print(f"{Color.GREEN}║                    ✅ TODO LISTO                          ║{Color.RESET}")
    print(f"{Color.GREEN}╚════════════════════════════════════════════════════════════╝{Color.RESET}\n")

    print(f"{Color.BLUE}Backend:{Color.RESET} http://127.0.0.1:8000")
    print(f"{Color.BLUE}WebSocket:{Color.RESET} ws://127.0.0.1:8000/ws/chat")
    print(f"{Color.BLUE}Logs:{Color.RESET} tail -f /tmp/jarvis-backend.log\n")

    print(f"{Color.YELLOW}En Xcode:{Color.RESET}")
    print("  1. Espera a que indexe el proyecto (20-30 segundos)")
    print("  2. Selecciona 'Jarvis' como target (top-left)")
    print("  3. Presiona Cmd+R o haz clic en Play ▶️\n")

    if backend_process:
        print(f"{Color.YELLOW}Para detener el backend:{Color.RESET}")
        print(f"  kill {backend_process.pid}")
        print(f"  OR: lsof -ti:8000 | xargs kill -9\n")

def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    print(f"\n{Color.YELLOW}Deteniendo Jarvis...{Color.RESET}")

    if backend_process:
        try:
            os.killpg(os.getpgid(backend_process.pid), signal.SIGTERM)
            print(f"{Color.GREEN}✅ Backend detenido{Color.RESET}")
        except:
            pass

    sys.exit(0)

def main():
    """Main entry point"""
    signal.signal(signal.SIGINT, signal_handler)

    print_header()

    try:
        check_python_venv()
        start_backend()

        if not wait_for_backend():
            sys.exit(1)

        print(f"{Color.YELLOW}[5/5]{Color.RESET} Abriendo Xcode...")
        start_xcode()

        show_instructions()

        # Show live logs
        print(f"{Color.BLUE}📋 Logs del backend (Ctrl+C para salir):{Color.RESET}\n")

        try:
            with open("/tmp/jarvis-backend.log", "r") as f:
                f.seek(0, 2)  # Go to end of file
                while True:
                    line = f.readline()
                    if line:
                        print(line, end='')
                    else:
                        time.sleep(0.1)
        except KeyboardInterrupt:
            signal_handler(None, None)

    except KeyboardInterrupt:
        signal_handler(None, None)
    except Exception as e:
        print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
        sys.exit(1)

if __name__ == "__main__":
    main()
