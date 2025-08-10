# Configuration
$baseUrl = "http://localhost:8081"
$userId = 20
$collectionInterval = 30  # 30 seconds interval
$batchSize = 3  # Small batch size for more frequent updates

# Function to get authentication token
function Get-AuthToken {
    $loginBody = @{
        username = "testuser_211178658"
        password = "password123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/users/login" `
        -Body $loginBody -ContentType "application/json"
    return $loginResponse.token
}

# Function to get active window information
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    }
"@

function Get-ActiveWindowTitle {
    $buf = New-Object System.Text.StringBuilder(256)
    $handle = [Win32]::GetForegroundWindow()
    [Win32]::GetWindowText($handle, $buf, 256)
    return $buf.ToString()
}

# Function to collect activity data
function Get-ActivityData {
    param ($userId)
    
    $currentTime = Get-Date
    $activeWindow = Get-ActiveWindowTitle
    $activeProcess = Get-Process | Where-Object { $_.MainWindowTitle -eq $activeWindow } | Select-Object -First 1
    
    if ($activeProcess) {
        @{
            userId = $userId
            activityType = "USER_ACTIVITY"
            description = "User interaction with: $($activeProcess.ProcessName)"
            processName = $activeProcess.ProcessName
            windowTitle = $activeWindow
            applicationName = $activeProcess.ProcessName
            workspaceType = "ACTIVE"
            applicationCategory = Get-ApplicationCategory $activeProcess.ProcessName
            processId = $activeProcess.Id
            startTime = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss")
            endTime = $currentTime.AddSeconds(30).ToString("yyyy-MM-ddTHH:mm:ss")
            durationSeconds = 30
            status = "ACTIVE"
        }
    }
}

# Function to categorize applications
function Get-ApplicationCategory {
    param ($processName)
    
    $processName = $processName.ToLower()
    
    $categories = @{
        development = @("code", "visual studio", "intellij", "pycharm", "eclipse", "sublime", "notepad++")
        browser = @("chrome", "firefox", "edge", "opera", "iexplore")
        productivity = @("excel", "word", "powerpoint", "outlook", "onenote", "acrobat")
        communication = @("teams", "slack", "zoom", "discord", "skype")
        entertainment = @("spotify", "netflix", "vlc", "steam", "game")
    }
    
    foreach ($category in $categories.Keys) {
        if ($categories[$category] | Where-Object { $processName -match $_ }) {
            return $category.ToUpper()
        }
    }
    
    return "OTHER"
}

# Function to log activity details
function Write-ActivityLog {
    param (
        [Parameter(Mandatory=$true)]
        [object]$ActivityData
    )
    
    Write-Host "`n=== Activity Log ===" -ForegroundColor Cyan
    Write-Host "Application: $($ActivityData.applicationName)" -ForegroundColor Yellow
    Write-Host "Window: $($ActivityData.windowTitle)" -ForegroundColor Yellow
    Write-Host "Category: $($ActivityData.applicationCategory)" -ForegroundColor Green
    Write-Host "Status: $($ActivityData.status)" -ForegroundColor Green
    Write-Host "Duration: $($ActivityData.durationSeconds) seconds" -ForegroundColor Gray
    Write-Host "===================" -ForegroundColor Cyan
}

# Main logging loop
try {
    $token = Get-AuthToken
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "Starting activity logging..." -ForegroundColor Green
    Write-Host "Logging interval: $collectionInterval seconds" -ForegroundColor Yellow
    
    $batchNumber = 1
    $activityLogs = @()
    
    while ($true) {
        $activityData = Get-ActivityData -userId $userId
        
        if ($activityData) {
            Write-ActivityLog -ActivityData $activityData
            $activityLogs += $activityData
            
            if ($activityLogs.Count -ge $batchSize) {
                try {
                    Write-Host "`nSending activity batch #$batchNumber..." -ForegroundColor Yellow
                    $response = Invoke-RestMethod -Method Post `
                        -Uri "$baseUrl/api/activities/log" `
                        -Headers $headers `
                        -Body ($activityLogs | ConvertTo-Json) `
                        -ContentType "application/json"
                    
                    Write-Host "Successfully sent batch #$batchNumber" -ForegroundColor Green
                    $activityLogs = @()
                    $batchNumber++
                }
                catch {
                    Write-Host "Error sending batch #$batchNumber" -ForegroundColor Red
                    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        Start-Sleep -Seconds $collectionInterval
    }
}
catch {
    Write-Host "Error in activity logging: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host "Activity logging ended" -ForegroundColor Yellow
}
