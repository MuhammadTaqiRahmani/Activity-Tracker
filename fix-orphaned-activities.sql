-- Manual Database Fix Script for Orphaned Activities Issue
-- This script fixes the database integrity issue by adding foreign key constraints
-- and cleaning up any existing orphaned data

USE EmployeesProductivityData;
GO

PRINT '=== ORPHANED ACTIVITIES DATABASE FIX SCRIPT ===';
PRINT 'This script will:';
PRINT '1. Check for orphaned activities';
PRINT '2. Clean up orphaned data';
PRINT '3. Add foreign key constraint';
PRINT '4. Create performance index';
PRINT '';

-- Step 1: Check for orphaned activities
PRINT 'Step 1: Checking for orphaned activities...';
DECLARE @OrphanedCount INT;
SELECT @OrphanedCount = COUNT(*) 
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;

PRINT 'Found ' + CAST(@OrphanedCount AS VARCHAR(10)) + ' orphaned activities.';

-- Step 2: Show details of orphaned activities (first 10)
IF @OrphanedCount > 0
BEGIN
    PRINT '';
    PRINT 'Sample orphaned activities:';
    SELECT TOP 10 
        a.id as activity_id,
        a.user_id as non_existent_user_id,
        a.activity_type,
        a.created_at
    FROM activities a 
    LEFT JOIN users u ON a.user_id = u.id 
    WHERE u.id IS NULL
    ORDER BY a.created_at DESC;
    
    -- Show count by user_id
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

-- Step 3: Option to backup orphaned data before deletion
IF @OrphanedCount > 0
BEGIN
    PRINT '';
    PRINT 'Step 3: Creating backup of orphaned activities...';
      -- Drop backup table if it exists and create fresh one
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[orphaned_activities_backup]') AND type in (N'U'))
    BEGIN
        DROP TABLE orphaned_activities_backup;
        PRINT 'Existing backup table dropped.';
    END      -- Create fresh backup table
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

-- Step 4: Clean up orphaned activities
IF @OrphanedCount > 0
BEGIN
    PRINT '';
    PRINT 'Step 4: Cleaning up orphaned activities...';
    
    DELETE FROM activities 
    WHERE user_id NOT IN (SELECT id FROM users);
    
    DECLARE @DeletedCount INT = @@ROWCOUNT;
    PRINT 'Deleted ' + CAST(@DeletedCount AS VARCHAR(10)) + ' orphaned activities.';
END
ELSE
BEGIN
    PRINT 'Step 4: No orphaned activities to clean up.';
END

-- Step 5: Check if foreign key constraint already exists
PRINT '';
PRINT 'Step 5: Checking existing constraints...';

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_activities_user_id')
BEGIN
    PRINT 'Foreign key constraint already exists. Skipping constraint creation.';
END
ELSE
BEGIN
    PRINT 'Step 6: Adding foreign key constraint...';
    
    -- Add the foreign key constraint
    ALTER TABLE activities 
    ADD CONSTRAINT fk_activities_user_id 
    FOREIGN KEY (user_id) REFERENCES users(id) 
    ON DELETE CASCADE;
    
    PRINT 'Foreign key constraint added successfully.';
END

-- Step 7: Create performance index if it doesn't exist
PRINT '';
PRINT 'Step 7: Creating performance index...';

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_activities_user_id' AND object_id = OBJECT_ID('activities'))
BEGIN
    CREATE INDEX idx_activities_user_id ON activities(user_id);
    PRINT 'Performance index created: idx_activities_user_id';
END
ELSE
BEGIN
    PRINT 'Performance index already exists.';
END

-- Step 8: Final verification
PRINT '';
PRINT 'Step 8: Final verification...';

-- Check constraint exists
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_activities_user_id')
BEGIN
    PRINT '✅ Foreign key constraint is active.';
END
ELSE
BEGIN
    PRINT '❌ Foreign key constraint not found!';
END

-- Check for remaining orphaned activities
SELECT @OrphanedCount = COUNT(*) 
FROM activities a 
LEFT JOIN users u ON a.user_id = u.id 
WHERE u.id IS NULL;

IF @OrphanedCount = 0
BEGIN
    PRINT '✅ No orphaned activities found - database integrity verified.';
END
ELSE
BEGIN
    PRINT '❌ Still found ' + CAST(@OrphanedCount AS VARCHAR(10)) + ' orphaned activities!';
END

-- Show final statistics
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
