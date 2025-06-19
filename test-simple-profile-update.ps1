# Simple Profile Update Test Script
Write-Host "Testing Profile Update Fix" -ForegroundColor Green

# Test login
$headers = @{'Content-Type' = 'application/json'}
$loginBody = @{
    username = 'yoro111ff22'
    password = 'yoro111ff22@gmail.com'
} | ConvertTo-Json

Write-Host "1. Testing login..." -ForegroundColor Cyan
try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Headers $headers -Body $loginBody
    Write-Host "   ✅ Login successful! User: $($loginResponse.username), Email: $($loginResponse.email)" -ForegroundColor Green
    
    $token = $loginResponse.token
    $authHeaders = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
    
    # Test profile access
    Write-Host "2. Testing profile access..." -ForegroundColor Cyan
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method GET -Headers $authHeaders
    Write-Host "   ✅ Profile access successful! Email: $($profileResponse.email)" -ForegroundColor Green
    
    # Test profile update
    Write-Host "3. Testing profile update..." -ForegroundColor Cyan
    $timestamp = Get-Date -Format "HHmmss"
    $updateData = @{
        username = "test_user_$timestamp"
        email = "test_email_$timestamp@example.com"
    } | ConvertTo-Json
    
    $updateResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method PUT -Headers $authHeaders -Body $updateData
    Write-Host "   ✅ Profile update successful!" -ForegroundColor Green
    Write-Host "      New Username: $($updateResponse.username)" -ForegroundColor Yellow
    Write-Host "      New Email: $($updateResponse.email)" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "🎉 SUCCESS: Both username and email updates are working!" -ForegroundColor Green
    
} catch {
    Write-Host "   ❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode) {
        Write-Host "   Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    }
}
