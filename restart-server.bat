@echo off
echo Restarting Spring Boot Server...
echo =====================================

echo Killing any existing Java processes...
taskkill /f /im java.exe 2>nul

echo Waiting 3 seconds...
timeout /t 3 /nobreak >nul

echo Starting Spring Boot server...
echo Please wait for server to start completely before running tests...

cd /d "%~dp0"
call mvnw.cmd spring-boot:run

pause
