# Configuration
$baseUrl = "http://localhost:8081"
$timestamp = Get-Date -Format "yyMMddHHmm"
$testUsername = "testuser_$timestamp"
$testEmail = "test_$timestamp@example.com"
$testPassword = "password123"

# Function to display formatted response
function Write-ResponseDetails {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        [Parameter(Mandatory=$true)]
        $Response
    )
    
    Write-Host "`n=== $Operation Results ===" -ForegroundColor Cyan
    Write-Host "Status: Success" -ForegroundColor Green
    Write-Host "Response Details:" -ForegroundColor Yellow
    $Response | ConvertTo-Json | Write-Host -ForegroundColor White
    Write-Host "========================`n" -ForegroundColor Cyan
}

# Function to handle errors
function Write-ErrorDetails {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        [Parameter(Mandatory=$true)]
        $ErrorObject
    )
    
    Write-Host "`n=== $Operation Failed ===" -ForegroundColor Red
    Write-Host "Error Message: $($ErrorObject.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($ErrorObject.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "========================`n" -ForegroundColor Red
}

# Test Registration
Write-Host "Testing User Registration..." -ForegroundColor Magenta
$registrationBody = @{
    username = $testUsername
    email = $testEmail
    password = $testPassword
    role = "EMPLOYEE"
} | ConvertTo-Json

try {
    $registrationResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $registrationBody `
        -ContentType "application/json"
    Write-ResponseDetails -Operation "Registration" -Response $registrationResponse
}
catch {
    Write-ErrorDetails -Operation "Registration" -ErrorObject $_
    exit
}

# Test Login
Write-Host "Testing User Login..." -ForegroundColor Magenta
$loginBody = @{
    username = $testUsername
    password = $testPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    Write-ResponseDetails -Operation "Login" -Response $loginResponse
    
    # Store token for further use
    $token = $loginResponse.token
    
    # Test protected endpoint (get profile)
    Write-Host "Testing Protected Endpoint (Profile)..." -ForegroundColor Magenta
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $profileResponse = Invoke-RestMethod -Method Get `
            -Uri "$baseUrl/api/users/profile" `
            -Headers $headers
        Write-ResponseDetails -Operation "Profile Fetch" -Response $profileResponse
    }
    catch {
        Write-ErrorDetails -Operation "Profile Fetch" -ErrorObject $_
    }
}
catch {
    Write-ErrorDetails -Operation "Login" -ErrorObject $_
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Test Username: $testUsername" -ForegroundColor Yellow
Write-Host "Test Email: $testEmail" -ForegroundColor Yellow
Write-Host "JWT Token: $token" -ForegroundColor Gray
Write-Host "==================`n" -ForegroundColor Green

# Save credentials for future use
$credentials = @{
    username = $testUsername
    email = $testEmail
    password = $testPassword
    token = $token
} | ConvertTo-Json

$credentialsPath = ".\test-credentials.json"
$credentials | Out-File -FilePath $credentialsPath
Write-Host "Credentials saved to: $credentialsPath" -ForegroundColor Cyan
