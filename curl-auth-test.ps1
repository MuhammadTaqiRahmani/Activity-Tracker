# Test script for role-based authentication using curl-like commands
# This script uses Invoke-WebRequest which is more reliable than Invoke-RestMethod

# Configuration
$baseUrl = "http://localhost:8081/api"
$uniqueSuffix = Get-Random -Minimum 1000 -Maximum 9999

# Function to print with timestamp
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message"
}

# Function to make API requests
function Invoke-ApiRequest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body = "",
        [string]$TestName = ""
    )
    
    Write-Log "RUNNING TEST: $TestName"
    Write-Log "Request: $Method $Uri"
    
    if ($Body -ne "") {
        Write-Log "Request Body: $Body"
    }
    
    $result = @{
        Success = $false
        StatusCode = 0
        Content = $null
    }
    
    try {
        # Create a custom header object including Content-Type
        $customHeaders = @{
            "Content-Type" = "application/json"
        }
        
        # Add any additional headers
        foreach ($key in $Headers.Keys) {
            $customHeaders[$key] = $Headers[$key]
        }
        
        # Make the request
        if ($Method -eq "GET") {
            $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $customHeaders -UseBasicParsing
        } else {
            $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $customHeaders -Body $Body -UseBasicParsing
        }
        
        $result.StatusCode = $response.StatusCode
        $result.Success = $response.StatusCode -ge 200 -and $response.StatusCode -lt 300
        $result.Content = $response.Content
        
        Write-Log "Response: $($response.StatusCode)"
        Write-Log "Content: $($response.Content)"
        
    } catch {
        $errorStatusCode = $_.Exception.Response.StatusCode.value__
        $result.StatusCode = $errorStatusCode
        
        try {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $errorContent = $reader.ReadToEnd()
            $result.Content = $errorContent
            Write-Log "Error Response: $errorContent" -Type "ERROR"
        } catch {
            $result.Content = "Failed to read error response"
            Write-Log "Failed to read error response: $_" -Type "ERROR"
        }
        
        Write-Log "Request failed with status code: $errorStatusCode" -Type "ERROR"
    }
    
    Write-Log "TEST RESULT: $(if ($result.Success) { 'PASSED' } else { 'FAILED' })"
    Write-Log "------------------------"
    return $result
}

# Test 1: Register Employee
Write-Log "=== Testing Registration - Employee ===" -Type "TEST"
$employeeUsername = "employee$uniqueSuffix"
$employeeRegistrationBody = @{
    username = $employeeUsername
    email = "$employeeUsername@example.com"
    password = "password123"
    role = "EMPLOYEE"
} | ConvertTo-Json

$employeeRegistrationResult = Invoke-ApiRequest -Uri "$baseUrl/users/register" -Method "POST" -Body $employeeRegistrationBody -TestName "Register Employee User"

# Test 2: Register Admin
Write-Log "=== Testing Registration - Admin ===" -Type "TEST"
$adminUsername = "admin$uniqueSuffix"
$adminRegistrationBody = @{
    username = $adminUsername
    email = "$adminUsername@example.com"
    password = "password123"
    role = "ADMIN"
} | ConvertTo-Json

$adminRegistrationResult = Invoke-ApiRequest -Uri "$baseUrl/users/register" -Method "POST" -Body $adminRegistrationBody -TestName "Register Admin User"

# Test 3: Register SuperAdmin
Write-Log "=== Testing Registration - SuperAdmin ===" -Type "TEST"
$superadminUsername = "superadmin$uniqueSuffix"
$superadminRegistrationBody = @{
    username = $superadminUsername
    email = "$superadminUsername@example.com"
    password = "password123"
    role = "SUPERADMIN"
} | ConvertTo-Json

$superadminRegistrationResult = Invoke-ApiRequest -Uri "$baseUrl/users/register" -Method "POST" -Body $superadminRegistrationBody -TestName "Register SuperAdmin User"

# Test 4: Register with invalid role
Write-Log "=== Testing Registration - Invalid Role ===" -Type "TEST"
$invalidRoleUsername = "invalid$uniqueSuffix"
$invalidRoleBody = @{
    username = $invalidRoleUsername
    email = "$invalidRoleUsername@example.com"
    password = "password123"
    role = "INVALID_ROLE"
} | ConvertTo-Json

$invalidRoleResult = Invoke-ApiRequest -Uri "$baseUrl/users/register" -Method "POST" -Body $invalidRoleBody -TestName "Register With Invalid Role"

# Test 5: Login as Employee
Write-Log "=== Testing Login - Employee ===" -Type "TEST"
$employeeLoginBody = @{
    username = $employeeUsername
    password = "password123"
} | ConvertTo-Json

$employeeLoginResult = Invoke-ApiRequest -Uri "$baseUrl/users/login" -Method "POST" -Body $employeeLoginBody -TestName "Login as Employee"

# Extract token from employee login response if successful
$employeeToken = $null
if ($employeeLoginResult.Success) {
    try {
        $employeeData = $employeeLoginResult.Content | ConvertFrom-Json
        $employeeToken = $employeeData.token
        Write-Log "Employee Role: $($employeeData.role)"
        Write-Log "Employee Permissions: $($employeeData.permissions | ConvertTo-Json)"
    } catch {
        Write-Log "Failed to parse employee login response: $_" -Type "ERROR"
    }
}

