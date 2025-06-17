# Test script for role-based authentication
# This script tests various endpoints with different user roles

$baseUrl = "http://localhost:8081/api"

# Function to log with timestamp
function Log-Message {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Function to make HTTP requests
function Invoke-ApiRequest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null,
        [string]$Token = ""
    )

    $fullUrl = "$baseUrl$Endpoint"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($Token -ne "") {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    try {
        $bodyJson = if ($Body) { $Body | ConvertTo-Json -Depth 10 } else { $null }
        
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $fullUrl -Method $Method -Headers $headers -UseBasicParsing -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $fullUrl -Method $Method -Headers $headers -Body $bodyJson -UseBasicParsing -ErrorAction Stop
        }
        return @{
            Success = $true
            Data = $response
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        $response = if ($_.Exception.Response) {
            try {
                $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                $reader.ReadToEnd()
            } catch {
                "Could not read response body: $_"
            }
        } else { "No response body" }
        
        Log-Message -Level "ERROR" -Message "HTTP $statusCode Error on $Method $Endpoint : $errorMessage"
        Log-Message -Level "ERROR" -Message "Response: $response"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Error = $errorMessage
            Response = $response
        }
    }
}

# Test role-based authentication
function Test-RoleBasedAuth {
    Log-Message "Starting role-based authentication tests..."
    
    # Step 1: Create test users with different roles
    Log-Message "Creating test users with different roles..."
    
    # Create employee user
    $employeeRegistration = @{
        username = "testemployee"
        email = "testemployee@example.com"
        password = "password123"
        role = "EMPLOYEE"
    }
    
    $employeeResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $employeeRegistration
    
    if (-not $employeeResult.Success) {
        Log-Message -Level "WARN" -Message "Employee user might already exist, proceeding with login"
    } else {
        Log-Message "Employee user created successfully"
    }
    
    # Create admin user
    $adminRegistration = @{
        username = "testadmin"
        email = "testadmin@example.com"
        password = "password123"
        role = "ADMIN"
    }
    
    $adminResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $adminRegistration
    
    if (-not $adminResult.Success) {
        Log-Message -Level "WARN" -Message "Admin user might already exist, proceeding with login"
    } else {
        Log-Message "Admin user created successfully"
    }
    
    # Create superadmin user
    $superadminRegistration = @{
        username = "testsuperadmin"
        email = "testsuperadmin@example.com"
        password = "password123"
        role = "SUPERADMIN"
    }
    
    $superadminResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $superadminRegistration
    
    if (-not $superadminResult.Success) {
        Log-Message -Level "WARN" -Message "Superadmin user might already exist, proceeding with login"
    } else {
        Log-Message "Superadmin user created successfully"
    }
    
    # Step 2: Login with each user and store tokens
    Log-Message "Logging in with different user roles..."
    
    # Employee login
    $employeeLogin = @{
        username = "testemployee"
        password = "password123"
    }
    
    $employeeLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $employeeLogin
    
    if ($employeeLoginResult.Success) {
        $employeeToken = $employeeLoginResult.Data.token
        $employeeRole = $employeeLoginResult.Data.role
        $employeePermissions = ($employeeLoginResult.Data.permissions | ConvertTo-Json -Depth 5)
        
        Log-Message "Employee login successful. Role: $employeeRole"
        Log-Message "Employee Permissions: $employeePermissions"
    } else {
        Log-Message -Level "ERROR" -Message "Employee login failed, skipping employee tests"
        $employeeToken = $null
    }
    
    # Admin login
    $adminLogin = @{
        username = "testadmin"
        password = "password123"
    }
    
    $adminLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $adminLogin
    
    if ($adminLoginResult.Success) {
        $adminToken = $adminLoginResult.Data.token
        $adminRole = $adminLoginResult.Data.role
        $adminPermissions = ($adminLoginResult.Data.permissions | ConvertTo-Json -Depth 5)
        
        Log-Message "Admin login successful. Role: $adminRole"
        Log-Message "Admin Permissions: $adminPermissions"
    } else {
        Log-Message -Level "ERROR" -Message "Admin login failed, skipping admin tests"
        $adminToken = $null
    }
    
    # Superadmin login
    $superadminLogin = @{
        username = "testsuperadmin"
        password = "password123"
    }
    
    $superadminLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $superadminLogin
    
    if ($superadminLoginResult.Success) {
        $superadminToken = $superadminLoginResult.Data.token
        $superadminRole = $superadminLoginResult.Data.role
        $superadminPermissions = ($superadminLoginResult.Data.permissions | ConvertTo-Json -Depth 5)
        
        Log-Message "Superadmin login successful. Role: $superadminRole"
        Log-Message "Superadmin Permissions: $superadminPermissions"
    } else {
        Log-Message -Level "ERROR" -Message "Superadmin login failed, skipping superadmin tests"
        $superadminToken = $null
    }
    
    # Step 3: Test endpoints with different roles
    Log-Message "Testing endpoints with different user roles..."
    
    # Test endpoints that should be accessible to all authenticated users
    $endpoints = @(
        "/users/profile",
        "/process-tracking/status"
    )
    
    foreach ($endpoint in $endpoints) {
        Log-Message "Testing endpoint accessible to all roles: $endpoint"
        
        if ($employeeToken) {
            $employeeResult = Invoke-ApiRequest -Endpoint $endpoint -Token $employeeToken
            $employeeStatus = if ($employeeResult.Success) { "Success" } else { "Failure" }
            Log-Message "Employee access: $employeeStatus"
        }
        
        if ($adminToken) {
            $adminResult = Invoke-ApiRequest -Endpoint $endpoint -Token $adminToken
            $adminStatus = if ($adminResult.Success) { "Success" } else { "Failure" }
            Log-Message "Admin access: $adminStatus"
        }
        
        if ($superadminToken) {
            $superadminResult = Invoke-ApiRequest -Endpoint $endpoint -Token $superadminToken
            $superadminStatus = if ($superadminResult.Success) { "Success" } else { "Failure" }
            Log-Message "Superadmin access: $superadminStatus"
        }
    }
    
    # Test admin-only endpoints
    $adminEndpoints = @(
        "/users/all",
        "/activities/all"
    )
    
    foreach ($endpoint in $adminEndpoints) {
        Log-Message "Testing admin-only endpoint: $endpoint"
        
        if ($employeeToken) {
            $employeeResult = Invoke-ApiRequest -Endpoint $endpoint -Token $employeeToken
            $employeeStatus = if ($employeeResult.Success) { "Success (Unexpected!)" } else { "Failure (Expected)" }
            Log-Message "Employee access: $employeeStatus"
        }
        
        if ($adminToken) {
            $adminResult = Invoke-ApiRequest -Endpoint $endpoint -Token $adminToken
            $adminStatus = if ($adminResult.Success) { "Success (Expected)" } else { "Failure (Unexpected!)" }
            Log-Message "Admin access: $adminStatus"
        }
        
        if ($superadminToken) {
            $superadminResult = Invoke-ApiRequest -Endpoint $endpoint -Token $superadminToken
            $superadminStatus = if ($superadminResult.Success) { "Success (Expected)" } else { "Failure (Unexpected!)" }
            Log-Message "Superadmin access: $superadminStatus"
        }
    }
    
    Log-Message "Role-based authentication tests completed."
}

# Run the tests
Test-RoleBasedAuth
