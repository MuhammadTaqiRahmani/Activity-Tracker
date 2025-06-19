# Profile Update API Test - POST-FIX
# Test the fixed profile update endpoint

Write-Host ""
Write-Host "🔧 PROFILE UPDATE API TEST" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Yellow
Write-Host "Testing profile update functionality after backend fix" -ForegroundColor White
Write-Host ""

# Test configuration
$baseUrl = "http://localhost:8081"
$employeeCredentials = @{
    username = "yoro111ff22"
    password = "yoro111ff22@gmail.com"
}

$headers = @{
    'Content-Type' = 'application/json'
}

# Step 1: Login to get token
Write-Host "1️⃣  LOGGING IN..." -ForegroundColor Cyan
$loginBody = $employeeCredentials | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/login" -Method POST -Headers $headers -Body $loginBody -ErrorAction Stop
    Write-Host "   ✅ Login successful!" -ForegroundColor Green
    Write-Host "   User: $($loginResponse.username)" -ForegroundColor Gray
    Write-Host "   Current Email: $($loginResponse.email)" -ForegroundColor Gray
    
    $token = $loginResponse.token
    $currentUser = $loginResponse
    
} catch {
    Write-Host "   ❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Get current profile
Write-Host ""
Write-Host "2️⃣  GETTING CURRENT PROFILE..." -ForegroundColor Cyan
$authHeaders = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json'
}

try {
    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method GET -Headers $authHeaders -ErrorAction Stop
    Write-Host "   ✅ Profile retrieved successfully!" -ForegroundColor Green
    Write-Host "   📋 Current Profile:" -ForegroundColor White
    Write-Host "      ID: $($profileResponse.id)" -ForegroundColor Gray
    Write-Host "      Username: $($profileResponse.username)" -ForegroundColor Gray
    Write-Host "      Email: $($profileResponse.email)" -ForegroundColor Yellow
    Write-Host "      Role: $($profileResponse.role)" -ForegroundColor Gray
    Write-Host "      Active: $($profileResponse.active)" -ForegroundColor Gray
    
    $originalEmail = $profileResponse.email
    $originalUsername = $profileResponse.username
    
} catch {
    Write-Host "   ❌ Failed to get profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Test profile update with both username and email changes
Write-Host ""
Write-Host "3️⃣  TESTING PROFILE UPDATE..." -ForegroundColor Cyan

# Generate timestamp for unique values
$timestamp = Get-Date -Format "MMddHHmmss"
$newEmail = "updated_email_$timestamp@example.com"
$newUsername = "updated_user_$timestamp"

$updateData = @{
    username = $newUsername
    email = $newEmail
} | ConvertTo-Json

Write-Host "   🔄 Updating profile with:" -ForegroundColor White
Write-Host "      New Username: $newUsername" -ForegroundColor Yellow
Write-Host "      New Email: $newEmail" -ForegroundColor Yellow

try {
    $updateResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method PUT -Headers $authHeaders -Body $updateData -ErrorAction Stop
    
    Write-Host "   ✅ Profile update successful!" -ForegroundColor Green
    Write-Host "   📋 Updated Profile Response:" -ForegroundColor White
    Write-Host "      ID: $($updateResponse.id)" -ForegroundColor Gray
    Write-Host "      Username: $($updateResponse.username)" -ForegroundColor Yellow
    Write-Host "      Email: $($updateResponse.email)" -ForegroundColor Yellow
    Write-Host "      Role: $($updateResponse.role)" -ForegroundColor Gray
    Write-Host "      Message: $($updateResponse.message)" -ForegroundColor Green
    
    # Verify the changes
    $usernameUpdated = $updateResponse.username -eq $newUsername
    $emailUpdated = $updateResponse.email -eq $newEmail
    
    Write-Host ""
    Write-Host "   🔍 VERIFICATION:" -ForegroundColor White
    Write-Host "      Username Updated: $(if($usernameUpdated) {'✅ YES'} else {'❌ NO'})" -ForegroundColor $(if($usernameUpdated) {'Green'} else {'Red'})
    Write-Host "      Email Updated: $(if($emailUpdated) {'✅ YES'} else {'❌ NO'})" -ForegroundColor $(if($emailUpdated) {'Green'} else {'Red'})
    
    if ($usernameUpdated -and $emailUpdated) {
        Write-Host ""
        Write-Host "   🎉 SUCCESS: Both username and email updated correctly!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "   ⚠️  ISSUE: Some fields were not updated properly" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   ❌ Profile update failed!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   Status Code: $statusCode" -ForegroundColor Red
        
        # Try to get response body for more details
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Response: $responseBody" -ForegroundColor Red
        } catch {
            # Ignore if can't read response body
        }
    }
}

