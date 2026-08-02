@echo off
setlocal
cd /d "%~dp0"

if not exist "build\web\index.html" (
  echo [求知] 尚未生成网页版，正在构建...
  call flutter build web --release --no-wasm-dry-run
  if errorlevel 1 (
    echo.
    echo 构建失败，请确认已经安装 Flutter。
    pause
    exit /b 1
  )
)

echo [求知] 正在启动 Edge 专用入口...
start "求知网页版 Edge 服务" /min cmd /c "dart tool\web_server.dart 18766"

for /l %%i in (1,1,15) do (
  powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 http://127.0.0.1:18766/; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>nul
  if not errorlevel 1 goto :open_edge
  timeout /t 1 /nobreak >nul
)

echo.
echo 网页服务启动失败，请确认 Dart/Flutter 已加入 PATH。
pause
exit /b 1

:open_edge
set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" (
  echo 找不到 Microsoft Edge，将使用默认浏览器。
  start "" "http://127.0.0.1:18766/?edge=fresh"
  exit /b 0
)

rem InPrivate 使用独立临时站点数据，新端口也与旧 Service Worker 缓存隔离。
start "" "%EDGE%" --inprivate "http://127.0.0.1:18766/?edge=fresh"
exit /b 0
