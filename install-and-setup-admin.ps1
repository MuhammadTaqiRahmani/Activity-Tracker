Write-Host "`n=== Installing Required Modules and Setting up Admin ===" -ForegroundColor Cyan

# Check if SqlServer module is installed
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "SqlServer module not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
        Write-Host "SqlServer module installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install SqlServer module: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
}

$server = "localhost"
$database = "EmployeesProductivityData"
$username = "sa"
$password = "Fake4Face"

# Test SQL Server connection
Write-Host "`nTesting SQL Server connection..." -ForegroundColor Yellow
try {
    $query = "SELECT @@VERSION AS Version"
    $result = Invoke-Sqlcmd -ServerInstance $server `
        -Database "master" `
        -Username $username `
        -Password $password `
        -Query $query `
        -ErrorAction Stop
    
    Write-Host "SQL Server connection successful!" -ForegroundColor Green
    Write-Host "Version: $($result.Version)" -ForegroundColor Gray
}
catch {
    Write-Host "SQL Server connection failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

# Create database if it doesn't exist
Write-Host "`nChecking database..." -ForegroundColor Yellow
$createDbQuery = @"
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$database')
BEGIN
    CREATE DATABASE [$database]
    PRINT 'Database created successfully'
END
ELSE
BEGIN
    PRINT 'Database already exists'
END
"@

try {
    Invoke-Sqlcmd -ServerInstance $server `
        -Database "master" `
        -Username $username `
        -Password $password `
        -Query $createDbQuery
    Write-Host "Database check completed!" -ForegroundColor Green
}
catch {
    Write-Host "Database creation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Execute admin setup script
Write-Host "`nSetting up admin user..." -ForegroundColor Yellow
try {
    $adminSetupScript = Get-Content ".\check-admin-db.sql" -Raw
    Invoke-Sqlcmd -ServerInstance $server `
        -Database $database `
        -Username $username `
        -Password $password `
        -Query $adminSetupScript
    Write-Host "Admin user setup completed!" -ForegroundColor Green
    
    # Verify admin user
    $verifyQuery = "SELECT id, username, email, role, active, created_at FROM users WHERE username = 'admin'"
    $adminUser = Invoke-Sqlcmd -ServerInstance $server `
        -Database $database `
        -Username $username `
        -Password $password `
        -Query $verifyQuery
    
    Write-Host "`nAdmin User Details:" -ForegroundColor Yellow
    Write-Host "ID: $($adminUser.id)" -ForegroundColor White
    Write-Host "Username: $($adminUser.username)" -ForegroundColor White
    Write-Host "Email: $($adminUser.email)" -ForegroundColor White
    Write-Host "Role: $($adminUser.role)" -ForegroundColor White
    Write-Host "Active: $($adminUser.active)" -ForegroundColor White
    Write-Host "Created: $($adminUser.created_at)" -ForegroundColor White
}
catch {
    Write-Host "Admin setup failed: $($_.Exception.Message)" -ForegroundColor Red
}
