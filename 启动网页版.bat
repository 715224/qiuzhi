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

where python >nul 2>nul
if errorlevel 1 (
  echo 未找到 Python，将直接打开 HTML 文件。
  start "" "%~dp0build\web\index.html"
  exit /b 0
)

echo [求知] 网页地址：http://127.0.0.1:8765
start "求知网页版服务" /min python -m http.server 8765 --directory "build\web"
timeout /t 1 /nobreak >nul
start "" "http://127.0.0.1:8765"
exit /b 0
