@echo off
setlocal
cd /d "%~dp0"

if not exist "build\web\index.html" (
  echo [Qiuzhi] Web build is missing. Building now...
  call flutter build web --release --no-wasm-dry-run
  if errorlevel 1 (
    echo.
    echo Build failed. Please make sure Flutter is available in PATH.
    pause
    exit /b 1
  )
)

echo [Qiuzhi] Starting the Edge-safe web entry...
start "Qiuzhi Edge Web Server" /min cmd /c "dart tool\web_server.dart 18766"

for /l %%i in (1,1,15) do (
  powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 http://127.0.0.1:18766/; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>nul
  if not errorlevel 1 goto :open_edge
  timeout /t 1 /nobreak >nul
)

echo.
echo Web server could not start. Please make sure Dart or Flutter is in PATH.
pause
exit /b 1

:open_edge
set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" (
  echo Microsoft Edge was not found. Opening the default browser instead.
  start "" "http://127.0.0.1:18766/?edge=fresh"
  exit /b 0
)

rem A fresh port plus InPrivate prevents reuse of the old Service Worker cache.
start "" "%EDGE%" --inprivate "http://127.0.0.1:18766/?edge=fresh"
exit /b 0
