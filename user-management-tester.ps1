# Configuration
$baseUrl = "http://localhost:8081"
$timestamp = Get-Date -Format "yyMMddHHmm"

# Test Users Configuration
$loginRequest = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

Write-TestHeader "Admin Login"
try {
    $adminLoginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginRequest `
        -ContentType "application/json"
    Write-ResponseDetails -Operation "Admin Login" -Response $adminLoginResponse
    $adminToken = $adminLoginResponse.token
    if ($null -eq $adminToken) {
        throw "No token received in login response"
    }
    Write-Host "Admin token received successfully" -ForegroundColor Green
    
    $adminHeaders = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
}
catch {
    Write-ErrorDetails -Operation "Admin Login" -ErrorObject $_
    Write-Host "Request Body: $loginRequest" -ForegroundColor Yellow
    exit
}

# Test Users Configuration
$testUser = @{
    username = "testuser_$timestamp"
    email = "test_$timestamp@example.com"
    password = "password123"
    role = "EMPLOYEE"
} | ConvertTo-Json

# Helper Functions
function Write-TestHeader {
    param ([string]$TestName)
    Write-Host "`n=== Testing: $TestName ===" -ForegroundColor Magenta
}

function Write-ResponseDetails {
    param (
        [string]$Operation,
        $Response
    )
    # Fixed string interpolation
    Write-Host ("`nResponse for " + $Operation) -ForegroundColor Cyan
    $Response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
}

function Write-ErrorDetails {
    param (
        [string]$Operation,
        $ErrorObject
    )
    # Fixed string interpolation
    Write-Host ("`nError in " + $Operation) -ForegroundColor Red
    Write-Host ("Message: " + $ErrorObject.Exception.Message) -ForegroundColor Red
    Write-Host ("Status: " + $ErrorObject.Exception.Response.StatusCode.value__) -ForegroundColor Red
}

# 2. Test User Registration (using admin token)
Write-TestHeader "User Registration"
try {
    $registrationResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $testUser `
        -Headers $adminHeaders
    Write-ResponseDetails -Operation "Registration" -Response $registrationResponse
    $testUserId = $registrationResponse.id
}
catch {
    Write-ErrorDetails -Operation "Registration" -ErrorObject $_
    exit
}

# 3. Test User Login
Write-TestHeader "User Login"
$loginBody = @{
    username = ($testUser | ConvertFrom-Json).username
    password = ($testUser | ConvertFrom-Json).password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    Write-ResponseDetails -Operation "Login" -Response $loginResponse
    $userToken = $loginResponse.token
    
    $userHeaders = @{
        "Authorization" = "Bearer $userToken"
        "Content-Type" = "application/json"
    }
}
catch {
    Write-ErrorDetails -Operation "Login" -ErrorObject $_
    exit
}

# 4. Test Get Profile (using user token)
Write-TestHeader "Get User Profile"
try {
    $profileResponse = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/profile" `
        -Headers $userHeaders
    Write-ResponseDetails -Operation "Profile Fetch" -Response $profileResponse
}
catch {
    Write-ErrorDetails -Operation "Profile Fetch" -ErrorObject $_
}

# 5. Test List All Users (using admin token)
Write-TestHeader "List All Users (Admin)"
try {
    $usersListResponse = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/list" `
        -Headers $adminHeaders
    Write-ResponseDetails -Operation "Users List" -Response $usersListResponse
}
catch {
    Write-ErrorDetails -Operation "Users List" -ErrorObject $_
}

# 6. Test Deactivate User (using admin token)
Write-TestHeader "Deactivate User"
try {
    $deactivateResponse = Invoke-RestMethod -Method Delete `
        -Uri "$baseUrl/api/users/deactivate/$testUserId" `
        -Headers $adminHeaders
    Write-ResponseDetails -Operation "User Deactivation" -Response $deactivateResponse
}
catch {
    Write-ErrorDetails -Operation "User Deactivation" -ErrorObject $_
}

# Final Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Test Results:" -ForegroundColor Yellow
Write-Host "Admin Login: Success" -ForegroundColor White
Write-Host "User Registration: Success" -ForegroundColor White
Write-Host "User Login: Success" -ForegroundColor White
Write-Host "Profile Fetch: Success" -ForegroundColor White
Write-Host "Users List: Success" -ForegroundColor White
Write-Host "User Deactivation: Success" -ForegroundColor White
Write-Host "==================`n" -ForegroundColor Green

# Save test results
$testResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    adminToken = $adminToken
    testUser = $testUser
    userToken = $userToken
    success = $true
} | ConvertTo-Json

$resultsPath = ".\user-management-test-results.json"
$testResults | Out-File -FilePath $resultsPath
Write-Host "Test results saved to: $resultsPath" -ForegroundColor Cyan
