$server = "localhost"
$database = "EmployeesProductivityData"
$username = "sa"
$password = "Fake4Face"

Write-Host "`n=== Setting up Admin User in Database ===" -ForegroundColor Cyan

try {
    # Import SQL Server module
    Import-Module SqlServer -ErrorAction Stop
    
    Write-Host "Executing database setup script..." -ForegroundColor Yellow
    
    # Execute the SQL script
    Invoke-Sqlcmd -ServerInstance $server `
        -Database $database `
        -Username $username `
        -Password $password `
        -InputFile ".\check-admin-db.sql" `
        -QueryTimeout 30 `
        -ErrorAction Stop
    
    Write-Host "`nAdmin user setup completed successfully!" -ForegroundColor Green
    
    # Verify admin user
    $query = "SELECT id, username, email, role, active, created_at FROM users WHERE username = 'admin'"
    $result = Invoke-Sqlcmd -ServerInstance $server `
        -Database $database `
        -Username $username `
        -Password $password `
        -Query $query
    
    Write-Host "`nAdmin User Details:" -ForegroundColor Yellow
    Write-Host "ID: $($result.id)" -ForegroundColor White
    Write-Host "Username: $($result.username)" -ForegroundColor White
    Write-Host "Email: $($result.email)" -ForegroundColor White
    Write-Host "Role: $($result.role)" -ForegroundColor White
    Write-Host "Active: $($result.active)" -ForegroundColor White
    Write-Host "Created: $($result.created_at)" -ForegroundColor White
}
catch {
    Write-Host "`nError setting up admin user:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "1. Ensure SQL Server is running" -ForegroundColor White
    Write-Host "2. Verify database credentials in setup-admin.ps1" -ForegroundColor White
    Write-Host "3. Check if database 'EmployeesProductivityData' exists" -ForegroundColor White
    Write-Host "4. Make sure you have appropriate SQL Server permissions" -ForegroundColor White
}
