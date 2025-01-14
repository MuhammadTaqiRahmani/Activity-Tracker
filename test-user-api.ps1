# Configuration
$baseUrl = "http://localhost:8081"
$timestamp = Get-Date -Format "yyMMddHHmm"

# Test data
$adminLogin = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$newUserData = @{
    username = "test_user_$timestamp"
    email = "test_$timestamp@example.com"
    password = "Test123!"
    role = "EMPLOYEE"
} | ConvertTo-Json

Write-Host "`n=== Testing User Management APIs ===" -ForegroundColor Cyan

# 1. Admin Login
Write-Host "`n1. Testing Admin Login..." -ForegroundColor Magenta
try {
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $adminLogin `
        -ContentType "application/json"
    Write-Host "Admin Login Successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.token)" -ForegroundColor Gray
    $adminHeaders = @{
        "Authorization" = "Bearer $($loginResponse.token)"
        "Content-Type" = "application/json"
    }
}
catch {
    Write-Host "Admin Login Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    exit
}

# 2. Register New User
Write-Host "`n2. Testing User Registration..." -ForegroundColor Magenta
try {
    $registerResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $newUserData `
        -Headers $adminHeaders
    Write-Host "User Registration Successful!" -ForegroundColor Green
    $userId = $registerResponse.id
    Write-Host "Created User ID: $userId" -ForegroundColor Gray
}
catch {
    Write-Host "Registration Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 3. New User Login
Write-Host "`n3. Testing New User Login..." -ForegroundColor Magenta
$userLogin = @{
    username = ($newUserData | ConvertFrom-Json).username
    password = ($newUserData | ConvertFrom-Json).password
} | ConvertTo-Json

try {
    $userLoginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $userLogin `
        -ContentType "application/json"
    Write-Host "User Login Successful!" -ForegroundColor Green
    $userHeaders = @{
        "Authorization" = "Bearer $($userLoginResponse.token)"
        "Content-Type" = "application/json"
    }
}
catch {
    Write-Host "User Login Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 4. Get User Profile
Write-Host "`n4. Testing Get Profile..." -ForegroundColor Magenta
try {
    $profileResponse = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/profile" `
        -Headers $userHeaders
    Write-Host "Profile Fetch Successful!" -ForegroundColor Green
    Write-Host ($profileResponse | ConvertTo-Json) -ForegroundColor Gray
}
catch {
    Write-Host "Profile Fetch Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. List All Users (Admin)
Write-Host "`n5. Testing List All Users..." -ForegroundColor Magenta
try {
    $usersResponse = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/list" `
        -Headers $adminHeaders
    Write-Host "Users List Fetch Successful!" -ForegroundColor Green
    Write-Host "Total Users: $($usersResponse.Count)" -ForegroundColor Gray
}
catch {
    Write-Host "Users List Fetch Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Deactivate User (Admin)
Write-Host "`n6. Testing User Deactivation..." -ForegroundColor Magenta
try {
    $deactivateResponse = Invoke-RestMethod -Method Delete `
        -Uri "$baseUrl/api/users/deactivate/$userId" `
        -Headers $adminHeaders
    Write-Host "User Deactivation Successful!" -ForegroundColor Green
}
catch {
    Write-Host "User Deactivation Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Test User Details:" -ForegroundColor Yellow
Write-Host "Username: $(($newUserData | ConvertFrom-Json).username)" -ForegroundColor White
Write-Host "Email: $(($newUserData | ConvertFrom-Json).email)" -ForegroundColor White
Write-Host "User ID: $userId" -ForegroundColor White
Write-Host "==================`n" -ForegroundColor Cyan
