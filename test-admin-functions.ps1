# Configuration
$baseUrl = "http://localhost:8081"  # Changed from 8080 to 8081

Write-Host "=== Testing Admin Functions ===" -ForegroundColor Green

# Login as admin
Write-Host "`nLogging in as admin..." -ForegroundColor Yellow
try {
    $loginBody = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    Write-Host "Attempting login with credentials:" -ForegroundColor Yellow
    Write-Host $loginBody

    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json" `
        -ErrorAction Stop

    $token = $loginResponse.token
    Write-Host "Login successful! Token obtained: $token" -ForegroundColor Green
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    # Test system status
    Write-Host "`nChecking System Status..." -ForegroundColor Yellow
    $systemStatus = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/admin/system/status" `
        -Headers $headers
    Write-Host "System Status:" -ForegroundColor Green
    $systemStatus | ConvertTo-Json

    # Test user management
    Write-Host "`nListing All Users..." -ForegroundColor Yellow
    $users = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/list" `
        -Headers $headers
    Write-Host "Users:" -ForegroundColor Green
    $users | ConvertTo-Json
}
catch {
    Write-Host "`nError Details:" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
    
    try {
        $errorContent = $_.ErrorDetails.Message
        Write-Host "Error Content: $errorContent" -ForegroundColor Red
    }
    catch {
        Write-Host "Raw Error: $_" -ForegroundColor Red
    }
}

Write-Host "`nTest completed!" -ForegroundColor Green
