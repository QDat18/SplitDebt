@echo off
setlocal
cd /d "%~dp0api"
if not exist .env (echo Missing api\.env - configure a separate demo database and JWT secret. & exit /b 1)
if not exist "%JAVA_HOME%\bin\javac.exe" (echo JAVA_HOME must point to JDK 21. & exit /b 1)
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "SPRING_PROFILES_ACTIVE=release"
set "SERVER_BIND_ADDRESS=127.0.0.1"
set "PORT=8081"
set "OCR_SERVICE_URL=http://127.0.0.1:8002"
set "CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000"
call mvnw.cmd -DskipTests package || exit /b 1
java -jar target\api-0.0.1-SNAPSHOT.jar
exit /b %ERRORLEVEL%
