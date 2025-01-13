# Configuration
$baseUrl = "http://localhost:8080"
$userId = 20  # Use the user ID from your previous test
$token = "" # Will be set after login

# Login to get token
$loginBody = @{
    username = "testuser_211178658"  # Use your existing test user
    password = "password123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/users/login" -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "Testing Process Tracking..." -ForegroundColor Green

# Get current running processes
$processes = Get-Process | Select-Object -First 5  # Getting first 5 processes for testing

foreach ($process in $processes) {
    $processData = @{
        userId = $userId
        processName = $process.ProcessName
        windowTitle = $process.MainWindowTitle
        processId = $process.Id
        applicationPath = $process.Path
        startTime = [DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss")
        endTime = [DateTime]::Now.AddMinutes(5).ToString("yyyy-MM-ddTHH:mm:ss")
        durationSeconds = 300
    } | ConvertTo-Json

    Write-Host "Logging process: $($process.ProcessName)" -ForegroundColor Yellow
    
    # Log the process
    $response = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/process-tracking/log" -Headers $headers -Body $processData
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json
}

# Get analytics
$startDate = [DateTime]::Now.AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss")
$endDate = [DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss")

Write-Host "`nGetting process analytics..." -ForegroundColor Yellow
$analytics = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/process-tracking/analytics?userId=$userId&startDate=$startDate&endDate=$endDate" -Headers $headers

Write-Host "Process Analytics:" -ForegroundColor Green
$analytics | ConvertTo-Json -Depth 10

Write-Host "`nTest completed!" -ForegroundColor Green
