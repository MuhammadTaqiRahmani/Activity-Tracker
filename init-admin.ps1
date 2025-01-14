$baseUrl = "http://localhost:8081"

# Admin registration data
$adminUser = @{
    username = "admin"
    email = "admin@system.com"
    password = "admin123"
    role = "ADMIN"
} | ConvertTo-Json

Write-Host "`n=== Initializing Admin User ===" -ForegroundColor Cyan

# Register admin user
try {
    $registerResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $adminUser `
        -ContentType "application/json"
    Write-Host "Admin Registration Successful!" -ForegroundColor Green
    Write-Host ($registerResponse | ConvertTo-Json) -ForegroundColor Gray
}
catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host "Admin user already exists" -ForegroundColor Yellow
    }
    else {
        Write-Host "Admin Registration Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test admin login
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    Write-Host "Admin Login Test Successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.token)" -ForegroundColor Gray

    # Save admin credentials
    $adminCreds = @{
        username = "admin"
        password = "admin123"
        token = $loginResponse.token
    } | ConvertTo-Json

    $credsPath = ".\admin-credentials.json"
    $adminCreds | Out-File -FilePath $credsPath
    Write-Host "Admin credentials saved to: $credsPath" -ForegroundColor Cyan
}
catch {
    Write-Host "Admin Login Test Failed: $($_.Exception.Message)" -ForegroundColor Red
}
