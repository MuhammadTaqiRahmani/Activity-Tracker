# HTML Report Generator for Authentication API Tests

param (
    [Parameter(Mandatory=$false)]
    [string]$ResultsFilePath = ""
)

# Find latest test results file if not specified
if ([string]::IsNullOrEmpty($ResultsFilePath)) {
    $testResultsDir = "c:\Users\M. Taqi Rahmani\IdeaProjects\Backend-app\test-results"
    $latestFile = Get-ChildItem -Path $testResultsDir -Filter "auth_test_results_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($latestFile) {
        $ResultsFilePath = $latestFile.FullName
        Write-Host "Using latest test results file: $ResultsFilePath"
    } else {
        Write-Host "No test results files found in $testResultsDir"
        exit 1
    }
}

# Check if file exists
if (-not (Test-Path $ResultsFilePath)) {
    Write-Host "File not found: $ResultsFilePath"
    exit 1
}

# Read the test results
$testResults = Get-Content -Path $ResultsFilePath | ConvertFrom-Json

# Extract the filename without extension for the report name
$reportName = [System.IO.Path]::GetFileNameWithoutExtension($ResultsFilePath)
$reportPath = [System.IO.Path]::ChangeExtension($ResultsFilePath, ".html")

# Generate HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Authentication API Test Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .summary {
            background-color: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .summary-item {
            margin-right: 20px;
            font-weight: bold;
        }
        .passed {
            color: green;
        }
        .failed {
            color: red;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            text-align: left;
            padding: 12px 15px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0066cc;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .test-details {
            margin-bottom: 30px;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
        }
        .test-passed {
            border-left: 5px solid green;
        }
        .test-failed {
            border-left: 5px solid red;
        }
        .json {
            background-color: #f8f8f8;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 3px;
            font-family: monospace;
            white-space: pre-wrap;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <h1>Authentication API Test Report</h1>
    <p>Test conducted on: $($testResults.timestamp)</p>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <span class="summary-item">Total Tests: $($testResults.summary.total)</span>
        <span class="summary-item passed">Passed: $($testResults.summary.passed)</span>
        <span class="summary-item failed">Failed: $($testResults.summary.failed)</span>
    </div>
    
    <h2>Test Results</h2>
"@

# Add each test case
foreach ($test in $testResults.tests) {
    $statusClass = if ($test.status -eq "Passed") { "test-passed" } else { "test-failed" }
    
    $html += @"
    <div class="test-details $statusClass">
        <h3>$($test.description)</h3>
        <p><strong>Status:</strong> <span class="$($test.status.ToLower())">$($test.status)</span></p>
        <p><strong>Endpoint:</strong> $($test.endpoint)</p>
        <p><strong>Method:</strong> $($test.method)</p>
        
"@

    if ($test.requestBody) {
        $requestBodyJson = ($test.requestBody | ConvertTo-Json -Depth 5)
        $html += @"
        <p><strong>Request Body:</strong></p>
        <div class="json">$requestBodyJson</div>
"@
    }

    if ($test.PSObject.Properties.Name -contains "response") {
        $responseJson = ($test.response | ConvertTo-Json -Depth 5)
        $html += @"
        <p><strong>Response:</strong></p>
        <div class="json">$responseJson</div>
"@
    }

    if ($test.details) {
        $html += @"
        <p><strong>Details:</strong> $($test.details)</p>
"@
    }

    $html += @"
    </div>
"@
}

$html += @"
</body>
</html>
"@

# Save the HTML report
$html | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "HTML Report generated: $reportPath"
return $reportPath
