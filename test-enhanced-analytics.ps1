# Configuration
$baseUrl = "http://localhost:8080"
$userId = 20  # Use the user ID from your previous test
$token = "" # Will be set after login

# Login to get token
$loginBody = @{
    username = "testuser_211178658"
    password = "password123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/users/login" -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "=== Testing Enhanced Analytics ===" -ForegroundColor Green

# Test dates
$startDate = [DateTime]::Now.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ss")
$endDate = [DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss")

# 1. Test Enhanced Application Usage Analytics
Write-Host "`nTesting Enhanced Application Usage Analytics..." -ForegroundColor Yellow
try {
    $appUsageAnalytics = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/analytics/app-usage/detailed?userId=$userId&startDate=$startDate&endDate=$endDate" `
        -Headers $headers

    Write-Host "Application Usage Analytics Results:" -ForegroundColor Green
    Write-Host "Category Usage:" -ForegroundColor Cyan
    $appUsageAnalytics.applicationTimeByCategory | ConvertTo-Json
    
    Write-Host "`nProductivity Scores:" -ForegroundColor Cyan
    $appUsageAnalytics.productivityScoreByApp | ConvertTo-Json
    
    Write-Host "`nApplication Switch Frequency:" -ForegroundColor Cyan
    $appUsageAnalytics.applicationSwitchFrequency | ConvertTo-Json
    
    Write-Host "`nFocus Score:" -ForegroundColor Cyan
    $appUsageAnalytics.focusScore
}
catch {
    Write-Host "Error testing application usage analytics: $_" -ForegroundColor Red
}

# 2. Test Enhanced Task Completion Analytics
Write-Host "`nTesting Enhanced Task Completion Analytics..." -ForegroundColor Yellow
try {
    $taskAnalytics = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/analytics/task-completion/detailed?userId=$userId&startDate=$startDate&endDate=$endDate" `
        -Headers $headers

    Write-Host "Task Analytics Results:" -ForegroundColor Green
    Write-Host "Task Efficiency by Category:" -ForegroundColor Cyan
    $taskAnalytics.taskEfficiencyByCategory | ConvertTo-Json
    
    Write-Host "`nTask Status Distribution:" -ForegroundColor Cyan
    $taskAnalytics.taskStatusDistribution | ConvertTo-Json
    
    Write-Host "`nProductivity Trends:" -ForegroundColor Cyan
    $taskAnalytics.productivityTrends | ConvertTo-Json
    
    Write-Host "`nCompletion Statistics:" -ForegroundColor Cyan
    Write-Host "Tasks Completed On Time: $($taskAnalytics.tasksCompletedOnTime)"
    Write-Host "Tasks Delayed: $($taskAnalytics.tasksDelayed)"
    Write-Host "Efficiency Score: $($taskAnalytics.efficiencyScore)%"
}
catch {
    Write-Host "Error testing task completion analytics: $_" -ForegroundColor Red
}

# 3. Test Combined Analytics (Efficiency Metrics)
Write-Host "`nTesting Combined Efficiency Metrics..." -ForegroundColor Yellow
try {
    $efficiencyMetrics = Invoke-RestMethod -Method Get `
        -Uri "$baseUrl/api/analytics/efficiency-metrics?userId=$userId&startDate=$startDate&endDate=$endDate" `
        -Headers $headers

    Write-Host "Combined Analytics Results:" -ForegroundColor Green
    Write-Host "Task Metrics:" -ForegroundColor Cyan
    $efficiencyMetrics.tasks | ConvertTo-Json -Depth 3
    
    Write-Host "`nWorkspace Metrics:" -ForegroundColor Cyan
    $efficiencyMetrics.workspaces | ConvertTo-Json -Depth 3
    
    Write-Host "`nProductivity Metrics:" -ForegroundColor Cyan
    $efficiencyMetrics.productivity | ConvertTo-Json -Depth 3
}
catch {
    Write-Host "Error testing efficiency metrics: $_" -ForegroundColor Red
}

# Summary Report
Write-Host "`n=== Analytics Test Summary ===" -ForegroundColor Green
Write-Host "1. Application Usage Analytics: " -NoNewline
if ($appUsageAnalytics) { Write-Host "PASSED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

Write-Host "2. Task Completion Analytics: " -NoNewline
if ($taskAnalytics) { Write-Host "PASSED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

Write-Host "3. Combined Efficiency Metrics: " -NoNewline
if ($efficiencyMetrics) { Write-Host "PASSED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

Write-Host "`nTest completed!" -ForegroundColor Green
