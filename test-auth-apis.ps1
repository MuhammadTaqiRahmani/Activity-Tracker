# Test script for role-based authentication - Registration and Login APIs
# This script tests register and login APIs with different roles

$baseUrl = "http://localhost:8081/api"
$testOutputDir = "c:\Users\M. Taqi Rahmani\IdeaProjects\Backend-app\test-results"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create timestamp-based log file
$logFile = Join-Path $testOutputDir "auth_test_$timestamp.log"
$jsonOutputFile = Join-Path $testOutputDir "auth_test_results_$timestamp.json"

# Test results to save
$testResults = @{
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    tests = @()
    summary = @{
        total = 0
        passed = 0
        failed = 0
    }
}

# Function to log with timestamp
function Log-Message {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry
}

# Function to make HTTP requests
function Invoke-ApiRequest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null,
        [string]$Token = "",
        [string]$Description = ""
    )

    $fullUrl = "$baseUrl$Endpoint"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($Token -ne "") {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    $testCase = @{
        description = $Description
        endpoint = $fullUrl
        method = $Method
        requestBody = $Body
        status = "Failed"
        details = ""
    }
    
    $testResults.summary.total++

    try {
        $bodyJson = if ($Body) { $Body | ConvertTo-Json -Depth 10 } else { $null }
        
        Log-Message "Sending $Method request to $fullUrl"
        if ($bodyJson) {
            Log-Message "Request Body: $bodyJson"
        }
        
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $fullUrl -Method $Method -Headers $headers -UseBasicParsing -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $fullUrl -Method $Method -Headers $headers -Body $bodyJson -UseBasicParsing -ErrorAction Stop
        }
        
        $responseJson = $response | ConvertTo-Json -Depth 5
        Log-Message "Response: $responseJson"
        
        $testCase.status = "Passed"
        $testCase.details = "Successful response received"
        $testCase.response = $response
        
        $testResults.summary.passed++
        
        $testResults.tests += $testCase
        
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
          $testCase.status = "Failed"
        $testCase.details = "HTTP Error: $errorMessage. Response: $response"
        
        $testResults.summary.failed++
        
        $testResults.tests += $testCase
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Error = $errorMessage
            Response = $response
        }
    }
}

# Save test results to JSON file
function Save-TestResults {
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonOutputFile
    Log-Message "Test results saved to $jsonOutputFile"
    
    # Print test summary
    Log-Message "Test Summary: Total=$($testResults.summary.total), Passed=$($testResults.summary.passed), Failed=$($testResults.summary.failed)"
}

