# Configuration
$baseUrl = "http://localhost:8081"
$timestamp = Get-Date -Format "yyMMddHHmm"

# Colors for better visibility
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$headerColor = "Magenta"

# Test data
$adminCredentials = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$newUser = @{
    username = "test_user_$timestamp"
    email = "test_$timestamp@example.com"
    password = "Test123!"
    role = "EMPLOYEE"
} | ConvertTo-Json

# Helper Functions
function Write-Header {
    param ([string]$text)
    Write-Host "`n=== $text ===" -ForegroundColor $headerColor
}

function Write-Success {
    param ([string]$text)
    Write-Host $text -ForegroundColor $successColor
}

function Write-Error {
    param ([string]$text)
    Write-Host $text -ForegroundColor $errorColor
}

function Write-Info {
    param ([string]$text)
    Write-Host $text -ForegroundColor $infoColor
}

function Test-Endpoint {
    param (
        [string]$name,
        [string]$method,
        [string]$endpoint,
        [string]$body = $null,
        [hashtable]$headers = @{},
        [switch]$continueOnError
    )

    Write-Header "Testing: $name"
    Write-Info "Method: $method"
    Write-Info "Endpoint: $endpoint"
    
    try {
        $params = @{
            Method = $method
            Uri = "$baseUrl$endpoint"
            ContentType = "application/json"
        }

        if ($body) {
            $params.Body = $body
            Write-Info "Request Body:"
            Write-Host $body
        }

        if ($headers.Count -gt 0) {
            $params.Headers = $headers
            Write-Info "Using Authorization Header"
        }

        $response = Invoke-RestMethod @params
        Write-Success "Response:"
        $response | ConvertTo-Json -Depth 10 | Write-Host
        return $response
    }
    catch {
        Write-Error "Failed: $($_.Exception.Message)"
        Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
        if (-not $continueOnError) {
            exit
        }
    }
}

# 1. Admin Login
Write-Header "Starting API Tests - Admin Authentication"
$adminLoginResponse = Test-Endpoint -name "Admin Login" `
    -method "POST" `
    -endpoint "/api/users/register" `
    -body $adminCredentials

$adminToken = $adminLoginResponse.token
$adminHeaders = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# 2. Register New User
$registerResponse = Test-Endpoint -name "User Registration" `
    -method "POST" `
    -endpoint "/api/users/register" `
    -body $newUser `
    -headers $adminHeaders

$newUserId = $registerResponse.id

# 3. Login as New User
$userLoginBody = @{
    username = ($newUser | ConvertFrom-Json).username
    password = ($newUser | ConvertFrom-Json).password
} | ConvertTo-Json

$userLoginResponse = Test-Endpoint -name "User Login" `
    -method "POST" `
    -endpoint "/api/users/login" `
    -body $userLoginBody

$userToken = $userLoginResponse.token
$userHeaders = @{
    "Authorization" = "Bearer $userToken"
    "Content-Type" = "application/json"
}

# 4. Get User Profile
Test-Endpoint -name "Get User Profile" `
    -method "GET" `
    -endpoint "/api/users/profile" `
    -headers $userHeaders

# 5. Update User Profile (Admin only)
$updateProfileBody = @{
    username = ($newUser | ConvertFrom-Json).username
    email = "updated_$timestamp@example.com"
    role = "EMPLOYEE"
} | ConvertTo-Json

Test-Endpoint -name "Update User Profile" `
    -method "PUT" `
    -endpoint "/api/users/profile" `
    -body $updateProfileBody `
    -headers $adminHeaders

# 6. List All Users (Admin only)
Test-Endpoint -name "List All Users" `
    -method "GET" `
    -endpoint "/api/users/list" `
    -headers $adminHeaders

# 7. Deactivate User (Admin only)
Test-Endpoint -name "Deactivate User" `
    -method "DELETE" `
    -endpoint "/api/users/deactivate/$newUserId" `
    -headers $adminHeaders

# Final Summary
Write-Header "Test Summary"
Write-Info "Test User Details:"
Write-Host "Username: $(($newUser | ConvertFrom-Json).username)"
Write-Host "Email: $(($newUser | ConvertFrom-Json).email)"
Write-Host "User ID: $newUserId"

# Save test results
$testResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    adminToken = $adminToken
    userToken = $userToken
    testUser = $newUser | ConvertFrom-Json
    userId = $newUserId
    success = $true
} | ConvertTo-Json

$resultsPath = ".\user-management-test-results.json"
$testResults | Out-File -FilePath $resultsPath
Write-Success "Test results saved to: $resultsPath"
