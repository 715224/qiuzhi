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

echo [求知] 网页地址：http://127.0.0.1:18765
start "求知网页版服务" /min cmd /c "dart tool\web_server.dart"

rem 等待服务真正可访问，避免浏览器先打开导致拒绝连接。
for /l %%i in (1,1,15) do (
  powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 http://127.0.0.1:18765/; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>nul
  if not errorlevel 1 goto :open_browser
  timeout /t 1 /nobreak >nul
)

echo.
echo 网页服务启动失败，请确认 Dart/Flutter 已加入 PATH。
pause
exit /b 1

:open_browser
start "" "http://127.0.0.1:18765/?v=388e21c-fix"
exit /b 0
