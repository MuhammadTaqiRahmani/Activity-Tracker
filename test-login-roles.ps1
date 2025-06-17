## Script to test role-based login
## This script tests login with different roles and displays the results clearly

# Base URL for the API
$baseUrl = "http://localhost:8081/api"

# Generate a unique suffix for test usernames
$uniqueSuffix = Get-Random -Minimum 10000 -Maximum 99999

# Clean output format
function Write-Header {
    param([string]$title)
    
    Write-Host ""
    Write-Host ("=" * 70)
    Write-Host $title
    Write-Host ("=" * 70)
}

function Write-Result {
    param(
        [string]$test,
        [bool]$success,
        [string]$details = ""
    )
    
    $status = if ($success) { "PASSED" } else { "FAILED" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "$test : " -NoNewline
    Write-Host $status -ForegroundColor $color
    
    if ($details) {
        Write-Host "  $details"
    }
}

# Test user registration
function Register-TestUser {
    param(
        [string]$username,
        [string]$email,
        [string]$password,
        [string]$role
    )
    
    try {
        $body = @{
            username = $username
            email = $email
            password = $password
            role = $role
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/users/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        return @{
            Success = $true
            Response = $response
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Response = $null
        }
    }
}

# Test user login
function Test-UserLogin {
    param(
        [string]$username,
        [string]$password
    )
    
    try {
        $body = @{
            username = $username
            password = $password
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$baseUrl/users/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        return @{
            Success = $true
            Response = $response
            Token = $response.token
            Role = $response.role
            Permissions = $response.permissions
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Response = $null
        }
    }
}

# Test endpoint access
function Test-EndpointAccess {
    param(
        [string]$endpoint,
        [string]$token,
        [bool]$expectedToSucceed
    )
    
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$baseUrl$endpoint" -Method Get -Headers $headers -ErrorAction Stop
        $success = $true
        $details = if ($expectedToSucceed) { "Access granted as expected" } else { "Access granted but should have been denied!" }
    }
    catch {
        $success = $false
        $details = $_.Exception.Message
    }
    
    # Determine if the test passed based on expected result
    $testPassed = ($success -eq $expectedToSucceed)
    $resultDetails = if ($testPassed) {
        if ($success) { "Access granted (expected)" } else { "Access denied (expected)" }
    } else {
        if ($success) { "Access granted (UNEXPECTED!)" } else { "Access denied (UNEXPECTED!)" }
    }
    
    return @{
        Success = $testPassed
        Details = $resultDetails
        Response = $success
    }
}

# Start testing
Write-Header "Role-Based Authentication Test"

# Define roles to test
$rolesToTest = @(
    @{
        Role = "EMPLOYEE"
        Username = "emp_$uniqueSuffix"
        Email = "emp_$uniqueSuffix@example.com"
        Password = "Password123!" 
        ExpectedPermissions = @("canTrackProcesses", "canViewOwnStats")
        DeniedPermissions = @("canViewAllUsers", "canViewAllActivities", "canManageUsers", "canManageAdmins")
    },
    @{
        Role = "ADMIN"
        Username = "adm_$uniqueSuffix"
        Email = "adm_$uniqueSuffix@example.com"
        Password = "Password123!"
        ExpectedPermissions = @("canTrackProcesses", "canViewOwnStats", "canViewAllUsers", "canViewAllActivities", "canManageUsers")
        DeniedPermissions = @("canManageAdmins", "canAccessSystemSettings")
    },
    @{
        Role = "SUPERADMIN"
        Username = "sadm_$uniqueSuffix" 
        Email = "sadm_$uniqueSuffix@example.com"
        Password = "Password123!"
        ExpectedPermissions = @("canTrackProcesses", "canViewOwnStats", "canViewAllUsers", "canViewAllActivities", "canManageUsers", "canManageAdmins", "canAccessSystemSettings")
        DeniedPermissions = @()
    }
)

# Test all roles
foreach ($roleTest in $rolesToTest) {
    $roleName = $roleTest.Role
    Write-Header "Testing $roleName Role"
    
    # 1. Register user
    Write-Host "Registering test user with role '$roleName'..."
    $registrationResult = Register-TestUser -username $roleTest.Username -email $roleTest.Email -password $roleTest.Password -role $roleName
    Write-Result -test "User Registration" -success $registrationResult.Success -details $(if (!$registrationResult.Success) { $registrationResult.Error })
    
    if (!$registrationResult.Success) {
        Write-Host "Skipping further tests for $roleName role due to registration failure" -ForegroundColor Yellow
        continue
    }
    
    # 2. Login
    Write-Host "Logging in as '$($roleTest.Username)'..."
    $loginResult = Test-UserLogin -username $roleTest.Username -password $roleTest.Password
    Write-Result -test "User Login" -success $loginResult.Success -details $(if (!$loginResult.Success) { $loginResult.Error })
    
    if (!$loginResult.Success) {
        Write-Host "Skipping further tests for $roleName role due to login failure" -ForegroundColor Yellow
        continue
    }
    
    # Display login results
    Write-Host ""
    Write-Host "Login Response:" -ForegroundColor Cyan
    Write-Host "  Role: $($loginResult.Role)"
    Write-Host "  User ID: $($loginResult.Response.userId)"
    Write-Host "  Username: $($loginResult.Response.username)"
    
    # Check permissions
    Write-Host ""
    Write-Host "Permissions:" -ForegroundColor Cyan
    
    if ($loginResult.Permissions) {
        $allPermissionsValid = $true
        
        # Check that expected permissions are present and true
        foreach ($permission in $roleTest.ExpectedPermissions) {
            $hasPermission = $loginResult.Permissions.$permission -eq $true
            Write-Host "  $permission : " -NoNewline
            
            if ($hasPermission) {
                Write-Host "✓ Granted" -ForegroundColor Green
            } else {
                Write-Host "✗ Missing (Expected)" -ForegroundColor Red
                $allPermissionsValid = $false
            }
        }
        
        # Check that denied permissions are either not present or false
        foreach ($permission in $roleTest.DeniedPermissions) {
            $hasPermission = $loginResult.Permissions.$permission -eq $true
            Write-Host "  $permission : " -NoNewline
            
            if (!$hasPermission) {
                Write-Host "✓ Denied" -ForegroundColor Green
            } else {
                Write-Host "✗ Granted (Unexpected)" -ForegroundColor Red
                $allPermissionsValid = $false
            }
        }
        
        Write-Result -test "Permission Verification" -success $allPermissionsValid
    } else {
        Write-Host "  No permissions object found in response!" -ForegroundColor Red
        Write-Result -test "Permission Verification" -success $false
    }
    
    # 3. Test endpoint access
    Write-Host ""
    Write-Host "Testing API Access:" -ForegroundColor Cyan
    
    # Common endpoint - all roles should have access
    $profileResult = Test-EndpointAccess -endpoint "/users/profile" -token $loginResult.Token -expectedToSucceed $true
    Write-Result -test "Access to /users/profile" -success $profileResult.Success -details $profileResult.Details
    
    # Admin endpoint - only ADMIN and SUPERADMIN should have access
    $shouldAccessAdmin = @("ADMIN", "SUPERADMIN") -contains $roleName
    $adminResult = Test-EndpointAccess -endpoint "/users/all" -token $loginResult.Token -expectedToSucceed $shouldAccessAdmin
    Write-Result -test "Access to /users/all" -success $adminResult.Success -details $adminResult.Details
}

# Test invalid role registration
Write-Header "Testing Invalid Role Registration"
$invalidRegistrationResult = Register-TestUser -username "invalid_$uniqueSuffix" -email "invalid_$uniqueSuffix@example.com" -password "Password123!" -role "INVALID_ROLE"

# This should fail, so success means the test passed
$invalidRoleTestPassed = !$invalidRegistrationResult.Success
Write-Result -test "Invalid Role Registration" -success $invalidRoleTestPassed -details $(if ($invalidRegistrationResult.Success) { "Registration succeeded but should have failed" } else { "Registration failed as expected" })

# Test invalid login
Write-Header "Testing Invalid Login"
$invalidLoginResult = Test-UserLogin -username "nonexistent_$uniqueSuffix" -password "wrongpassword"

# This should fail, so success means the test passed
$invalidLoginTestPassed = !$invalidLoginResult.Success
Write-Result -test "Invalid Login" -success $invalidLoginTestPassed -details $(if ($invalidLoginResult.Success) { "Login succeeded but should have failed" } else { "Login failed as expected" })

Write-Header "Test Summary"
Write-Host "Role-based authentication testing completed!"
