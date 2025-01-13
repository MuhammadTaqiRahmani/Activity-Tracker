# First, ensure clean startup
Write-Host "=== Starting Test Sequence ===" -ForegroundColor Green

# 1. Start the server
Write-Host "`nStarting server..." -ForegroundColor Yellow
.\start-server.ps1

# 2. Run test endpoints
Write-Host "`nRunning endpoint tests..." -ForegroundColor Yellow
.\test-endpoints.ps1

# 3. Start process collector
Write-Host "`nStarting process collector..." -ForegroundColor Yellow
.\process-collector.ps1

Write-Host "`nTest sequence completed!" -ForegroundColor Green
