#!/usr/bin/env python3
"""
Jarvis Full Auto-Launcher with Build & Run
Inicia backend → Compila Xcode → Ejecuta la app
"""

import subprocess
import sys
import time
import signal
import os
from pathlib import Path
import requests

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    CYAN = '\033[96m'
    RESET = '\033[0m'

PROJECT_ROOT = Path("/Users/felipechaux/Developer/jarvis-personal")
FRONTEND_DIR = PROJECT_ROOT / "frontend"
BACKEND_DIR = PROJECT_ROOT / "backend"
VENV_DIR = PROJECT_ROOT / "venv"
BUILD_DIR = Path("/tmp/jarvis-build")

backend_process = None

def print_header():
    print(f"\n{Color.BLUE}╔════════════════════════════════════════════════════════════╗{Color.RESET}")
    print(f"{Color.BLUE}║   🚀 JARVIS FULL AUTO-BUILD & RUN (Python)              ║{Color.RESET}")
    print(f"{Color.BLUE}╚════════════════════════════════════════════════════════════╝{Color.RESET}\n")

def step(num, total, msg):
    return f"{Color.YELLOW}[{num}/{total}]{Color.RESET} {msg}"

def check_venv():
    print(step(1, 7, "Verificando Python environment..."))
    if not VENV_DIR.exists():
        print(f"{Color.RED}❌ venv no encontrado: {VENV_DIR}{Color.RESET}")
        sys.exit(1)
    print(f"{Color.GREEN}✅ Python venv OK{Color.RESET}\n")

def start_backend():
    global backend_process
    print(step(2, 7, "Iniciando backend (FastAPI)..."))

    # Check if already running
    try:
        response = requests.get("http://127.0.0.1:8000/health", timeout=1)
        if response.status_code < 500:
            print(f"{Color.YELLOW}⚠️  Backend ya está corriendo{Color.RESET}")
            return
    except:
        pass

    venv_python = VENV_DIR / "bin" / "python"
    backend_main = BACKEND_DIR / "main.py"

    try:
        backend_process = subprocess.Popen(
            [str(venv_python), str(backend_main)],
            cwd=str(PROJECT_ROOT),
            stdout=open("/tmp/jarvis-backend.log", "w"),
            stderr=subprocess.STDOUT,
            preexec_fn=os.setsid
        )
        print(f"{Color.GREEN}✅ Backend iniciado (PID: {backend_process.pid}){Color.RESET}")
        time.sleep(2)
    except Exception as e:
        print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
        sys.exit(1)
    print()

def wait_for_backend():
    print(step(3, 7, "Esperando a que backend esté listo..."))

    for attempt in range(30):
        try:
            response = requests.get("http://127.0.0.1:8000/health", timeout=1)
            if response.status_code == 200:
                print(f"{Color.GREEN}✅ Backend listo (http://127.0.0.1:8000){Color.RESET}\n")
                return True
        except:
            pass

        if attempt % 5 == 0:
            print(f"{Color.YELLOW}  Esperando... ({attempt}s){Color.RESET}")
        time.sleep(1)

    print(f"{Color.RED}❌ Backend no respondió{Color.RESET}")
    return False

def verify_project():
    print(step(4, 7, "Verificando proyecto Xcode..."))

    project_file = FRONTEND_DIR / "Jarvis.xcodeproj" / "project.pbxproj"
    if not project_file.exists():
        print(f"{Color.RED}❌ Proyecto no encontrado{Color.RESET}")
        sys.exit(1)

    print(f"{Color.GREEN}✅ Proyecto encontrado{Color.RESET}\n")

