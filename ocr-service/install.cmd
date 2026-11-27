@echo off
setlocal
cd /d "%~dp0"
set "PIP_CACHE_DIR=%CD%\.cache\pip"
set "TEMP=%CD%\.cache\tmp"
set "TMP=%TEMP%"
if not exist "%TEMP%" mkdir "%TEMP%"
py -3.11 -m venv .venv || goto fail
.venv\Scripts\python.exe -m pip install --upgrade pip || goto fail
.venv\Scripts\python.exe -m pip install -r requirements.txt || goto fail
.venv\Scripts\python.exe -c "import paddle; from paddleocr import PaddleOCR, PPStructureV3; print('OCR imports OK'); paddle.utils.run_check()" || goto fail
echo Installation complete. Run start.cmd.
exit /b 0
:fail
echo Installation failed. Check Python 3.11 x64, internet and disk space.
exit /b 1
