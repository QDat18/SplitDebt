@echo off
setlocal
echo === Backend health ===
curl.exe --max-time 10 -sS -i http://localhost:8081/api/health
if errorlevel 1 (echo Backend is unreachable. Check the Spring Boot console. & exit /b 1)
echo.
echo === Login CORS preflight: localhost ===
curl.exe --max-time 10 -sS -i -X OPTIONS http://localhost:8081/api/auth/login -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: content-type"
echo.
echo === OCR CORS preflight: 127.0.0.1 ===
curl.exe --max-time 10 -sS -i -X OPTIONS http://localhost:8081/api/v1/receipts/advanced -H "Origin: http://127.0.0.1:3000" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: content-type,authorization"
echo.
echo === Optional OCR service ===
curl.exe --max-time 5 -sS -i http://127.0.0.1:8002/health
echo.
echo === Expected: backend health 200, preflights 200 with matching Access-Control-Allow-Origin. OCR service is optional for login. ===