def build_project():
    print(step(5, 7, "Compilando con xcodebuild..."))

    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    print(f"{Color.CYAN}xcodebuild -project Jarvis.xcodeproj -target Jarvis -configuration Debug{Color.RESET}")
    print()

    try:
        result = subprocess.run(
            [
                "xcodebuild",
                "-project", str(FRONTEND_DIR / "Jarvis.xcodeproj"),
                "-scheme", "Jarvis",
                "-configuration", "Debug",
                "-derivedDataPath", str(BUILD_DIR)
            ],
            cwd=str(FRONTEND_DIR),
            capture_output=True,
            text=True
        )

        with open("/tmp/jarvis-build.log", "w") as f:
            f.write(result.stdout)
            f.write(result.stderr)

        if result.returncode != 0:
            print(f"{Color.RED}❌ Build falló{Color.RESET}")
            print(f"\n{Color.YELLOW}Error output:{Color.RESET}")
            print(result.stderr[-1000:])  # Last 1000 chars
            return False

        print(f"{Color.GREEN}✅ Build exitoso{Color.RESET}\n")
        return True

    except Exception as e:
        print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
        return False

def run_app():
    print(step(6, 7, "Preparando para ejecutar..."))

    app_path = BUILD_DIR / "Build" / "Products" / "Debug" / "Jarvis.app"

    if not app_path.exists():
        print(f"{Color.RED}❌ App no encontrada: {app_path}{Color.RESET}")
        return False

    print(f"{Color.BLUE}Lanzando: open '{app_path}'{Color.RESET}\n")

    try:
        subprocess.Popen(["open", str(app_path)])
        time.sleep(2)
        print(f"{Color.GREEN}✅ App ejecutada{Color.RESET}\n")
        return True
    except Exception as e:
        print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
        return False

def show_final_message():
    print(f"{Color.GREEN}╔════════════════════════════════════════════════════════════╗{Color.RESET}")
    print(f"{Color.GREEN}║                    ✅ TODO LISTO                          ║{Color.RESET}")
    print(f"{Color.GREEN}╚════════════════════════════════════════════════════════════╝{Color.RESET}\n")

    print(f"{Color.CYAN}Backend:${Color.RESET}   http://127.0.0.1:8000")
    print(f"{Color.CYAN}WebSocket:${Color.RESET}  ws://127.0.0.1:8000/ws/chat")
    print(f"{Color.CYAN}App:${Color.RESET}        Jarvis (ejecutándose)\n")

    print(f"{Color.YELLOW}Logs:${Color.RESET}")
    print("  Backend: tail -f /tmp/jarvis-backend.log")
    print("  Build:   tail -f /tmp/jarvis-build.log\n")

    if backend_process:
        print(f"{Color.YELLOW}Para detener:${Color.RESET}")
        print(f"  kill {backend_process.pid}")
        print(f"  O presiona Ctrl+C aquí\n")

    print(f"{Color.BLUE}📋 Logs del backend (Ctrl+C para salir):{Color.RESET}\n")

def show_logs():
    try:
        with open("/tmp/jarvis-backend.log", "r") as f:
            f.seek(0, 2)  # Go to end
            while True:
                line = f.readline()
                if line:
                    print(line, end='')
                else:
                    time.sleep(0.1)
    except KeyboardInterrupt:
        cleanup()

def cleanup(sig=None, frame=None):
    print(f"\n{Color.YELLOW}Deteniendo...{Color.RESET}")
    if backend_process:
        try:
            os.killpg(os.getpgid(backend_process.pid), signal.SIGTERM)
            print(f"{Color.GREEN}✅ Backend detenido{Color.RESET}")
        except:
            pass
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, cleanup)

    print_header()

    try:
        check_venv()
        start_backend()

        if not wait_for_backend():
            sys.exit(1)

        verify_project()

        if not build_project():
            sys.exit(1)

        print(step(7, 7, "Ejecutando aplicación..."))

        if not run_app():
            sys.exit(1)

        show_final_message()
        show_logs()

    except KeyboardInterrupt:
        cleanup()
    except Exception as e:
        print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
        sys.exit(1)

if __name__ == "__main__":
    main()
