Write-Host "Checking ports 8080 and 8081..." -ForegroundColor Yellow

$ports = @(8080, 8081)
foreach ($port in $ports) {
    $processId = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess
    if ($processId) {
        $process = Get-Process -Id $processId
        Write-Host "Found process using port $port : $($process.ProcessName) (ID: $processId)" -ForegroundColor Red
        Stop-Process -Id $processId -Force
        Write-Host "Killed process on port $port" -ForegroundColor Green
    } else {
        Write-Host "No process found on port $port" -ForegroundColor Green
    }
}
