Write-Host "Starting Spring Boot Application..." -ForegroundColor Green

# Kill any existing Java processes
Get-Process | Where-Object { $_.ProcessName -eq "java" } | ForEach-Object {
    Write-Host "Killing existing Java process: $($_.Id)" -ForegroundColor Yellow
    Stop-Process -Id $_.Id -Force
}

# Start the Spring Boot application
try {
    Write-Host "Starting server on port 8081..." -ForegroundColor Yellow
    $process = Start-Process "mvn" -ArgumentList "spring-boot:run" -NoNewWindow -PassThru
    
    # Wait for server to start
    Write-Host "Waiting for server to start..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    $started = $false
    
    while (-not $started -and $attempt -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -Method GET -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $started = $true
                Write-Host "Server started successfully!" -ForegroundColor Green
            }
        }
        catch {
            $attempt++
            Write-Host "Attempt $attempt of $maxAttempts..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }

    if (-not $started) {
        throw "Server failed to start after $maxAttempts attempts"
    }

    # Run the process collector
    Write-Host "Starting process collector..." -ForegroundColor Green
    .\process-collector.ps1
}
catch {
    Write-Host "Error starting server: $_" -ForegroundColor Red
}
