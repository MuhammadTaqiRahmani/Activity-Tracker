# Store the base URL
$baseUrl = "http://localhost:8080"
$token = ""

# 1. Register a test user
Write-Host "Registering test user..."
$registerBody = @{
    username = "testuser_$(Get-Random)"  # Add random suffix to avoid duplicates
    password = "password123"
    email = "test_$(Get-Random)@example.com"  # Add random suffix to avoid duplicates
    role = "EMPLOYEE"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/users/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "Registration Response: $($response | ConvertTo-Json)"
    $username = ($registerBody | ConvertFrom-Json).username
    $password = ($registerBody | ConvertFrom-Json).password
} catch {
    Write-Host "Registration Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

# 2. Login and get JWT token
Write-Host "`nLogging in..."
$loginBody = @{
    username = $username
    password = $password
} | ConvertTo-Json

try {
    $token = Invoke-RestMethod -Uri "$baseUrl/api/users/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "JWT Token received: $token"
} catch {
    Write-Host "Login Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

# Create headers with JWT token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 3. Simulate keystroke activity
Write-Host "`nSimulating keystroke activity..."
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/test/tracking/simulate-keystroke?userId=1" -Method Post -Headers $headers
    Write-Host "Keystroke Response: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Keystroke Simulation Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

# 4. Simulate application usage
Write-Host "`nSimulating application usage..."
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/test/tracking/simulate-app-usage?userId=1&appName=VS%20Code&duration=3600" -Method Post -Headers $headers
    Write-Host "App Usage Response: $($response | ConvertTo-Json)"
} catch {
    Write-Host "App Usage Simulation Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

# 5. Get daily report
Write-Host "`nFetching daily report..."
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/test/tracking/simulate-daily-report?userId=1" -Method Get -Headers $headers
    Write-Host "Daily Report: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Daily Report Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

# 6. Get productive time
Write-Host "`nFetching productive time..."
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/activities/productive-time?userId=1" -Method Get -Headers $headers
    Write-Host "Productive Time: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Productive Time Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

# 7. Get application usage statistics
Write-Host "`nFetching application usage statistics..."
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/activities/application-usage?userId=1" -Method Get -Headers $headers
    Write-Host "Application Usage Stats: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Application Usage Stats Error: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Response.StatusDescription)"
    Write-Host $_.Exception.Message
    exit
}

Write-Host "`nTest completed!"