# Test 6: Login as Admin
Write-Log "=== Testing Login - Admin ===" -Type "TEST"
$adminLoginBody = @{
    username = $adminUsername
    password = "password123"
} | ConvertTo-Json

$adminLoginResult = Invoke-ApiRequest -Uri "$baseUrl/users/login" -Method "POST" -Body $adminLoginBody -TestName "Login as Admin"

# Extract token from admin login response if successful
$adminToken = $null
if ($adminLoginResult.Success) {
    try {
        $adminData = $adminLoginResult.Content | ConvertFrom-Json
        $adminToken = $adminData.token
        Write-Log "Admin Role: $($adminData.role)"
        Write-Log "Admin Permissions: $($adminData.permissions | ConvertTo-Json)"
    } catch {
        Write-Log "Failed to parse admin login response: $_" -Type "ERROR"
    }
}

# Test 7: Login as SuperAdmin
Write-Log "=== Testing Login - SuperAdmin ===" -Type "TEST"
$superadminLoginBody = @{
    username = $superadminUsername
    password = "password123"
} | ConvertTo-Json

$superadminLoginResult = Invoke-ApiRequest -Uri "$baseUrl/users/login" -Method "POST" -Body $superadminLoginBody -TestName "Login as SuperAdmin"

# Extract token from superadmin login response if successful
$superadminToken = $null
if ($superadminLoginResult.Success) {
    try {
        $superadminData = $superadminLoginResult.Content | ConvertFrom-Json
        $superadminToken = $superadminData.token
        Write-Log "SuperAdmin Role: $($superadminData.role)"
        Write-Log "SuperAdmin Permissions: $($superadminData.permissions | ConvertTo-Json)"
    } catch {
        Write-Log "Failed to parse superadmin login response: $_" -Type "ERROR"
    }
}

# Test 8: Login with invalid credentials
Write-Log "=== Testing Login - Invalid Credentials ===" -Type "TEST"
$invalidLoginBody = @{
    username = "nonexistent$uniqueSuffix"
    password = "wrongpassword"
} | ConvertTo-Json

$invalidLoginResult = Invoke-ApiRequest -Uri "$baseUrl/users/login" -Method "POST" -Body $invalidLoginBody -TestName "Login with Invalid Credentials"

# Test 9: Employee accessing profile (should succeed)
if ($employeeToken) {
    Write-Log "=== Testing Access - Employee accessing profile ===" -Type "TEST"
    $employeeHeaders = @{
        "Authorization" = "Bearer $employeeToken"
    }
    
    $employeeProfileResult = Invoke-ApiRequest -Uri "$baseUrl/users/profile" -Method "GET" -Headers $employeeHeaders -TestName "Employee Access to Profile"
}

# Test 10: Employee accessing admin endpoint (should fail)
if ($employeeToken) {
    Write-Log "=== Testing Access - Employee accessing admin endpoint ===" -Type "TEST"
    $employeeHeaders = @{
        "Authorization" = "Bearer $employeeToken"
    }
    
    $employeeAdminResult = Invoke-ApiRequest -Uri "$baseUrl/users/all" -Method "GET" -Headers $employeeHeaders -TestName "Employee Access to Admin Endpoint"
}

# Test 11: Admin accessing profile (should succeed)
if ($adminToken) {
    Write-Log "=== Testing Access - Admin accessing profile ===" -Type "TEST"
    $adminHeaders = @{
        "Authorization" = "Bearer $adminToken"
    }
    
    $adminProfileResult = Invoke-ApiRequest -Uri "$baseUrl/users/profile" -Method "GET" -Headers $adminHeaders -TestName "Admin Access to Profile"
}

# Test 12: Admin accessing admin endpoint (should succeed)
if ($adminToken) {
    Write-Log "=== Testing Access - Admin accessing admin endpoint ===" -Type "TEST"
    $adminHeaders = @{
        "Authorization" = "Bearer $adminToken"
    }
    
    $adminEndpointResult = Invoke-ApiRequest -Uri "$baseUrl/users/all" -Method "GET" -Headers $adminHeaders -TestName "Admin Access to Admin Endpoint"
}

# Test 13: SuperAdmin accessing profile (should succeed)
if ($superadminToken) {
    Write-Log "=== Testing Access - SuperAdmin accessing profile ===" -Type "TEST"
    $superadminHeaders = @{
        "Authorization" = "Bearer $superadminToken"
    }
    
    $superadminProfileResult = Invoke-ApiRequest -Uri "$baseUrl/users/profile" -Method "GET" -Headers $superadminHeaders -TestName "SuperAdmin Access to Profile"
}

# Test 14: SuperAdmin accessing admin endpoint (should succeed)
if ($superadminToken) {
    Write-Log "=== Testing Access - SuperAdmin accessing admin endpoint ===" -Type "TEST"
    $superadminHeaders = @{
        "Authorization" = "Bearer $superadminToken"
    }
    
    $superadminEndpointResult = Invoke-ApiRequest -Uri "$baseUrl/users/all" -Method "GET" -Headers $superadminHeaders -TestName "SuperAdmin Access to Admin Endpoint"
}

Write-Log "All tests completed!" -Type "TEST"
