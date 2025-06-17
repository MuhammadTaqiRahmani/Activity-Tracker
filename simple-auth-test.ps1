# Simple test script for role-based authentication
# Tests register and login with different roles

$baseUrl = "http://localhost:8081/api"

function Log-Message {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Test-Register {
    param (
        [string]$username,
        [string]$email,
        [string]$password,
        [string]$role
    )
    
    try {
        Log-Message "Testing registration for role: $role"
        
        $body = @{
            username = $username
            email = $email
            password = $password
            role = $role
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/users/register" -Method Post -Body $body -ContentType "application/json"
        Log-Message "Registration successful: $($response | ConvertTo-Json -Depth 3)"
        return $true
    } catch {
        Log-Message "Registration failed: $_"
        return $false
    }
}

function Test-Login {
    param (
        [string]$username,
        [string]$password
    )
    
    try {
        Log-Message "Testing login for user: $username"
        
        $body = @{
            username = $username
            password = $password
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/users/login" -Method Post -Body $body -ContentType "application/json"
        Log-Message "Login successful. Role: $($response.role)"
        Log-Message "Permissions: $($response.permissions | ConvertTo-Json -Depth 3)"
        
        return @{
            success = $true
            token = $response.token
            role = $response.role
            permissions = $response.permissions
        }
    } catch {
        Log-Message "Login failed: $_"
        return @{
            success = $false
        }
    }
}

function Test-AccessEndpoint {
    param (
        [string]$endpoint,
        [string]$token
    )
    
    try {
        Log-Message "Testing access to endpoint: $endpoint"
        
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        $response = Invoke-RestMethod -Uri "$baseUrl$endpoint" -Method Get -Headers $headers -ContentType "application/json"
        Log-Message "Access successful: $($response | ConvertTo-Json -Depth 3)"
        return $true
    } catch {
        Log-Message "Access failed: $_"
        return $false
    }
}

# Generate unique suffix for usernames
$uniqueSuffix = Get-Random -Minimum 1000 -Maximum 9999

# Test employee role
$employeeUsername = "employee$uniqueSuffix"
Log-Message "==== Testing EMPLOYEE role ===="
$registerResult = Test-Register -username $employeeUsername -email "$employeeUsername@example.com" -password "password123" -role "EMPLOYEE"

if ($registerResult) {
    $loginResult = Test-Login -username $employeeUsername -password "password123"
    
    if ($loginResult.success) {
        # Test endpoints with employee token
        Test-AccessEndpoint -endpoint "/users/profile" -token $loginResult.token
        Test-AccessEndpoint -endpoint "/users/all" -token $loginResult.token  # Should fail for employee
    }
}

# Test admin role
$adminUsername = "admin$uniqueSuffix"
Log-Message "==== Testing ADMIN role ===="
$registerResult = Test-Register -username $adminUsername -email "$adminUsername@example.com" -password "password123" -role "ADMIN"

if ($registerResult) {
    $loginResult = Test-Login -username $adminUsername -password "password123"
    
    if ($loginResult.success) {
        # Test endpoints with admin token
        Test-AccessEndpoint -endpoint "/users/profile" -token $loginResult.token
        Test-AccessEndpoint -endpoint "/users/all" -token $loginResult.token  # Should succeed for admin
    }
}

# Test superadmin role
$superadminUsername = "superadmin$uniqueSuffix"
Log-Message "==== Testing SUPERADMIN role ===="
$registerResult = Test-Register -username $superadminUsername -email "$superadminUsername@example.com" -password "password123" -role "SUPERADMIN"

if ($registerResult) {
    $loginResult = Test-Login -username $superadminUsername -password "password123"
    
    if ($loginResult.success) {
        # Test endpoints with superadmin token
        Test-AccessEndpoint -endpoint "/users/profile" -token $loginResult.token
        Test-AccessEndpoint -endpoint "/users/all" -token $loginResult.token  # Should succeed for superadmin
    }
}

Log-Message "==== Testing invalid role ===="
Test-Register -username "invalid$uniqueSuffix" -email "invalid$uniqueSuffix@example.com" -password "password123" -role "INVALID_ROLE"

Log-Message "==== Testing invalid credentials ===="
Test-Login -username "nonexistent" -password "wrongpassword"

Log-Message "Testing completed"
