@echo off
setlocal
cd /d "%~dp0frontend"
call flutter pub get || exit /b 1
call flutter run -d chrome --web-hostname localhost --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8081/api
exit /b %ERRORLEVEL%
