$baseUrl = "http://localhost:8081"

Write-Host "=== Testing Auth Debug ===" -ForegroundColor Green

$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

Write-Host "`nTesting debug login endpoint..." -ForegroundColor Yellow
try {
    $debugResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/debug/login" `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Host "Debug Response:" -ForegroundColor Green
    $debugResponse | ConvertTo-Json
} catch {
    Write-Host "Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "`nTest completed!" -ForegroundColor Green
