#!/usr/bin/env powershell

# Setup
$baseUrl = "http://localhost:8081/api"

# Generate unique suffixes for test users
$random = Get-Random -Minimum 1000 -Maximum 9999

# Define the roles to test
$roles = @(
    @{Name="EMPLOYEE"; ExpectedToAccessAdmin=$false},
    @{Name="ADMIN"; ExpectedToAccessAdmin=$true},
    @{Name="SUPERADMIN"; ExpectedToAccessAdmin=$true}
)

# Function to log messages
function Write-TestLog {
    param([string]$message, [string]$type = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$type] $message"
}

# Test each role
foreach ($role in $roles) {
    $roleName = $role.Name
    $username = "$($roleName.ToLower())_$random"
    $password = "Test123!"
    
    Write-TestLog "Testing role: $roleName" -type "TEST"
    
    # 1. Register user
    Write-TestLog "Registering user with role $roleName"
    try {
        $registrationBody = @{
            username = $username
            email = "$username@example.com"
            password = $password
            role = $roleName
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "$baseUrl/users/register" -Method Post -Body $registrationBody -ContentType "application/json"
        Write-TestLog "User registration successful for $username" -type "SUCCESS"
    } catch {
        Write-TestLog "User registration failed: $($_.Exception.Message)" -type "ERROR"
        if ($_.Exception.Response.StatusCode.value__ -ne 409) {
            # Skip to next role if not a conflict (which means user might already exist)
            continue
        }
        Write-TestLog "User might already exist, proceeding with login" -type "WARNING"
    }
    
    # 2. Login
    Write-TestLog "Logging in as $username"
    $token = $null
    try {
        $loginBody = @{
            username = $username
            password = $password
        } | ConvertTo-Json
        
        $loginResponse = Invoke-RestMethod -Uri "$baseUrl/users/login" -Method Post -Body $loginBody -ContentType "application/json"
        $token = $loginResponse.token
        $returnedRole = $loginResponse.role
        
        # Display login response details
        Write-TestLog "Login successful for $username" -type "SUCCESS"
        Write-TestLog "Received role: $returnedRole" -type "SUCCESS"
        Write-TestLog "Permissions:" -type "INFO"
        if ($loginResponse.permissions) {
            $loginResponse.permissions.PSObject.Properties | ForEach-Object {
                Write-TestLog "  $($_.Name): $($_.Value)" -type "INFO"
            }
        }
    } catch {
        Write-TestLog "Login failed: $($_.Exception.Message)" -type "ERROR"
        continue
    }
    
    # 3. Test profile access (should succeed for all roles)
    if ($token) {
        Write-TestLog "Testing profile access for $roleName"
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
            }
            
            $profile = Invoke-RestMethod -Uri "$baseUrl/users/profile" -Method Get -Headers $headers -ContentType "application/json"
            Write-TestLog "Profile access successful" -type "SUCCESS"
        } catch {
            Write-TestLog "Profile access failed: $($_.Exception.Message)" -type "ERROR"
        }
    }
    
    # 4. Test admin endpoint access
    if ($token) {
        Write-TestLog "Testing admin endpoint access for $roleName"
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
            }
            
            $adminAccess = Invoke-RestMethod -Uri "$baseUrl/users/all" -Method Get -Headers $headers -ContentType "application/json"
            
            if ($role.ExpectedToAccessAdmin) {
                Write-TestLog "Admin endpoint access successful (expected)" -type "SUCCESS"
            } else {
                Write-TestLog "Admin endpoint access successful (UNEXPECTED - security issue!)" -type "ERROR"
            }
        } catch {
            if ($role.ExpectedToAccessAdmin) {
                Write-TestLog "Admin endpoint access failed (UNEXPECTED): $($_.Exception.Message)" -type "ERROR"
            } else {
                Write-TestLog "Admin endpoint access failed (expected security restriction)" -type "SUCCESS"
            }
        }
    }
}

# Test invalid role registration
$invalidRoleName = "INVALID_ROLE"
$invalidUsername = "invalid_$random"

Write-TestLog "Testing invalid role registration: $invalidRoleName" -type "TEST"
try {
    $invalidRegBody = @{
        username = $invalidUsername
        email = "$invalidUsername@example.com"
        password = "Test123!"
        role = $invalidRoleName
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$baseUrl/users/register" -Method Post -Body $invalidRegBody -ContentType "application/json"
    Write-TestLog "Invalid role registration succeeded (UNEXPECTED)" -type "ERROR"
} catch {
    Write-TestLog "Invalid role registration failed (expected): $($_.Exception.Message)" -type "SUCCESS"
}

# Test invalid login
Write-TestLog "Testing invalid login credentials" -type "TEST"
try {
    $invalidLoginBody = @{
        username = "nonexistent_$random"
        password = "wrongpassword"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$baseUrl/users/login" -Method Post -Body $invalidLoginBody -ContentType "application/json"
    Write-TestLog "Invalid login succeeded (UNEXPECTED)" -type "ERROR"
} catch {
    Write-TestLog "Invalid login failed (expected): $($_.Exception.Message)" -type "SUCCESS"
}

Write-TestLog "All tests completed!" -type "TEST"
