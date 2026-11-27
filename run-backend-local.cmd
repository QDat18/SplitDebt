@echo off
setlocal
cd /d "%~dp0api"
if not exist .env (echo Missing api\.env & exit /b 1)
if not exist "%JAVA_HOME%\bin\javac.exe" (echo JAVA_HOME must point to JDK 21. & exit /b 1)
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000"
call mvnw.cmd clean spring-boot:run
exit /b %ERRORLEVEL%
