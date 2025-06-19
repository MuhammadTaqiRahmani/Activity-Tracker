# Database Recreation Script - Executes the SQL script to recreate database with fixed schema

# Configuration
$serverName = "localhost"
$scriptPath = ".\recreate-database-fixed-schema.sql"

Write-Host "=== DATABASE RECREATION WITH FIXED SCHEMA ===" -ForegroundColor Cyan
Write-Host "This script will recreate the entire database with proper foreign key constraints" -ForegroundColor Yellow
Write-Host ""

# Check if SQL script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: SQL script not found at $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "SQL Script: $scriptPath" -ForegroundColor Green
Write-Host "Server: $serverName" -ForegroundColor Green
Write-Host ""

# Prompt for confirmation
$confirmation = Read-Host "This will DROP and RECREATE the entire database. Are you sure? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Executing database recreation script..." -ForegroundColor Cyan

try {
    # Execute the SQL script using sqlcmd
    $result = & sqlcmd -S $serverName -E -i $scriptPath -o "database-recreation-log.txt"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=== DATABASE RECREATION SUCCESSFUL ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "✅ Database recreated with fixed schema" -ForegroundColor Green
        Write-Host "✅ Foreign key constraints implemented" -ForegroundColor Green
        Write-Host "✅ Orphaned activities issue FIXED" -ForegroundColor Green
        Write-Host "✅ Sample data inserted" -ForegroundColor Green
        Write-Host ""
        Write-Host "Default Admin Credentials:" -ForegroundColor Cyan
        Write-Host "Username: admin" -ForegroundColor White
        Write-Host "Password: admin123" -ForegroundColor White
        Write-Host ""
        Write-Host "Log file: database-recreation-log.txt" -ForegroundColor Gray
        Write-Host ""
        Write-Host "You can now start the Spring Boot application!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "ERROR: Database recreation failed!" -ForegroundColor Red
        Write-Host "Check the log file: database-recreation-log.txt" -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to execute SQL script" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "1. SQL Server is running" -ForegroundColor Yellow
    Write-Host "2. You have appropriate permissions" -ForegroundColor Yellow
    Write-Host "3. sqlcmd is installed and in PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
