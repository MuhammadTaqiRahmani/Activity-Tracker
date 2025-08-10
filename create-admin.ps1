$baseUrl = "http://localhost:8081"

# Admin registration data
$adminData = @{
    username = "Tiqi"
    email = "tiqiq@tiqi.com"
    password = "123tiqi.com"
    role = "ADMIN"
} | ConvertTo-Json

Write-Host "`n=== Creating Admin User ===" -ForegroundColor Cyan

# 1. Register Admin
try {
    $registerResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/register" `
        -Body $adminData `
        -ContentType "application/json"
    Write-Host "Admin Registration Successful!" -ForegroundColor Green
    Write-Host ($registerResponse | ConvertTo-Json) -ForegroundColor Gray
}
catch {
    Write-Host "Admin Registration Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Login as Admin
try {
    $loginBody = @{
        username = "Tiqi"
        password = "123tiqi.com"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Host "`nAdmin Login Successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.token)" -ForegroundColor Gray

    # Save admin credentials
    $adminCreds = @{
        username = "Tiqi"
        password = "123tiqi.com"
        token = $loginResponse.token
        role = $loginResponse.role
    } | ConvertTo-Json

    $credsPath = ".\admin-credentials.json"
    $adminCreds | Out-File -FilePath $credsPath
    Write-Host "`nCredentials saved to: $credsPath" -ForegroundColor Cyan
}
catch {
    Write-Host "Admin Login Failed: $($_.Exception.Message)" -ForegroundColor Red
}
