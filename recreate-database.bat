@echo off
echo ================================================
echo DATABASE RECREATION WITH FIXED SCHEMA
echo ================================================
echo This will DROP and RECREATE the entire database
echo with proper foreign key constraints to fix the
echo orphaned activities issue.
echo.

set /p confirm="Are you sure you want to proceed? (Y/N): "
if /i "%confirm%" NEQ "Y" (
    echo Operation cancelled.
    pause
    exit /b
)

echo.
echo Executing database recreation script...
echo.

sqlcmd -S localhost -E -i recreate-database-fixed-schema.sql -o database-recreation-log.txt

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =============================================
    echo DATABASE RECREATION SUCCESSFUL
    echo =============================================
    echo.
    echo [✓] Database recreated with fixed schema
    echo [✓] Foreign key constraints implemented  
    echo [✓] Orphaned activities issue FIXED
    echo [✓] Sample data inserted
    echo.
    echo Default Admin Credentials:
    echo Username: admin
    echo Password: admin123
    echo.
    echo You can now start the Spring Boot application!
) else (
    echo.
    echo ERROR: Database recreation failed!
    echo Check the log file: database-recreation-log.txt
)

echo.
pause
