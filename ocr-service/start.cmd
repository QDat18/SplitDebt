@echo off
setlocal
cd /d "%~dp0"
set "PADDLE_PDX_CACHE_HOME=%CD%\.cache\paddlex"
rem Cached models can load without waiting for the optional model-host connectivity probe.
set "DISABLE_MODEL_SOURCE_CHECK=True"
set "HF_HOME=%CD%\.cache\huggingface"
set "TEMP=%CD%\.cache\tmp"
set "TMP=%TEMP%"
if not exist "%TEMP%" mkdir "%TEMP%"
if not exist .venv\Scripts\python.exe (echo Run install.cmd first. & exit /b 1)
.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8002 --workers 1 --no-access-log