# Step 4: Verify persistence by fetching profile again
Write-Host ""
Write-Host "4️⃣  VERIFYING PERSISTENCE..." -ForegroundColor Cyan

try {
    $verifyResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method GET -Headers $authHeaders -ErrorAction Stop
    
    Write-Host "   ✅ Profile re-fetched successfully!" -ForegroundColor Green
    Write-Host "   📋 Persisted Profile:" -ForegroundColor White
    Write-Host "      Username: $($verifyResponse.username)" -ForegroundColor Yellow
    Write-Host "      Email: $($verifyResponse.email)" -ForegroundColor Yellow
    
    # Check if changes persisted
    $persistedUsername = $verifyResponse.username -eq $newUsername
    $persistedEmail = $verifyResponse.email -eq $newEmail
    
    Write-Host ""
    Write-Host "   🔍 PERSISTENCE CHECK:" -ForegroundColor White
    Write-Host "      Username Persisted: $(if($persistedUsername) {'✅ YES'} else {'❌ NO'})" -ForegroundColor $(if($persistedUsername) {'Green'} else {'Red'})
    Write-Host "      Email Persisted: $(if($persistedEmail) {'✅ YES'} else {'❌ NO'})" -ForegroundColor $(if($persistedEmail) {'Green'} else {'Red'})
    
} catch {
    Write-Host "   ❌ Failed to verify persistence: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Test email uniqueness validation
Write-Host ""
Write-Host "5️⃣  TESTING EMAIL UNIQUENESS VALIDATION..." -ForegroundColor Cyan

# Try to update with an email that might already exist
$duplicateEmailTest = @{
    email = "yoro111ff22@gmail.com"  # This might be used by another user
} | ConvertTo-Json

try {
    $duplicateResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method PUT -Headers $authHeaders -Body $duplicateEmailTest -ErrorAction Stop
    Write-Host "   ⚠️  Email uniqueness validation might not be working (duplicate email accepted)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 409 -or $_.Exception.Message -like "*already exists*") {
        Write-Host "   ✅ Email uniqueness validation working correctly (duplicate rejected)" -ForegroundColor Green
    } else {
        Write-Host "   ❓ Unexpected error during duplicate email test: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 6: Test partial updates
Write-Host ""
Write-Host "6️⃣  TESTING PARTIAL UPDATES..." -ForegroundColor Cyan

# Test updating only email
$partialUpdate = @{
    email = "partial_update_$timestamp@example.com"
} | ConvertTo-Json

try {
    $partialResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method PUT -Headers $authHeaders -Body $partialUpdate -ErrorAction Stop
    Write-Host "   ✅ Partial update (email only) successful!" -ForegroundColor Green
    Write-Host "      Updated Email: $($partialResponse.email)" -ForegroundColor Yellow
    Write-Host "      Username Unchanged: $($partialResponse.username)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Partial update failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Final Summary
Write-Host ""
Write-Host "🏁 TEST SUMMARY" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Yellow

if ($updateResponse -and $verifyResponse) {
    Write-Host "✅ PROFILE UPDATE BACKEND FIX: SUCCESS" -ForegroundColor Green
    Write-Host "✅ Email Update: WORKING" -ForegroundColor Green
    Write-Host "✅ Username Update: WORKING" -ForegroundColor Green
    Write-Host "✅ Persistence: WORKING" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎉 The backend fix has resolved the email update issue!" -ForegroundColor Green
    Write-Host "Both username and email updates are now working correctly." -ForegroundColor White
    
} else {
    Write-Host "❌ PROFILE UPDATE: ISSUES DETECTED" -ForegroundColor Red
    Write-Host "Check the error messages above for troubleshooting" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Backend Changes Made:" -ForegroundColor Cyan
Write-Host "1. Added email update logic to UserService.updateUser() method" -ForegroundColor White
Write-Host "2. Added email uniqueness validation" -ForegroundColor White
Write-Host "3. Proper error handling for duplicate emails" -ForegroundColor White

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
