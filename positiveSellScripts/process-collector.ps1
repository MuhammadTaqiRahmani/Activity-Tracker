# Configuration
$baseUrl = "http://localhost:8081"  # Updated to match application.properties port
$userId = 20  # Replace with actual user ID
$collectionInterval = 60  # Changed from 300 to 60 seconds (1 minute)
$maxBatchSize = 3  # Reduced batch size
$maxRetries = 3    # Number of retries for failed requests

# Token management variables
$tokenRefreshInterval = 300  # Reduce to 5 minutes
$lastTokenRefresh = $null
$token = $null
$tokenValidated = $false

# Modified Get-AuthToken function
function Get-AuthToken {
    try {
        $loginBody = @{
            username = "Naqi111"
            password = "123niqi123111.com"
        } | ConvertTo-Json

        Write-Host "Attempting authentication..." -ForegroundColor Yellow
        $loginResponse = Invoke-RestMethod -Method Post `
            -Uri "$baseUrl/api/users/login" `
            -Body $loginBody `
            -ContentType "application/json"
        
        if ($loginResponse.token) {
            $script:tokenValidated = $true
            Write-Host "Authentication successful" -ForegroundColor Green
            return $loginResponse.token
        } else {
            throw "No token received in response"
        }
    }
    catch {
        Write-Host "Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        $script:tokenValidated = $false
        throw
    }
}

# Modified token validation function
function Ensure-ValidToken {
    param([bool]$forceRefresh = $false)
    
    $currentTime = Get-Date
    $needsRefresh = $false

    if (-not $script:lastTokenRefresh) {
        $needsRefresh = $true
    } else {
        $timeSinceRefresh = ($currentTime - $script:lastTokenRefresh).TotalSeconds
        $needsRefresh = $timeSinceRefresh -ge $tokenRefreshInterval
    }
    
    if ($forceRefresh -or $needsRefresh -or -not $script:tokenValidated) {
        Write-Host "Token needs refresh. Force: $forceRefresh, Time elapsed: $timeSinceRefresh" -ForegroundColor Yellow
        $script:token = Get-AuthToken
        $script:lastTokenRefresh = $currentTime
        $script:headers = @{
            "Authorization" = "Bearer $($script:token)"
            "Content-Type" = "application/json"
        }
        Write-Host "Token refreshed and headers updated" -ForegroundColor Green
    }
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

# Modified Send-ProcessBatch function
function Send-ProcessBatch {
    param (
        [array]$batch,
        [hashtable]$headers,
        [int]$retryCount = 0
    )
    
    try {
        Ensure-ValidToken

        # Wrap single item in array
        $jsonBody = if ($batch.Count -eq 1) {
            "[$($batch | ConvertTo-Json -Depth 10)]"
        } else {
            $batch | ConvertTo-Json -Depth 10
        }
        
        Write-Host "Sending batch with current token..." -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Method Post `
            -Uri "$baseUrl/api/logs/batch" `
            -Headers $script:headers `
            -Body $jsonBody `
            -ContentType "application/json"
        
        Write-Host "Successfully sent batch with $($batch.Count) logs" -ForegroundColor Green
        return $true
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        
        if ($statusCode -eq 403) {
            if ($retryCount -lt $maxRetries) {
                Write-Host "Token rejected (403), forcing refresh..." -ForegroundColor Yellow
                $script:tokenValidated = $false
                Ensure-ValidToken -forceRefresh $true
                return Send-ProcessBatch -batch $batch -headers $script:headers -retryCount ($retryCount + 1)
            }
        }
        elseif ($retryCount -lt $maxRetries) {
            Write-Host "Retry attempt $($retryCount + 1) for batch..." -ForegroundColor Yellow
            Start-Sleep -Seconds (2 * ($retryCount + 1))  # Exponential backoff
            return Send-ProcessBatch -batch $batch -headers $script:headers -retryCount ($retryCount + 1)
        }

        Write-Host "Failed to send batch after $maxRetries attempts" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        return $false
    }
}

# Main collection loop
try {
    # Initial setup
    Ensure-ValidToken
    
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
    
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        Write-Host "Authentication error - please verify credentials" -ForegroundColor Red
    }
}
finally {
    Write-Host "Collection process ended" -ForegroundColor Yellow
}
