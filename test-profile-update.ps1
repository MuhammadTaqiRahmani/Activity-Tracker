$baseUrl = "http://localhost:8081"

# First, login to get a fresh token
$loginBody = @{
    username = "Tiqi"
    password = "123tiqi.com"
} | ConvertTo-Json

Write-Host "`n=== Testing Profile Update ===" -ForegroundColor Cyan

try {
    Write-Host "Logging in..." -ForegroundColor Yellow
    $loginResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/users/login" `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Host "Login successful!" -ForegroundColor Green
    
    $headers = @{
        "Authorization" = "Bearer $($loginResponse.token)"
        "Content-Type" = "application/json"
    }

    # First, get current profile
    Write-Host "`nFetching current profile..." -ForegroundColor Yellow
    $currentProfile = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/profile" `
        -Headers $headers
    
    Write-Host "Current profile:" -ForegroundColor Cyan
    Write-Host ($currentProfile | ConvertTo-Json) -ForegroundColor Gray

    # Update profile
    $updateData = @{
        email = "tiqi.updated@tiqi.com"
        username = "Tiqi"  # keep same username
        role = "ADMIN"     # keep same role
    } | ConvertTo-Json

    Write-Host "`nUpdating profile..." -ForegroundColor Yellow
    $updateResponse = Invoke-RestMethod -Method Put `
        -Uri "$baseUrl/api/users/profile" `
        -Headers $headers `
        -Body $updateData
    
    Write-Host "Profile updated successfully!" -ForegroundColor Green
    Write-Host "Updated profile:" -ForegroundColor Cyan
    Write-Host ($updateResponse | ConvertTo-Json) -ForegroundColor Gray
}
catch {
    Write-Host "`nError occurred!" -ForegroundColor Red
    Write-Host "Status code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error message: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody" -ForegroundColor Red
    }
}
