# Configuration
$baseUrl = "http://localhost:8080"
$token = ""
$userId = 0

# Helper function for making HTTP requests with error handling
function Invoke-ApiRequest {
    param (
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [hashtable]$Headers = @{}
    )
    
    try {
        $fullUrl = "$baseUrl$Endpoint"
        $params = @{
            Method = $Method
            Uri = $fullUrl
            ContentType = "application/json"
            Headers = $Headers
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json)
        }
        
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        Write-Host "Error calling $fullUrl : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        return $null
    }
}

# 1. User Management Tests
Write-Host "`n=== Testing User Management Endpoints ===`n" -ForegroundColor Green

# Register new user with ADMIN role
$user = @{
    username = "testuser_$(Get-Random)"
    password = "password123"
    email = "test_$(Get-Random)@example.com"
    role = "ADMIN"  # Changed to ADMIN role
}
Write-Host "Registering new user..."
$registeredUser = Invoke-ApiRequest -Method "POST" -Endpoint "/api/users/register" -Body $user
$userId = $registeredUser.id

# Login and get token
Write-Host "Testing login..."
$loginResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/api/users/login" -Body @{
    username = $user.username
    password = $user.password
}

# After successful login
if ($loginResponse -and $loginResponse.token) {
    $token = $loginResponse.token
    $secureHeaders = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    Write-Host "Successfully obtained JWT token: $token" -ForegroundColor Green
    Write-Host "User ID: $($loginResponse.userId)" -ForegroundColor Green
    Write-Host "Role: $($loginResponse.role)" -ForegroundColor Green
} else {
    Write-Host "Failed to obtain JWT token. Exiting..." -ForegroundColor Red
    exit
}

# Update the headers for all subsequent requests
$headers = $secureHeaders

# Set proper date parameters
$startDate = [DateTime]::Now.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ss")
$endDate = [DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss")

# Test protected endpoints
Write-Host "`nTesting protected endpoints..." -ForegroundColor Yellow
$endpoints = @(
    @{Method="GET"; Url="/api/users/profile"; Name="User Profile"},
    @{Method="GET"; Url="/api/activities/today?userId=$userId"; Name="Today's Activities"},
    @{Method="GET"; Url="/api/analytics/productivity?userId=$userId&startDate=$startDate&endDate=$endDate"; Name="Productivity Analytics"}
)

foreach ($endpoint in $endpoints) {
    Write-Host "`nTesting $($endpoint.Name)..."
    $response = Invoke-ApiRequest -Method $endpoint.Method -Endpoint $endpoint.Url -Headers $secureHeaders
    if ($response) {
        Write-Host "Success!" -ForegroundColor Green
        Write-Host ($response | ConvertTo-Json)
    }
}

# 2. Activity Tracking Tests
Write-Host "`n=== Testing Activity Tracking Endpoints ===`n" -ForegroundColor Green

# Log activity
$activity = @{
    userId = $userId
    activityType = "APPLICATION_USAGE"
    description = "Testing VS Code"
    applicationName = "VS Code"
    workspaceType = "PRODUCTIVE"
    durationSeconds = 3600
}
Write-Host "Logging activity..."
Invoke-ApiRequest -Method "POST" -Endpoint "/api/activities/log" -Body $activity -Headers $secureHeaders

# Get today's activities
Write-Host "Getting today's activities..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/activities/today?userId=$userId" -Headers $secureHeaders

# Get activity summary
$startDate = [DateTime]::Now.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ss")
$endDate = [DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss")
Write-Host "Getting activity summary..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/activities/summary?userId=$userId&startDate=$startDate&endDate=$endDate" -Headers $secureHeaders

# 3. Analytics Tests
Write-Host "`n=== Testing Analytics Endpoints ===`n" -ForegroundColor Green

# Get productivity analytics
Write-Host "Getting productivity analytics..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/analytics/productivity?userId=$userId&startDate=$startDate&endDate=$endDate" -Headers $secureHeaders

# Get application usage analytics
Write-Host "Getting application usage analytics..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/analytics/app-usage?userId=$userId&startDate=$startDate&endDate=$endDate" -Headers $secureHeaders

# Get workspace analytics
Write-Host "Getting workspace analytics..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/analytics/workspace-comparison?userId=$userId&startDate=$startDate&endDate=$endDate" -Headers $secureHeaders

# Admin-only endpoints (if admin token available)
Write-Host "`n=== Testing Admin Endpoints ===`n" -ForegroundColor Yellow

# List all users
Write-Host "Listing all users..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/users/list" -Headers $secureHeaders

# Get tamper report
Write-Host "Getting tamper report..."
Invoke-ApiRequest -Method "GET" -Endpoint "/api/security/tamper-report?userId=$userId&startDate=$startDate&endDate=$endDate" -Headers $secureHeaders

Write-Host "`nTest completed!" -ForegroundColor Green
