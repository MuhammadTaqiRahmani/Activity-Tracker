# Database Migration Guide - Fix Orphaned Activities Issue

## 🎯 Overview
This guide helps you fix the orphaned activities issue on another PC/system that has the old database schema. The fix includes adding foreign key constraints, cleaning up orphaned data, and optimizing performance.

---

## 📋 Migration Steps

### **Step 1: Backup Current Database (IMPORTANT!)**
Before making any changes, always backup your database:

```sql
-- Create a full backup of your database
BACKUP DATABASE EmployeesProductivityData 
TO DISK = 'C:\Backup\EmployeesProductivityData_Backup_Before_Fix.bak'
WITH FORMAT, INIT, DESCRIPTION = 'Full backup before orphaned activities fix';

-- Verify backup was created successfully
RESTORE VERIFYONLY 
FROM DISK = 'C:\Backup\EmployeesProductivityData_Backup_Before_Fix.bak';
```

### **Step 2: Run the Complete Migration Script**
Use the script below to fix all database issues:

```sql
-- =====================================================
-- COMPLETE DATABASE FIX SCRIPT FOR ORPHANED ACTIVITIES
-- =====================================================
-- This script fixes the database on another PC/system
-- Run this script on the system with the old database
-- =====================================================

USE EmployeesProductivityData;
GO

PRINT '=== STARTING DATABASE FIX FOR ORPHANED ACTIVITIES ===';
PRINT 'Date: ' + CAST(GETDATE() AS VARCHAR(50));
PRINT '';

-- Step 1: Check current state
PRINT 'Step 1: Checking current database state...';

DECLARE @OrphanedCount INT;
SELECT @OrphanedCount = COUNT(*)
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;

PRINT 'Found ' + CAST(@OrphanedCount AS VARCHAR(10)) + ' orphaned activities.';

-- Display sample orphaned activities if any exist
IF @OrphanedCount > 0
BEGIN
    PRINT '';
    PRINT 'Sample orphaned activities:';
    SELECT TOP 5 
        a.id as activity_id,
        a.user_id as non_existent_user_id,
        a.activity_type,
        a.created_at
    FROM activities a 
    LEFT JOIN users u ON a.user_id = u.id 
    WHERE u.id IS NULL
    ORDER BY a.created_at DESC;
    
    PRINT '';
    PRINT 'Orphaned activities count by non-existent user_id:';
    SELECT 
        a.user_id as non_existent_user_id,
        COUNT(*) as activity_count
    FROM activities a 
    LEFT JOIN users u ON a.user_id = u.id 
    WHERE u.id IS NULL
    GROUP BY a.user_id
    ORDER BY activity_count DESC;
END
ELSE
BEGIN
    PRINT 'No orphaned activities found - database is already clean.';
END

-- Step 2: Create backup of orphaned data before deletion
IF @OrphanedCount > 0
BEGIN
    PRINT '';
    PRINT 'Step 2: Creating backup of orphaned activities...';
    
    -- Drop backup table if it exists and create fresh one
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[orphaned_activities_backup]') AND type in (N'U'))
    BEGIN
        DROP TABLE orphaned_activities_backup;
        PRINT 'Existing backup table dropped.';
    END
    
    -- Create fresh backup table
    SELECT a.* 
    INTO orphaned_activities_backup
    FROM activities a 
    LEFT JOIN users u ON a.user_id = u.id 
    WHERE u.id IS NULL;
    
    PRINT 'Backup created: orphaned_activities_backup table with ' + CAST(@OrphanedCount AS VARCHAR(10)) + ' records.';
END
ELSE
BEGIN
    PRINT 'No orphaned activities found. Skipping backup creation.';
END

-- Step 3: Clean up orphaned activities
IF @OrphanedCount > 0
BEGIN
    PRINT '';
    PRINT 'Step 3: Cleaning up orphaned activities...';
    
    DELETE FROM activities 
    WHERE user_id NOT IN (SELECT id FROM users);
    
    DECLARE @DeletedCount INT = @@ROWCOUNT;
    PRINT 'Deleted ' + CAST(@DeletedCount AS VARCHAR(10)) + ' orphaned activities.';
END
ELSE
BEGIN
    PRINT 'Step 3: No orphaned activities to clean up.';
END

-- Step 4: Check existing constraints
PRINT '';
PRINT 'Step 4: Checking existing constraints...';

IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_NAME = 'fk_activities_user_id' 
    AND TABLE_NAME = 'activities'
)
BEGIN
    PRINT 'Foreign key constraint already exists: fk_activities_user_id';
END
ELSE
BEGIN
    PRINT 'Foreign key constraint does not exist. Will create it.';
END

-- Step 5: Add foreign key constraint
PRINT '';
PRINT 'Step 5: Adding foreign key constraint...';

-- Drop constraint if it exists (in case it exists but wasn't detected)
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_NAME = 'fk_activities_user_id' 
    AND TABLE_NAME = 'activities'
)
BEGIN
    ALTER TABLE activities DROP CONSTRAINT fk_activities_user_id;
    PRINT 'Existing foreign key constraint dropped.';
END

-- Add the foreign key constraint
BEGIN TRY
    ALTER TABLE activities 
    ADD CONSTRAINT fk_activities_user_id 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    PRINT 'Foreign key constraint added successfully.';
END TRY
BEGIN CATCH
    PRINT 'Error adding foreign key constraint: ' + ERROR_MESSAGE();
    PRINT 'This might indicate there are still orphaned activities.';
    
    -- Check again for orphaned activities
    SELECT @OrphanedCount = COUNT(*)
    FROM activities a 
    LEFT JOIN users u ON a.user_id = u.id 
    WHERE u.id IS NULL;
    
    IF @OrphanedCount > 0
    BEGIN
        PRINT 'Found ' + CAST(@OrphanedCount AS VARCHAR(10)) + ' remaining orphaned activities:';
        SELECT 
            a.user_id as problematic_user_id,
            COUNT(*) as count
        FROM activities a 
        LEFT JOIN users u ON a.user_id = u.id 
        WHERE u.id IS NULL
        GROUP BY a.user_id;
        
        PRINT 'Please manually clean these activities before adding the foreign key constraint.';
    END
END CATCH

-- Step 6: Create performance index
PRINT '';
PRINT 'Step 6: Creating performance index...';

-- Check if index already exists
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_activities_user_id' AND object_id = OBJECT_ID('activities'))
BEGIN
    PRINT 'Performance index already exists: idx_activities_user_id';
END
ELSE
BEGIN
    CREATE INDEX idx_activities_user_id ON activities(user_id);
    PRINT 'Performance index created: idx_activities_user_id';
END

-- Step 7: Final verification
PRINT '';
PRINT 'Step 7: Final verification...';

-- Check foreign key constraint
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_NAME = 'fk_activities_user_id' 
    AND TABLE_NAME = 'activities'
)
BEGIN
    PRINT '✓ Foreign key constraint is active.';
END
ELSE
BEGIN
    PRINT '✗ Foreign key constraint is NOT active.';
END

-- Check for remaining orphaned activities
SELECT @OrphanedCount = COUNT(*)
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;

IF @OrphanedCount = 0
BEGIN
    PRINT '✓ No orphaned activities found - database integrity verified.';
END
ELSE
BEGIN
    PRINT '✗ Still found ' + CAST(@OrphanedCount AS VARCHAR(10)) + ' orphaned activities.';
END

-- Step 8: Display final statistics
PRINT '';
PRINT '=== FINAL STATISTICS ===';
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM activities) as total_activities,
    (SELECT COUNT(DISTINCT user_id) FROM activities) as users_with_activities;

PRINT '';
PRINT '=== DATABASE FIX COMPLETED ===';
PRINT 'The database now has proper referential integrity between users and activities.';
PRINT 'Future activity creation will automatically validate user existence.';
PRINT 'If you delete a user, their activities will be automatically deleted (CASCADE).';

GO
```

