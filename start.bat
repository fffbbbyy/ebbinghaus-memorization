@echo off
cd /d "A:\艾宾浩斯曲线"
REM Kill old serve instances on common ports
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8765" ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
REM Start server
start "背诵表服务器" npx serve -p 8765 --no-clipboard
REM Wait for server to start, then open browser
timeout /t 3 /nobreak >nul
start "" "http://localhost:8765/index.html"
