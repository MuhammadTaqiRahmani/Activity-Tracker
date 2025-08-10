# Configuration
$baseUrl = "http://localhost:8081"  # Updated to match application.properties port
$userId = 20  # Replace with actual user ID
$collectionInterval = 60  # Changed from 300 to 60 seconds (1 minute)
$maxBatchSize = 3  # Reduced batch size
$maxRetries = 3    # Number of retries for failed requests

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

# New function to split array into chunks
function Split-Array {
    param([array]$array, [int]$chunkSize)
    
    for ($i = 0; $i -lt $array.Count; $i += $chunkSize) {
        $end = [Math]::Min($i + $chunkSize - 1, $array.Count - 1)
        , ($array[$i..$end])
    }
}

# New function to send batch with retry logic
function Send-ProcessBatch {
    param (
        [array]$batch,
        [hashtable]$headers,
        [int]$retryCount = 0
    )
    
    try {
        # Ensure batch is wrapped in array brackets
        $jsonBody = if ($batch.Count -eq 1) {
            "[$($batch | ConvertTo-Json)]"
        } else {
            $batch | ConvertTo-Json -Depth 10
        }
        
        Write-Host "Sending JSON payload:" -ForegroundColor Gray
        Write-Host $jsonBody -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Method Post `
            -Uri "$baseUrl/api/logs/batch" `
            -Headers $headers `
            -Body $jsonBody `
            -ContentType "application/json"
        
        Write-Host "Successfully sent batch with $($batch.Count) logs" -ForegroundColor Green
        return $true
    }
    catch {
        if ($retryCount -lt $maxRetries) {
            Write-Host "Retry attempt $($retryCount + 1) for batch..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return Send-ProcessBatch -batch $batch -headers $headers -retryCount ($retryCount + 1)
        }
        else {
            Write-Host "Failed to send batch after $maxRetries attempts" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Response: $($_.Exception.Response.StatusCode) $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
            return $false
        }
    }
}

# Main collection loop
try {
    $token = Get-AuthToken
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "Starting process collection..." -ForegroundColor Green
    
    while ($true) {
        $processData = Get-ProcessData -userId $userId
        
        # Split processes into smaller batches
        $batches = Split-Array -array $processData -chunkSize $maxBatchSize
        
        Write-Host "`nCollected $($processData.Count) processes, split into $($batches.Count) batches" -ForegroundColor Cyan
        
        $batchNumber = 1
        foreach ($batch in $batches) {
            Write-Host "`nProcessing batch $batchNumber of $($batches.Count)" -ForegroundColor Yellow
            
            foreach ($process in $batch) {
                Write-ProcessLog -ProcessData $process
            }
            
            $success = Send-ProcessBatch -batch $batch -headers $headers
            if (-not $success) {
                Write-Host "Skipping remaining items in current batch..." -ForegroundColor Yellow
                continue
            }
            
            $batchNumber++
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
