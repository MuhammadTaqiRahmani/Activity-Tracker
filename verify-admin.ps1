$baseUrl = "http://localhost:8081"

Write-Host "`n=== Verifying Admin Access ===" -ForegroundColor Cyan

# Test admin login
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    Write-Host "Attempting admin login..." -ForegroundColor Yellow
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Host "Admin Login Successful!" -ForegroundColor Green
    
    # Save admin credentials
    $adminCreds = @{
        username = "admin"
        password = "admin123"
        token = $loginResponse.token
        role = $loginResponse.role
    } | ConvertTo-Json

    $credsPath = ".\admin-credentials.json"
    $adminCreds | Out-File -FilePath $credsPath
    Write-Host "Admin credentials saved to: $credsPath" -ForegroundColor Cyan
    Write-Host "Token: $($loginResponse.token)" -ForegroundColor Gray
    Write-Host "Role: $($loginResponse.role)" -ForegroundColor Gray
}
catch {
    Write-Host "`nAdmin Login Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    
    Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "1. Ensure your Spring Boot application is running" -ForegroundColor White
    Write-Host "2. Verify database connection in application.properties" -ForegroundColor White
    Write-Host "3. Check if admin user exists in database" -ForegroundColor White
    Write-Host "4. Verify the admin credentials match data.sql" -ForegroundColor White
}