---

## 🚀 Quick Fix Script (Alternative)

If you prefer a simpler approach, use this condensed script:

```sql
-- QUICK FIX SCRIPT FOR ORPHANED ACTIVITIES
USE EmployeesProductivityData;

-- 1. Backup orphaned activities
SELECT a.* 
INTO orphaned_activities_backup_quick
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;

-- 2. Delete orphaned activities
DELETE FROM activities 
WHERE user_id NOT IN (SELECT id FROM users);

-- 3. Add foreign key constraint
ALTER TABLE activities 
ADD CONSTRAINT fk_activities_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- 4. Add performance index
CREATE INDEX idx_activities_user_id ON activities(user_id);

-- 5. Verify fix
SELECT COUNT(*) as orphaned_count 
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;
```

---

## 📝 Instructions for Running on Another PC

### **Method 1: Using SQL Server Management Studio (SSMS)**
1. **Connect to SQL Server** on the other PC
2. **Open New Query** window
3. **Copy and paste** the complete migration script above
4. **Execute** the script (F5)
5. **Review** the output messages to ensure success

### **Method 2: Using Command Line (sqlcmd)**
1. **Save the script** to a file: `database_fix_script.sql`
2. **Copy the file** to the other PC
3. **Run the command**:
   ```bash
   sqlcmd -S localhost,1433 -U sa -P "YourPassword" -d EmployeesProductivityData -i "database_fix_script.sql"
   ```
