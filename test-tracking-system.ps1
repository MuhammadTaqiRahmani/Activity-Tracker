$baseUrl = "http://localhost:8081"

# 1. First register a test user if not exists
$testUser = @{
    username = "tracker_test"
    email = "tracker_test@example.com"
    password = "Test123!"
    role = "EMPLOYEE"
} | ConvertTo-Json

Write-Host "`n=== Setting up Test User ===" -ForegroundColor Cyan

try {
    $registerResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $testUser `
        -ContentType "application/json"
    Write-Host "Test user registered successfully!" -ForegroundColor Green
}
catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host "Test user already exists" -ForegroundColor Yellow
    }
    else {
        Write-Host "Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 2. Login with test user
Write-Host "`n=== Logging in Test User ===" -ForegroundColor Cyan

$loginBody = @{
    username = "tracker_test"
    password = "Test123!"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    
    $headers = @{
        "Authorization" = "Bearer $($loginResponse.token)"
        "Content-Type" = "application/json"
    }
    
    $userId = $loginResponse.userId
    Write-Host "Login successful!" -ForegroundColor Green
    Write-Host "User ID: $userId" -ForegroundColor Gray

    # After successful login, verify the role
    Write-Host "User role: $($loginResponse.role)" -ForegroundColor Gray
    if ($loginResponse.role -notlike "*EMPLOYEE*" -and $loginResponse.role -notlike "*ADMIN*") {
        Write-Host "Warning: User does not have required role (EMPLOYEE or ADMIN)" -ForegroundColor Yellow
        Write-Host "Current role: $($loginResponse.role)" -ForegroundColor Yellow
        $confirm = Read-Host "Do you want to continue anyway? (y/n)"
        if ($confirm -ne "y") {
            exit
        }
    }

    # Ensure proper Authorization header
    $headers = @{
        "Authorization" = "Bearer $($loginResponse.token)"
        "Content-Type" = "application/json"
    }

    Write-Host "Using token: $($loginResponse.token)" -ForegroundColor Gray
}
catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 3. Start collecting and sending process data
Write-Host "`n=== Starting Process Collection ===" -ForegroundColor Cyan

$collectionInterval = 30  # 30 seconds
$maxAttempts = 5  # Number of collection attempts

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "`nCollection Attempt $i of $maxAttempts" -ForegroundColor Yellow
    
    # Collect current processes
    $processes = Get-Process | Where-Object {$_.MainWindowTitle -ne ""}
    $currentTime = Get-Date
    
    $processLogs = $processes | Select-Object -First 3 | ForEach-Object {
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

    # Send process data
    try {
        Write-Host "Sending batch of $($processLogs.Count) processes..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Method Post `
            -Uri "$baseUrl/api/logs/batch" `
            -Headers $headers `
            -Body ($processLogs | ConvertTo-Json) `
            -ContentType "application/json"
        
        Write-Host "Batch sent successfully!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
    }
    catch {
        Write-Host "Failed to send batch: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Get today's activities
    try {
        Write-Host "`nFetching today's activities..." -ForegroundColor Yellow
        Write-Host "Using headers:" -ForegroundColor Gray
        $headers | ConvertTo-Json | Write-Host -ForegroundColor Gray
        
        $activities = Invoke-RestMethod -Method Get `
            -Uri "$baseUrl/api/activities/today" `
            -Headers $headers `
            -Verbose
        
        Write-Host "Activities retrieved successfully!" -ForegroundColor Green
        Write-Host "Count: $($activities.Count)" -ForegroundColor Gray
        $activities | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
    }
    catch {
        Write-Host "Failed to fetch activities:" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
        
        try {
            $errorDetails = $_.ErrorDetails.Message
            Write-Host "Error Details: $errorDetails" -ForegroundColor Red
        }
        catch {
            Write-Host "No additional error details available" -ForegroundColor Red
        }
    }

    if ($i -lt $maxAttempts) {
        Write-Host "`nWaiting $collectionInterval seconds before next collection..." -ForegroundColor Cyan
        Start-Sleep -Seconds $collectionInterval
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