# Test register and login APIs with different roles
function Test-AuthApis {
    Log-Message "Starting authentication API tests..."
    
    # Generate unique usernames to avoid conflicts
    $uniqueSuffix = Get-Random -Minimum 1000 -Maximum 9999
    
    # Test Case 1: Register & Login as Employee
    Log-Message "Test Case 1: Register and Login as Employee"
    
    $employeeUsername = "employee_$uniqueSuffix"
    $employeeRegistration = @{
        username = $employeeUsername
        email = "$employeeUsername@example.com"
        password = "password123"
        role = "EMPLOYEE"
    }
    
    $employeeRegResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $employeeRegistration -Description "Register as Employee"
    
    if ($employeeRegResult.Success) {
        Log-Message "Employee user registered successfully"
        
        # Now login
        $employeeLogin = @{
            username = $employeeUsername
            password = "password123"
        }
        
        $employeeLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $employeeLogin -Description "Login as Employee"
        
        if ($employeeLoginResult.Success) {
            $employeeToken = $employeeLoginResult.Data.token
            $employeeRole = $employeeLoginResult.Data.role
            $employeePermissions = ($employeeLoginResult.Data.permissions | ConvertTo-Json)
            
            Log-Message "Employee login successful. Role: $employeeRole"
            Log-Message "Employee Token: $employeeToken"
            Log-Message "Employee Permissions: $employeePermissions"
            
            # Test accessing profile with token
            $profileResult = Invoke-ApiRequest -Endpoint "/users/profile" -Token $employeeToken -Description "Employee accessing profile"
            
            if ($profileResult.Success) {
                Log-Message "Employee can access profile endpoint (expected behavior)"
            } else {
                Log-Message -Level "ERROR" "Employee cannot access profile endpoint (unexpected behavior)"
            }
            
            # Test accessing admin-only endpoint
            $adminAccessResult = Invoke-ApiRequest -Endpoint "/users/all" -Token $employeeToken -Description "Employee attempting to access admin endpoint"
            
            if ($adminAccessResult.Success) {
                Log-Message -Level "ERROR" "Employee can access admin-only endpoint (security issue)"
            } else {
                Log-Message "Employee correctly denied access to admin-only endpoint"
            }
        }
    }
    
    # Test Case 2: Register & Login as Admin
    Log-Message "Test Case 2: Register and Login as Admin"
    
    $adminUsername = "admin_$uniqueSuffix"
    $adminRegistration = @{
        username = $adminUsername
        email = "$adminUsername@example.com"
        password = "password123"
        role = "ADMIN"
    }
    
    $adminRegResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $adminRegistration -Description "Register as Admin"
    
    if ($adminRegResult.Success) {
        Log-Message "Admin user registered successfully"
        
        # Now login
        $adminLogin = @{
            username = $adminUsername
            password = "password123"
        }
        
        $adminLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $adminLogin -Description "Login as Admin"
        
        if ($adminLoginResult.Success) {
            $adminToken = $adminLoginResult.Data.token
            $adminRole = $adminLoginResult.Data.role
            $adminPermissions = ($adminLoginResult.Data.permissions | ConvertTo-Json)
            
            Log-Message "Admin login successful. Role: $adminRole"
            Log-Message "Admin Token: $adminToken"
            Log-Message "Admin Permissions: $adminPermissions"
            
            # Test accessing profile with token
            $profileResult = Invoke-ApiRequest -Endpoint "/users/profile" -Token $adminToken -Description "Admin accessing profile"
            
            if ($profileResult.Success) {
                Log-Message "Admin can access profile endpoint (expected behavior)"
            } else {
                Log-Message -Level "ERROR" "Admin cannot access profile endpoint (unexpected behavior)"
            }
            
            # Test accessing admin-only endpoint
            $adminAccessResult = Invoke-ApiRequest -Endpoint "/users/all" -Token $adminToken -Description "Admin accessing admin endpoint"
            
            if ($adminAccessResult.Success) {
                Log-Message "Admin can access admin-only endpoint (expected behavior)"
            } else {
                Log-Message -Level "ERROR" "Admin cannot access admin-only endpoint (unexpected behavior)"
            }
        }
    }
    
    # Test Case 3: Register & Login as SuperAdmin
    Log-Message "Test Case 3: Register and Login as SuperAdmin"
    
    $superadminUsername = "superadmin_$uniqueSuffix"
    $superadminRegistration = @{
        username = $superadminUsername
        email = "$superadminUsername@example.com"
        password = "password123"
        role = "SUPERADMIN"
    }
    
    $superadminRegResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $superadminRegistration -Description "Register as SuperAdmin"
    
    if ($superadminRegResult.Success) {
        Log-Message "SuperAdmin user registered successfully"
        
        # Now login
        $superadminLogin = @{
            username = $superadminUsername
            password = "password123"
        }
        
        $superadminLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $superadminLogin -Description "Login as SuperAdmin"
        
        if ($superadminLoginResult.Success) {
            $superadminToken = $superadminLoginResult.Data.token
            $superadminRole = $superadminLoginResult.Data.role
            $superadminPermissions = ($superadminLoginResult.Data.permissions | ConvertTo-Json)
            
            Log-Message "SuperAdmin login successful. Role: $superadminRole"
            Log-Message "SuperAdmin Token: $superadminToken"
            Log-Message "SuperAdmin Permissions: $superadminPermissions"
            
            # Test accessing profile with token
            $profileResult = Invoke-ApiRequest -Endpoint "/users/profile" -Token $superadminToken -Description "SuperAdmin accessing profile"
            
            if ($profileResult.Success) {
                Log-Message "SuperAdmin can access profile endpoint (expected behavior)"
            } else {
                Log-Message -Level "ERROR" "SuperAdmin cannot access profile endpoint (unexpected behavior)"
            }
            
            # Test accessing admin-only endpoint
            $adminAccessResult = Invoke-ApiRequest -Endpoint "/users/all" -Token $superadminToken -Description "SuperAdmin accessing admin endpoint"
            
            if ($adminAccessResult.Success) {
                Log-Message "SuperAdmin can access admin-only endpoint (expected behavior)"
            } else {
                Log-Message -Level "ERROR" "SuperAdmin cannot access admin-only endpoint (unexpected behavior)"
            }
        }
    }
    
    # Test Case 4: Register with invalid role
    Log-Message "Test Case 4: Register with invalid role"
    
    $invalidRoleUsername = "invalid_role_$uniqueSuffix"
    $invalidRoleRegistration = @{
        username = $invalidRoleUsername
        email = "$invalidRoleUsername@example.com"
        password = "password123"
        role = "INVALID_ROLE"
    }
    
    $invalidRoleResult = Invoke-ApiRequest -Endpoint "/users/register" -Method "POST" -Body $invalidRoleRegistration -Description "Register with invalid role"
    
    if ($invalidRoleResult.Success) {
        Log-Message -Level "ERROR" "Registration with invalid role succeeded (unexpected behavior)"
    } else {
        Log-Message "Registration with invalid role failed (expected behavior)"
    }
    
    # Test Case 5: Login with invalid credentials
    Log-Message "Test Case 5: Login with invalid credentials"
    
    $invalidLogin = @{
        username = "nonexistent_user"
        password = "wrongpassword"
    }
    
    $invalidLoginResult = Invoke-ApiRequest -Endpoint "/users/login" -Method "POST" -Body $invalidLogin -Description "Login with invalid credentials"
    
    if ($invalidLoginResult.Success) {
        Log-Message -Level "ERROR" "Login with invalid credentials succeeded (security issue)"
    } else {
        Log-Message "Login with invalid credentials failed (expected behavior)"
    }
    
    Log-Message "Authentication API tests completed."
}

# Run the tests
Log-Message "Starting API authentication tests at $(Get-Date)"
Test-AuthApis
Save-TestResults
Log-Message "Tests completed at $(Get-Date)"
