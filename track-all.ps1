# Configuration
$baseUrl = "http://localhost:8081"
$userId = 20
$processInterval = 60  # Process collection every 1 minute
$activityInterval = 30  # Activity collection every 30 seconds
$batchSize = 5

# Import the active window detection code
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

# Authentication function
function Get-AuthToken {
    $loginBody = @{
        username = "testuser_211178658"
        password = "password123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/users/login" -Body $loginBody -ContentType "application/json"
    return $loginResponse.token
}

# Function to get active window title
function Get-ActiveWindowTitle {
    $buf = New-Object System.Text.StringBuilder(256)
    $handle = [Win32]::GetForegroundWindow()
    [Win32]::GetWindowText($handle, $buf, 256)
    return $buf.ToString()
}

# Function to categorize applications
function Get-ApplicationCategory {
    param ($processName)
    $processName = $processName.ToLower()
    $categories = @{
        development = @("code", "studio", "intellij", "pycharm", "eclipse", "sublime")
        browser = @("chrome", "firefox", "edge", "opera")
        productivity = @("excel", "word", "powerpoint", "outlook", "onenote")
        communication = @("teams", "slack", "zoom", "discord", "skype")
        entertainment = @("spotify", "netflix", "vlc", "steam")
    }
    
    foreach ($category in $categories.Keys) {
        if ($categories[$category] | Where-Object { $processName -match $_ }) {
            return $category.ToUpper()
        }
    }
    return "OTHER"
}

# Start tracking
try {
    $token = Get-AuthToken
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    Write-Host "Starting combined tracking..." -ForegroundColor Green
    Write-Host "Process interval: $processInterval seconds" -ForegroundColor Yellow
    Write-Host "Activity interval: $activityInterval seconds" -ForegroundColor Yellow

    $lastProcessTime = [DateTime]::MinValue
    $lastActivityTime = [DateTime]::MinValue
    $batchNumber = 1
    $processLogs = @()
    $activityLogs = @()

    while ($true) {
        $currentTime = Get-Date

        # Process tracking
        if (($currentTime - $lastProcessTime).TotalSeconds -ge $processInterval) {
            Write-Host "`n=== Collecting Processes ===" -ForegroundColor Magenta
            $processes = Get-Process | Where-Object { $_.MainWindowTitle -ne "" }
            
            foreach ($proc in $processes) {
                $processData = @{
                    userId = $userId
                    processName = $proc.ProcessName
                    windowTitle = $proc.MainWindowTitle
                    processId = $proc.Id
                    applicationPath = $proc.Path
                    startTime = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss")
                    endTime = $currentTime.AddMinutes(1).ToString("yyyy-MM-ddTHH:mm:ss")
                    durationSeconds = 60
                    category = Get-ApplicationCategory $proc.ProcessName
                    isProductiveApp = $true
                }
                $processLogs += $processData
                
                Write-Host "Process: $($proc.ProcessName)" -ForegroundColor Yellow
            }

            if ($processLogs.Count -ge $batchSize) {
                Write-Host "`nSending process batch..." -ForegroundColor Cyan
                $response = Invoke-RestMethod -Method Post `
                    -Uri "$baseUrl/api/logs/batch" `
                    -Headers $headers `
                    -Body ($processLogs | ConvertTo-Json) `
                    -ContentType "application/json"
                
                Write-Host "Sent process batch #$batchNumber" -ForegroundColor Green
                $processLogs = @()
                $batchNumber++
            }

            $lastProcessTime = $currentTime
        }

        # Activity tracking
        if (($currentTime - $lastActivityTime).TotalSeconds -ge $activityInterval) {
            Write-Host "`n=== Recording Activity ===" -ForegroundColor Blue
            $activeWindow = Get-ActiveWindowTitle
            $activeProcess = Get-Process | Where-Object { $_.MainWindowTitle -eq $activeWindow } | Select-Object -First 1

            if ($activeProcess) {
                $activityData = @{
                    userId = $userId
                    activityType = "USER_ACTIVITY"
                    description = "User interaction with: $($activeProcess.ProcessName)"
                    processName = $activeProcess.ProcessName
                    windowTitle = $activeWindow
                    applicationName = $activeProcess.ProcessName
                    workspaceType = "ACTIVE"
                    applicationCategory = Get-ApplicationCategory $activeProcess.ProcessName
                    processId = $activeProcess.Id.ToString()
                    startTime = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss")
                    endTime = $currentTime.AddSeconds($activityInterval).ToString("yyyy-MM-ddTHH:mm:ss")
                    durationSeconds = $activityInterval
                    status = "ACTIVE"
                }

                Write-Host "Active Window: $activeWindow" -ForegroundColor Yellow
                Write-Host "Application: $($activeProcess.ProcessName)" -ForegroundColor Green
                
                $response = Invoke-RestMethod -Method Post `
                    -Uri "$baseUrl/api/activities/log" `
                    -Headers $headers `
                    -Body ($activityData | ConvertTo-Json) `
                    -ContentType "application/json"
                
                Write-Host "Activity logged successfully" -ForegroundColor Green
            }

            $lastActivityTime = $currentTime
        }

        Start-Sleep -Seconds 1
    }
}
catch {
    Write-Host "`nError in tracking: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
finally {
    Write-Host "`nTracking ended" -ForegroundColor Yellow
}
