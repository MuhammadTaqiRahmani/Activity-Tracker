# Configuration
$baseUrl = "http://localhost:8081"
$timestamp = Get-Date -Format "yyMMddHHmm"

# Check if admin credentials exist
$credsPath = ".\admin-credentials.json"
if (-not (Test-Path $credsPath)) {
    Write-Host "Admin credentials not found. Please run init-admin.ps1 first." -ForegroundColor Red
    exit
}

# Load admin credentials
$adminCreds = Get-Content $credsPath | ConvertFrom-Json
$adminHeaders = @{
    "Authorization" = "Bearer $($adminCreds.token)"
    "Content-Type" = "application/json"
}

# Test data for new user
$newUser = @{
    username = "user_$timestamp"
    email = "user_$timestamp@example.com"
    password = "Test123!"
    role = "EMPLOYEE"
} | ConvertTo-Json

function Write-TestCase {
    param ([string]$name)
    Write-Host "`n=== Testing: $name ===" -ForegroundColor Magenta
}

function Write-Success {
    param ([string]$message)
    Write-Host $message -ForegroundColor Green
}

function Write-Error {
    param ([string]$message)
    Write-Host $message -ForegroundColor Red
}

# 2. Register New User (Admin Only)
Write-TestCase "User Registration (Admin Only)"
try {
    $registerResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $newUser `
        -Headers $adminHeaders
    Write-Success "User Registration Successful!"
    Write-Host "Created User ID: $($registerResponse.id)" -ForegroundColor Gray
    $userId = $registerResponse.id
}
catch {
    Write-Error "Registration Failed: $($_.Exception.Message)"
    exit
}

# 3. User Login
Write-TestCase "New User Login"
$userCreds = @{
    username = ($newUser | ConvertFrom-Json).username
    password = ($newUser | ConvertFrom-Json).password
} | ConvertTo-Json

try {
    $userLoginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $userCreds `
        -ContentType "application/json"
    Write-Success "User Login Successful!"
    
    $userHeaders = @{
        "Authorization" = "Bearer $($userLoginResponse.token)"
        "Content-Type" = "application/json"
    }
}
catch {
    Write-Error "User Login Failed: $($_.Exception.Message)"
    exit
}

# 4. Get User Profile (User Operation)
Write-TestCase "Get User Profile (User Operation)"
try {
    $profileResponse = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/profile" `
        -Headers $userHeaders
    Write-Success "Profile Fetch Successful!"
    $profileResponse | ConvertTo-Json | Write-Host -ForegroundColor Gray
}
catch {
    Write-Error "Profile Fetch Failed: $($_.Exception.Message)"
}

# 5. Update Profile (Admin Only)
Write-TestCase "Update User Profile (Admin Only)"
$updateData = @{
    username = ($newUser | ConvertFrom-Json).username
    email = "updated_$timestamp@example.com"
    role = "EMPLOYEE"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Method Put `
        -Uri "$baseUrl/api/users/profile" `
        -Body $updateData `
        -Headers $adminHeaders
    Write-Success "Profile Update Successful!"
}
catch {
    Write-Error "Profile Update Failed: $($_.Exception.Message)"
}

# 6. List All Users (Admin Only)
Write-TestCase "List All Users (Admin Only)"
try {
    $usersResponse = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/list" `
        -Headers $adminHeaders
    Write-Success "Users List Fetch Successful!"
    Write-Host "Total Users: $($usersResponse.Count)" -ForegroundColor Gray
}
catch {
    Write-Error "Users List Fetch Failed: $($_.Exception.Message)"
}

# 7. Deactivate User (Admin Only)
Write-TestCase "Deactivate User (Admin Only)"
try {
    $deactivateResponse = Invoke-RestMethod -Method Delete `
        -Uri "$baseUrl/api/users/deactivate/$userId" `
        -Headers $adminHeaders
    Write-Success "User Deactivation Successful!"
}
catch {
    Write-Error "User Deactivation Failed: $($_.Exception.Message)"
}

# Test Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Test User Details:" -ForegroundColor Yellow
Write-Host "Username: $(($newUser | ConvertFrom-Json).username)" -ForegroundColor White
Write-Host "Email: $(($newUser | ConvertFrom-Json).email)" -ForegroundColor White
Write-Host "User ID: $userId" -ForegroundColor White

# Save test results
$testResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    testUser = $newUser | ConvertFrom-Json
    userId = $userId
    adminToken = $adminCreds.token
    userToken = $userLoginResponse.token
} | ConvertTo-Json

$resultsPath = ".\user-management-test-results.json"
$testResults | Out-File -FilePath $resultsPath
Write-Success "`nTest results saved to: $resultsPath"
