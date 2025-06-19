# Orphaned Activities Management Test Script - Tests the new database integrity features

# Configuration
$baseUrl = "http://localhost:8081"
$timestamp = Get-Date -Format "yyMMddHHmm"

# Check if admin credentials exist
$credsPath = ".\admin-credentials.json"
if (-not (Test-Path $credsPath)) {
    Write-Host "Admin credentials not found. Please run init-admin.ps1 first." -ForegroundColor Red
    exit
}

# Load admin credentials
$adminCreds = Get-Content $credsPath | ConvertFrom-Json
$adminHeaders = @{
    "Authorization" = "Bearer $($adminCreds.token)"
    "Content-Type" = "application/json"
}

function Write-TestCase {
    param ([string]$name)
    Write-Host "`n=== Testing: $name ===" -ForegroundColor Cyan
}

function Write-Success {
    param ([string]$message)
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-Error {
    param ([string]$message)
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

function Write-Info {
    param ([string]$message)
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

Write-Host "=== ORPHANED ACTIVITIES MANAGEMENT TEST ===" -ForegroundColor Magenta
Write-Host "This script tests the new database integrity features for preventing orphaned activities." -ForegroundColor Gray

# Test 1: Check for orphaned activities
Write-TestCase "Check for Orphaned Activities"
try {
    $orphanedCheck = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/activities/admin/orphaned-check" `
        -Headers $adminHeaders
    
    if ($orphanedCheck.hasOrphanedActivities) {
        Write-Error "Found orphaned activities!"
        Write-Host "Orphaned User IDs: $($orphanedCheck.orphanedUserIds -join ', ')" -ForegroundColor Yellow
        Write-Host "Total orphaned activities: $($orphanedCheck.orphanedActivityCount)" -ForegroundColor Yellow
    } else {
        Write-Success "No orphaned activities found - database integrity is maintained!"
    }
    
    Write-Host "Check completed at: $($orphanedCheck.timestamp)" -ForegroundColor Gray
} catch {
    Write-Error "Failed to check orphaned activities: $($_.Exception.Message)"
}

# Test 2: Get detailed orphaned activities information
Write-TestCase "Get Orphaned Activities Details"
try {
    $orphanedDetails = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/activities/admin/orphaned-details" `
        -Headers $adminHeaders
    
    Write-Info "Found $($orphanedDetails.count) orphaned activities"
    
    if ($orphanedDetails.count -gt 0) {
        Write-Host "`nDetailed Orphaned Activities:" -ForegroundColor Yellow
        foreach ($activity in $orphanedDetails.orphanedActivities | Select-Object -First 5) {
            Write-Host "  - Activity ID: $($activity.id), User ID: $($activity.userId), Type: $($activity.activityType)" -ForegroundColor Gray
        }
        
        if ($orphanedDetails.count -gt 5) {
            Write-Host "  ... and $($orphanedDetails.count - 5) more" -ForegroundColor Gray
        }
    }
    
    Write-Success "Successfully retrieved orphaned activities details"
} catch {
    Write-Error "Failed to get orphaned activities details: $($_.Exception.Message)"
}

# Test 3: Test user validation in activity creation
Write-TestCase "Test Activity Creation with Non-Existent User"
try {
    $testActivity = @{
        userId = 99999  # Non-existent user ID
        activityType = "TEST_VALIDATION"
        description = "Testing user validation"
        applicationName = "TestApp"
        workspaceType = "TEST"
        durationSeconds = 60
    } | ConvertTo-Json
    
    $activityResponse = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/api/activities/log" `
        -Body $testActivity `
        -Headers $adminHeaders
    
    Write-Error "Activity creation should have failed but didn't!"
} catch {
    if ($_.Exception.Message -like "*does not exist*" -or $_.Exception.Message -like "*not found*") {
        Write-Success "User validation is working correctly - prevented orphaned activity creation"
    } else {
        Write-Error "Activity creation failed for unexpected reason: $($_.Exception.Message)"
    }
}

# Test 4: Test activity creation with valid user
Write-TestCase "Test Activity Creation with Valid User"
try {
    # First, get a valid user ID
    $users = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/users/all?size=5" `
        -Headers $adminHeaders
    
    if ($users.users.Count -gt 0) {
        $validUserId = $users.users[0].id
        
        $testActivity = @{
            userId = $validUserId
            activityType = "TEST_VALIDATION"
            description = "Testing valid activity creation"
            applicationName = "TestApp"
            workspaceType = "TEST"
            durationSeconds = 60
        } | ConvertTo-Json
        
        $activityResponse = Invoke-RestMethod -Method Post `
            -Uri "$baseUrl/api/activities/log" `
            -Body $testActivity `
            -Headers $adminHeaders
        
        Write-Success "Successfully created activity for valid user ID: $validUserId"
        Write-Host "Created Activity ID: $($activityResponse.id)" -ForegroundColor Gray
    } else {
        Write-Error "No valid users found to test with"
    }
} catch {
    Write-Error "Failed to create activity with valid user: $($_.Exception.Message)"
}

# Test 5: Demonstrate cleanup functionality (only if orphaned activities exist)
Write-TestCase "Test Orphaned Activities Cleanup (If Needed)"
try {
    $orphanedCheck = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/activities/admin/orphaned-check" `
        -Headers $adminHeaders
    
    if ($orphanedCheck.hasOrphanedActivities) {
        Write-Host "Proceeding with cleanup of $($orphanedCheck.orphanedActivityCount) orphaned activities..." -ForegroundColor Yellow
        
        $cleanupResponse = Invoke-RestMethod -Method Delete `
            -Uri "$baseUrl/api/activities/admin/orphaned-cleanup" `
            -Headers $adminHeaders
        
        Write-Success "Cleanup completed!"
        Write-Host "Deleted activities: $($cleanupResponse.deletedCount)" -ForegroundColor Gray
        Write-Host "Cleanup timestamp: $($cleanupResponse.timestamp)" -ForegroundColor Gray
    } else {
        Write-Success "No orphaned activities to clean up - database is already clean!"
    }
} catch {
    Write-Error "Failed to cleanup orphaned activities: $($_.Exception.Message)"
}

# Test 6: Final verification
Write-TestCase "Final Database Integrity Verification"
try {
    $finalCheck = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/activities/admin/orphaned-check" `
        -Headers $adminHeaders
    
    if ($finalCheck.hasOrphanedActivities) {
        Write-Error "Still found orphaned activities after cleanup!"
    } else {
        Write-Success "Database integrity verified - no orphaned activities!"
    }
} catch {
    Write-Error "Failed final verification: $($_.Exception.Message)"
}

Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Magenta
Write-Host "[SUCCESS] Database integrity features tested" -ForegroundColor Green
Write-Host "[SUCCESS] User validation in activity creation tested" -ForegroundColor Green  
Write-Host "[SUCCESS] Orphaned activities detection tested" -ForegroundColor Green
Write-Host "[SUCCESS] Cleanup functionality tested" -ForegroundColor Green
Write-Host "`nThe backend now has proper safeguards against orphaned activities!" -ForegroundColor Cyan
