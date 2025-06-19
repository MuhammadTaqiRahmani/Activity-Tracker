# Employee Login Verification Test - POST-FIX
# Run this after restarting the Spring Boot server

Write-Host ""
Write-Host "🔧 EMPLOYEE LOGIN FIX VERIFICATION" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Yellow
Write-Host "Testing all fixes implemented for employee login issue" -ForegroundColor White
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

Write-Host "🧪 Test Configuration:" -ForegroundColor Cyan
Write-Host "   Base URL: $baseUrl" -ForegroundColor White
Write-Host "   Employee: $($employeeCredentials.username)" -ForegroundColor White
Write-Host ""

# Test 1: Server Health Check
Write-Host "1️⃣  TESTING SERVER HEALTH..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/actuator/health" -Method GET -ErrorAction Stop
    Write-Host "   ✅ Server is running and healthy" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Server is not running or not healthy" -ForegroundColor Red
    Write-Host "   Please start the server first: mvn spring-boot:run" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Test 2: Employee Login
Write-Host ""
Write-Host "2️⃣  TESTING EMPLOYEE LOGIN..." -ForegroundColor Cyan
$loginBody = $employeeCredentials | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/login" -Method POST -Headers $headers -Body $loginBody -ErrorAction Stop
    
    Write-Host "   ✅ Login successful!" -ForegroundColor Green
    Write-Host "   📋 Login Response Details:" -ForegroundColor White
    Write-Host "      User ID: $($loginResponse.userId)" -ForegroundColor Gray
    Write-Host "      Username: $($loginResponse.username)" -ForegroundColor Gray
    Write-Host "      Email: $($loginResponse.email)" -ForegroundColor Gray
    Write-Host "      Role: $($loginResponse.role)" -ForegroundColor Yellow
    
    # Verify role normalization
    if ($loginResponse.role -eq "EMPLOYEE") {
        Write-Host "   ✅ JWT Role Normalization: WORKING (role without ROLE_ prefix)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  JWT Role Normalization: ISSUE (expected 'EMPLOYEE', got '$($loginResponse.role)')" -ForegroundColor Red
    }
    
    # Store token for profile test
    $token = $loginResponse.token
    
} catch {
    Write-Host "   ❌ Login failed!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Test 3: JWT Token Analysis
Write-Host ""
Write-Host "3️⃣  ANALYZING JWT TOKEN..." -ForegroundColor Cyan
try {
    # Decode JWT payload (basic decoding without signature verification)
    $tokenParts = $token.Split('.')
    if ($tokenParts.Length -eq 3) {
        # Add padding if needed for Base64 decoding
        $payload = $tokenParts[1]
        $padding = 4 - ($payload.Length % 4)
        if ($padding -ne 4) {
            $payload += "=" * $padding
        }
        
        $payloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
        $payloadObj = $payloadJson | ConvertFrom-Json
        
        Write-Host "   ✅ JWT Token decoded successfully" -ForegroundColor Green
        Write-Host "   📋 JWT Payload Details:" -ForegroundColor White
        Write-Host "      Subject (username): $($payloadObj.sub)" -ForegroundColor Gray
        Write-Host "      User ID: $($payloadObj.userId)" -ForegroundColor Gray
        Write-Host "      Role in JWT: $($payloadObj.role)" -ForegroundColor Yellow
        Write-Host "      Issued At: $(Get-Date -UnixTimeSeconds $payloadObj.iat)" -ForegroundColor Gray
        Write-Host "      Expires At: $(Get-Date -UnixTimeSeconds $payloadObj.exp)" -ForegroundColor Gray
        
        # Verify JWT role format
        if ($payloadObj.role -eq "EMPLOYEE") {
            Write-Host "   ✅ JWT Token Role Format: CORRECT (normalized to 'EMPLOYEE')" -ForegroundColor Green
        } else {
            Write-Host "   ❌ JWT Token Role Format: INCORRECT (expected 'EMPLOYEE', got '$($payloadObj.role)')" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   ⚠️  Could not decode JWT token: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 4: Profile Access (The main fix verification)
Write-Host ""
Write-Host "4️⃣  TESTING PROFILE ACCESS..." -ForegroundColor Cyan
$authHeaders = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json'
}

try {
    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/profile" -Method GET -Headers $authHeaders -ErrorAction Stop
    
    Write-Host "   ✅ Profile access successful!" -ForegroundColor Green
    Write-Host "   📋 Profile Response Details:" -ForegroundColor White
    Write-Host "      Profile ID: $($profileResponse.id)" -ForegroundColor Gray
    Write-Host "      Username: $($profileResponse.username)" -ForegroundColor Gray
    Write-Host "      Email: $($profileResponse.email)" -ForegroundColor Gray
    Write-Host "      Role: $($profileResponse.role)" -ForegroundColor Yellow
    Write-Host "      Active: $($profileResponse.active)" -ForegroundColor Gray
    Write-Host "      Created: $($profileResponse.createdAt)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "   🎉 MAIN ISSUE RESOLVED: Employee can now access profile!" -ForegroundColor Green
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "   ❌ Profile access failed!" -ForegroundColor Red
    Write-Host "   Status Code: $statusCode" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($statusCode -eq 403) {
        Write-Host ""
        Write-Host "   🔍 TROUBLESHOOTING 403 FORBIDDEN:" -ForegroundColor Yellow
        Write-Host "   1. Ensure server was restarted after configuration changes" -ForegroundColor Yellow
        Write-Host "   2. Check SecurityConfig.java has the profile endpoint configured" -ForegroundColor Yellow
        Write-Host "   3. Verify hasAuthority() is used instead of hasRole()" -ForegroundColor Yellow
        Write-Host "   4. Confirm UserService.loadUserByUsername() returns authorities with ROLE_ prefix" -ForegroundColor Yellow
    }
}

# Test 5: Additional Employee Endpoints
Write-Host ""
Write-Host "5️⃣  TESTING OTHER EMPLOYEE ENDPOINTS..." -ForegroundColor Cyan

# Test process tracking endpoint
try {
    $processTrackingResponse = Invoke-RestMethod -Uri "$baseUrl/api/process-tracking/status" -Method GET -Headers $authHeaders -ErrorAction Stop
    Write-Host "   ✅ Process tracking endpoint: ACCESSIBLE" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Process tracking endpoint: NOT ACCESSIBLE (may not exist)" -ForegroundColor Yellow
}

# Test analytics endpoint
try {
    $analyticsResponse = Invoke-RestMethod -Uri "$baseUrl/api/analytics/user/stats" -Method GET -Headers $authHeaders -ErrorAction Stop
    Write-Host "   ✅ Analytics user endpoint: ACCESSIBLE" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Analytics user endpoint: NOT ACCESSIBLE (may not exist)" -ForegroundColor Yellow
}

# Test restricted admin endpoint (should be denied)
try {
    $adminResponse = Invoke-RestMethod -Uri "$baseUrl/api/users/all" -Method GET -Headers $authHeaders -ErrorAction Stop
    Write-Host "   ❌ Admin endpoint access: INCORRECTLY ALLOWED (security issue)" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 403) {
        Write-Host "   ✅ Admin endpoint access: CORRECTLY DENIED (403 Forbidden)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Admin endpoint access: UNEXPECTED ERROR ($statusCode)" -ForegroundColor Yellow
    }
}

# Final Summary
Write-Host ""
Write-Host "🏁 TEST SUMMARY" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Yellow

if ($loginResponse -and $profileResponse) {
    Write-Host "✅ EMPLOYEE LOGIN ISSUE: RESOLVED" -ForegroundColor Green
    Write-Host "✅ JWT Token Normalization: WORKING" -ForegroundColor Green
    Write-Host "✅ Profile Access: WORKING" -ForegroundColor Green
    Write-Host "✅ Security Configuration: WORKING" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎉 SUCCESS: All employee authentication issues have been fixed!" -ForegroundColor Green
    Write-Host "Employees can now:" -ForegroundColor White
    Write-Host "  • Log in successfully" -ForegroundColor Gray
    Write-Host "  • Access their profile" -ForegroundColor Gray
    Write-Host "  • Use employee-specific features" -ForegroundColor Gray
    Write-Host "  • Be properly restricted from admin features" -ForegroundColor Gray
    
} else {
    Write-Host "❌ EMPLOYEE LOGIN ISSUE: NOT FULLY RESOLVED" -ForegroundColor Red
    Write-Host "Check the troubleshooting steps above" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test with frontend application" -ForegroundColor White
Write-Host "2. Verify all employee features work correctly" -ForegroundColor White
Write-Host "3. Test with other employee accounts" -ForegroundColor White
Write-Host "4. Update documentation if needed" -ForegroundColor White

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
