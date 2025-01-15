# Configuration
$baseUrl = "http://localhost:8081"  # Updated to match application.properties port
$userId = 13  # Replace with actual user ID
$collectionInterval = 60  # Changed from 300 to 60 seconds (1 minute)
$batchSize = 5  # Changed from 10 to 5 for more frequent sending

# Function to get authentication token
function Get-AuthToken {
    $loginBody = @{
        username = "fifa"
        password = "fifa@gmail.com"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/users/login" `
        -Body $loginBody -ContentType "application/json"
    return $loginResponse.token
}

# Function to collect process data
function Get-ProcessData {
    param ($userId)
    
    $processes = Get-Process | Where-Object {$_.MainWindowTitle -ne ""}
    $currentTime = Get-Date
    
    return $processes | ForEach-Object {
        @{
            # Process tracking fields
            userId = $userId
            processName = $_.ProcessName
            windowTitle = $_.MainWindowTitle
            processId = $_.Id
            applicationPath = $_.Path
            startTime = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss")
            endTime = $currentTime.AddMinutes(1).ToString("yyyy-MM-ddTHH:mm:ss")
            durationSeconds = 60
            category = "SYSTEM"
            isProductiveApp = $true

            # Activity fields
            activityType = "PROCESS_MONITORING"
            description = "Automatic process monitoring: $($_.ProcessName)"
            workspaceType = "LOCAL"
            applicationCategory = "SYSTEM"
        }
    }
}

function Write-ProcessLog {
    param (
        [Parameter(Mandatory=$true)]
        [object]$ProcessData
    )
    
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Process: $($ProcessData.processName)" -ForegroundColor Yellow
    Write-Host "Window Title: $($ProcessData.windowTitle)" -ForegroundColor Yellow
    Write-Host "Process ID: $($ProcessData.processId)" -ForegroundColor Yellow
    Write-Host "Start Time: $($ProcessData.startTime)" -ForegroundColor Green
    Write-Host "Duration: $($ProcessData.durationSeconds) seconds" -ForegroundColor Green
    Write-Host "Application Path: $($ProcessData.applicationPath)" -ForegroundColor Gray
    Write-Host "----------------------------------------" -ForegroundColor Cyan
}

# Main collection loop
try {
    $token = Get-AuthToken
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "Starting high-frequency process collection..." -ForegroundColor Green
    Write-Host "Collecting every $collectionInterval seconds with batch size of $batchSize" -ForegroundColor Yellow
    
    $batchNumber = 1
    while ($true) {
        $processLogs = @()
        
        # Collect process data
        Write-Host "`nBatch #$batchNumber - Collecting process data..." -ForegroundColor Magenta
        $processData = Get-ProcessData -userId $userId
        
        # Print collected data
        Write-Host "`nCollected Processes in this batch:" -ForegroundColor Cyan
        foreach ($process in $processData) {
            Write-ProcessLog -ProcessData $process
            $processLogs += $process
        }
        
        # Send batch when we reach batch size
        if ($processLogs.Count -ge $batchSize) {
            try {
                Write-Host "`nSending batch to server..." -ForegroundColor Yellow
                $response = Invoke-RestMethod -Method Post `
                    -Uri "$baseUrl/api/logs/batch" `
                    -Headers $headers `
                    -Body ($processLogs | ConvertTo-Json) `
                    -ContentType "application/json"
                
                Write-Host "Successfully sent batch #$batchNumber with $($processLogs.Count) logs" -ForegroundColor Green
                Write-Host "Server response: " -NoNewline
                $response | ConvertTo-Json | Write-Host -ForegroundColor Cyan
                
                $processLogs = @()
                $batchNumber++
            }
            catch {
                Write-Host "Error sending batch #$batchNumber" -ForegroundColor Red
                Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "`nWaiting $collectionInterval seconds before next collection..." -ForegroundColor Gray
        Start-Sleep -Seconds $collectionInterval
    }
}
catch {
    Write-Host "Error in collection process" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host "Collection process ended" -ForegroundColor Yellow
}