4. **Check the output** for success messages

### **Method 3: Using PowerShell Script**
Create a PowerShell script for automated execution:

```powershell
# save as: fix_database.ps1
$ServerInstance = "localhost,1433"
$Database = "EmployeesProductivityData"
$Username = "sa"
$Password = "YourPassword"  # Replace with actual password

Write-Host "=== DATABASE FIX SCRIPT ===" -ForegroundColor Cyan
Write-Host "Connecting to: $ServerInstance" -ForegroundColor Yellow
Write-Host "Database: $Database" -ForegroundColor Yellow

try {
    sqlcmd -S $ServerInstance -U $Username -P $Password -d $Database -i "database_fix_script.sql"
    Write-Host "Database fix completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
}
```

---

## ✅ Verification Steps

After running the fix script, verify everything is working:

### **1. Check Database Integrity**
```sql
-- Verify no orphaned activities
SELECT COUNT(*) as orphaned_count 
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;
-- Should return 0

-- Verify foreign key constraint exists
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE CONSTRAINT_NAME = 'fk_activities_user_id';
-- Should return the constraint information
```

### **2. Test the Fix**
```sql
-- Try to insert activity with non-existent user (should fail)
INSERT INTO activities (user_id, activity_type, created_at) 
VALUES (99999, 'TEST', GETDATE());
-- Should get foreign key constraint error

-- Verify current statistics
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM activities) as total_activities,
    (SELECT COUNT(DISTINCT user_id) FROM activities) as users_with_activities;
```

### **3. Update Application Configuration**
Make sure the application on the other PC uses the correct configuration:

```properties
# Update application.properties
spring.jpa.hibernate.ddl-auto=validate
# This prevents Hibernate from modifying the fixed schema
```

---

## 🔧 Troubleshooting

### **If Foreign Key Constraint Fails**
```sql
-- Find remaining orphaned activities
SELECT a.user_id, COUNT(*) as count
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL
GROUP BY a.user_id;

-- Delete specific orphaned activities
DELETE FROM activities WHERE user_id = [problematic_user_id];

-- Then retry adding the constraint
ALTER TABLE activities 
ADD CONSTRAINT fk_activities_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
```

### **If Database Connection Issues**
1. **Check SQL Server service** is running
2. **Verify connection string** and credentials
3. **Ensure database exists** and is accessible
4. **Check firewall settings** for SQL Server port (1433)

---

## 📋 Post-Migration Checklist

- [ ] **Database backup** created before migration
- [ ] **Migration script** executed successfully
- [ ] **Zero orphaned activities** confirmed
- [ ] **Foreign key constraint** active
- [ ] **Performance index** created
- [ ] **Application configuration** updated
- [ ] **Backend application** tested
- [ ] **Frontend application** verified working
- [ ] **No "User not found" errors** in application

---

**This migration guide will fix the orphaned activities issue on your other PC/system and bring it to the same state as the fixed database on this system.**
