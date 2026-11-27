@echo off
setlocal
cd /d "%~dp0"
if not exist "..\docs\ocr-test\layout\sample-printed.png" (echo Missing sample image. Apply the layout update first. & exit /b 1)
if not exist .cache mkdir .cache
curl.exe -sS --fail --max-time 1800 -H "Content-Type: application/octet-stream" --data-binary "@..\docs\ocr-test\layout\sample-printed.png" "http://127.0.0.1:8002/recognize?mode=ocr" -o ".cache\sample-ocr.json" || goto fail
curl.exe -sS --fail --max-time 1800 -H "Content-Type: application/octet-stream" --data-binary "@..\docs\ocr-test\layout\sample-printed.png" "http://127.0.0.1:8002/recognize?mode=structure" -o ".cache\sample-structure.json" || goto fail
echo Both models returned results. Inspect .cache\sample-ocr.json and .cache\sample-structure.json.
exit /b 0
:fail
echo Warmup failed. Check the OCR service console. Fast OCR still works independently.
exit /b 1
