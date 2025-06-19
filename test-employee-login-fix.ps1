# Employee Login Test - Verify JWT Fix
Write-Host "Testing Employee Login after JWT Token Fix" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Yellow

$headers = @{
    'Content-Type' = 'application/json'
}

$loginBody = @{
    username = 'yoro111ff22'
    password = 'yoro111ff22@gmail.com'
} | ConvertTo-Json

try {
    # Test login
    Write-Host "`n1. Testing Login..." -ForegroundColor Cyan
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Headers $headers -Body $loginBody
    
    Write-Host "✅ Login Successful!" -ForegroundColor Green
    Write-Host "   User ID: $($loginResponse.userId)" -ForegroundColor White
    Write-Host "   Username: $($loginResponse.username)" -ForegroundColor White
    Write-Host "   Role: $($loginResponse.role)" -ForegroundColor White
    Write-Host "   Email: $($loginResponse.email)" -ForegroundColor White
    
    # Test profile access with the JWT token
    Write-Host "`n2. Testing Profile Access..." -ForegroundColor Cyan
    $authHeaders = @{
        'Authorization' = "Bearer $($loginResponse.token)"
        'Content-Type' = 'application/json'
    }
    
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method GET -Headers $authHeaders
    
    Write-Host "✅ Profile Access Successful!" -ForegroundColor Green
    Write-Host "   Profile ID: $($profileResponse.id)" -ForegroundColor White
    Write-Host "   Profile Username: $($profileResponse.username)" -ForegroundColor White
    Write-Host "   Profile Role: $($profileResponse.role)" -ForegroundColor White
    Write-Host "   Profile Email: $($profileResponse.email)" -ForegroundColor White
    
    Write-Host "`n🎉 SUCCESS: Employee login and profile access are now working!" -ForegroundColor Green
    Write-Host "The JWT token role normalization fix has resolved the 403 Forbidden issue." -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error occurred:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   Status Code: $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n" + "=" * 50 -ForegroundColor Yellow
Write-Host "Employee Login Test Completed" -ForegroundColor Green
