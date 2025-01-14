$baseUrl = "http://localhost:8081"

# Helper Functions
function Write-Header {
    param ([string]$text)
    Write-Host "`n=== $text ===" -ForegroundColor Cyan
}

function Write-Success {
    param ([string]$text)
    Write-Host $text -ForegroundColor Green
}

function Write-Error {
    param ([string]$text)
    Write-Host $text -ForegroundColor Red
}

# 1. Login and get token
Write-Header "Authenticating User"
$loginBody = @{
    username = "admin"  # or your test user
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Success "Login successful!"
    $userId = $loginResponse.userId
    $headers = @{
        "Authorization" = "Bearer $($loginResponse.token)"
        "Content-Type" = "application/json"
    }
}
catch {
    Write-Error "Login failed: $($_.Exception.Message)"
    exit
}

# 2. Send Process Tracking Data
Write-Header "Sending Process Tracking Data"

# Get current running processes
$processes = Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object -First 3
$currentTime = Get-Date

# Create process tracking logs
$processLogs = $processes | ForEach-Object {
    @{
        userId = $userId
        processName = $_.ProcessName
        windowTitle = $_.MainWindowTitle
        processId = $_.Id.ToString()
        applicationPath = $_.Path
        startTime = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss")
        endTime = $currentTime.AddMinutes(1).ToString("yyyy-MM-ddTHH:mm:ss")
        durationSeconds = 60
        category = "SYSTEM"
        isProductiveApp = $true
        activityType = "PROCESS_MONITORING"
        description = "Process: $($_.ProcessName)"
        workspaceType = "LOCAL"
        applicationCategory = "SYSTEM"
    }
}

try {
    Write-Host "Sending process logs..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/logs/batch" `
        -Headers $headers `
        -Body ($processLogs | ConvertTo-Json) `
        -ContentType "application/json"
    
    Write-Success "Process logs sent successfully!"
    Write-Host "Response:" -ForegroundColor Yellow
    $response | ConvertTo-Json | Write-Host -ForegroundColor Gray
}
catch {
    Write-Error "Failed to send process logs: $($_.Exception.Message)"
}

# 3. Test Activity Endpoints
Write-Header "Testing Activity Endpoints"

# Test Cases Array
$activityTests = @(
    @{
        Name = "Get Today's Activities"
        Method = "GET"
        Endpoint = "/api/activities/today"
    },
    @{
        Name = "Get Activity Summary"
        Method = "GET"
        Endpoint = "/api/activities/summary"
    }
)

foreach ($test in $activityTests) {
    Write-Host "`nTesting: $($test.Name)" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Method $test.Method `
            -Uri "$baseUrl$($test.Endpoint)" `
            -Headers $headers
        
        Write-Success "$($test.Name) successful!"
        Write-Host "Response:" -ForegroundColor Yellow
        $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
    }
    catch {
        Write-Error "$($test.Name) failed: $($_.Exception.Message)"
    }
}

# 4. Summary
Write-Header "Test Summary"
Write-Host "User ID: $userId" -ForegroundColor White
Write-Host "Processes Logged: $($processLogs.Count)" -ForegroundColor White
Write-Host "Endpoints Tested: $($activityTests.Count)" -ForegroundColor White

# Save test results
$testResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    userId = $userId
    processesLogged = $processLogs.Count
    endpointsTested = $activityTests.Count
} | ConvertTo-Json

$resultsPath = ".\tracking-test-results.json"
$testResults | Out-File -FilePath $resultsPath
Write-Success "`nTest results saved to: $resultsPath"
