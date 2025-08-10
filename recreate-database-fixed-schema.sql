-- Complete Database Recreation Script with Fixed Schema
-- This script recreates the entire database with proper foreign key constraints
-- and all necessary tables for the Employee Productivity Tracking System

-- =====================================================
-- STEP 1: DROP AND RECREATE DATABASE
-- =====================================================

USE master;
GO

-- Drop database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'EmployeesProductivityData')
BEGIN
    ALTER DATABASE EmployeesProductivityData SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EmployeesProductivityData;
    PRINT 'Existing database dropped successfully.';
END

-- Create fresh database
CREATE DATABASE EmployeesProductivityData;
PRINT 'New database created successfully.';
GO

USE EmployeesProductivityData;
GO

PRINT '=== CREATING FRESH DATABASE WITH FIXED SCHEMA ===';
PRINT 'Database: EmployeesProductivityData';
PRINT 'Date: 2025-06-19';
PRINT 'Purpose: Recreate with proper foreign key constraints';
PRINT '';

-- =====================================================
-- STEP 2: CREATE USERS TABLE (PRIMARY TABLE)
-- =====================================================

PRINT 'Creating users table...';
CREATE TABLE users (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'ROLE_EMPLOYEE',
    active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Add indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(active);

PRINT 'Users table created with indexes.';

-- =====================================================
-- STEP 3: CREATE ACTIVITIES TABLE WITH FOREIGN KEY
-- =====================================================

PRINT 'Creating activities table with foreign key constraints...';
CREATE TABLE activities (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    description NVARCHAR(1000) NOT NULL,
    application_name VARCHAR(255),
    workspace_type VARCHAR(50),
    duration_seconds BIGINT,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    idle_time_seconds BIGINT,
    activity_status VARCHAR(20) DEFAULT 'ACTIVE',
    application_category VARCHAR(100),
    process_id VARCHAR(50),
    process_name VARCHAR(255),
    window_title NVARCHAR(500),
    ip_address VARCHAR(45),
    machine_id VARCHAR(255),
    tamper_attempt BIT DEFAULT 0,
    tamper_details NVARCHAR(1000),
    hash_value VARCHAR(255),
    start_time DATETIME2,
    end_time DATETIME2,
    version BIGINT DEFAULT 0,
    
    -- FOREIGN KEY CONSTRAINT - THIS FIXES THE ORPHANED ACTIVITIES ISSUE
    CONSTRAINT fk_activities_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE
);

-- Add performance indexes
CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_created_at ON activities(created_at);
CREATE INDEX idx_activities_activity_type ON activities(activity_type);
CREATE INDEX idx_activities_application_name ON activities(application_name);
CREATE INDEX idx_activities_start_time ON activities(start_time);
CREATE INDEX idx_activities_status ON activities(activity_status);

PRINT 'Activities table created with foreign key constraint and indexes.';

-- =====================================================
-- STEP 4: CREATE PROCESS_TRACKS TABLE WITH FOREIGN KEY
-- =====================================================

PRINT 'Creating process_tracks table...';
CREATE TABLE process_tracks (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    process_name VARCHAR(255) NOT NULL,
    window_title NVARCHAR(500),
    process_id VARCHAR(50) NOT NULL,
    category VARCHAR(100),
    start_time DATETIME2 NOT NULL,
    end_time DATETIME2,
    duration_seconds BIGINT,
    is_productive_app BIT,
    application_path NVARCHAR(1000),
    
    -- FOREIGN KEY CONSTRAINT
    CONSTRAINT fk_process_tracks_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE
);

-- Add indexes
CREATE INDEX idx_process_tracks_user_id ON process_tracks(user_id);
CREATE INDEX idx_process_tracks_start_time ON process_tracks(start_time);
CREATE INDEX idx_process_tracks_process_name ON process_tracks(process_name);

PRINT 'Process_tracks table created with foreign key constraint.';

-- =====================================================
-- STEP 5: CREATE TASKS TABLE WITH FOREIGN KEY
-- =====================================================

PRINT 'Creating tasks table...';
CREATE TABLE tasks (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description NVARCHAR(1000),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    start_time DATETIME2,
    completion_time DATETIME2,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    -- FOREIGN KEY CONSTRAINT
    CONSTRAINT fk_tasks_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE
);

-- Add indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_start_time ON tasks(start_time);

PRINT 'Tasks table created with foreign key constraint.';

-- =====================================================
-- STEP 6: INSERT DEFAULT ADMIN USER
-- =====================================================

PRINT 'Creating default admin user...';
INSERT INTO users (username, email, password, role, active, created_at)
VALUES (
    'admin',
    'admin@system.com',
    '$2a$10$N0MHe5T9wCf1LgRN5WmfgeFOhHGCFQs6YdGfnr1KRMUwp3qGv8aKu', -- Password: admin123
    'ROLE_ADMIN',
    1,
    GETDATE()
);

DECLARE @AdminId BIGINT = SCOPE_IDENTITY();
PRINT 'Default admin user created with ID: ' + CAST(@AdminId AS VARCHAR(10));

-- =====================================================
-- STEP 7: INSERT SAMPLE USERS FOR TESTING
-- =====================================================

PRINT 'Creating sample users for testing...';
INSERT INTO users (username, email, password, role, active, created_at)
VALUES 
    ('employee1', 'employee1@company.com', '$2a$10$N0MHe5T9wCf1LgRN5WmfgeFOhHGCFQs6YdGfnr1KRMUwp3qGv8aKu', 'ROLE_EMPLOYEE', 1, GETDATE()),
    ('employee2', 'employee2@company.com', '$2a$10$N0MHe5T9wCf1LgRN5WmfgeFOhHGCFQs6YdGfnr1KRMUwp3qGv8aKu', 'ROLE_EMPLOYEE', 1, GETDATE()),
    ('manager1', 'manager1@company.com', '$2a$10$N0MHe5T9wCf1LgRN5WmfgeFOhHGCFQs6YdGfnr1KRMUwp3qGv8aKu', 'ROLE_ADMIN', 1, GETDATE()),
    ('superadmin', 'superadmin@system.com', '$2a$10$N0MHe5T9wCf1LgRN5WmfgeFOhHGCFQs6YdGfnr1KRMUwp3qGv8aKu', 'ROLE_SUPERADMIN', 1, GETDATE());

PRINT 'Sample users created successfully.';

-- =====================================================
-- STEP 8: INSERT SAMPLE ACTIVITIES FOR TESTING
-- =====================================================

PRINT 'Creating sample activities...';
DECLARE @EmployeeId BIGINT = (SELECT TOP 1 id FROM users WHERE username = 'employee1');

INSERT INTO activities (user_id, activity_type, description, application_name, workspace_type, duration_seconds, activity_status, application_category)
VALUES 
    (@EmployeeId, 'APPLICATION_USAGE', 'Working on Visual Studio Code', 'Code.exe', 'PRODUCTIVE', 3600, 'ACTIVE', 'DEVELOPMENT'),
    (@EmployeeId, 'APPLICATION_USAGE', 'Checking emails in Outlook', 'OUTLOOK.EXE', 'PRODUCTIVE', 1200, 'ACTIVE', 'COMMUNICATION'),
    (@EmployeeId, 'APPLICATION_USAGE', 'Web browsing for research', 'chrome.exe', 'NEUTRAL', 1800, 'ACTIVE', 'BROWSER'),
    (@EmployeeId, 'PROCESS_MONITORING', 'System monitoring activity', 'explorer.exe', 'SYSTEM', 300, 'IDLE', 'SYSTEM');

PRINT 'Sample activities created successfully.';

-- =====================================================
-- STEP 9: VERIFY FOREIGN KEY CONSTRAINTS
-- =====================================================

PRINT '';
PRINT '=== VERIFYING FOREIGN KEY CONSTRAINTS ===';

-- Test orphaned activity prevention
PRINT 'Testing foreign key constraint (this should fail):';
BEGIN TRY
    INSERT INTO activities (user_id, activity_type, description) 
    VALUES (99999, 'TEST', 'This should fail due to foreign key constraint');
    PRINT 'ERROR: Foreign key constraint not working!';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Foreign key constraint is working - orphaned activities prevented!';
END CATCH

-- =====================================================
-- STEP 10: DISPLAY FINAL STATISTICS
-- =====================================================

PRINT '';
PRINT '=== DATABASE RECREATION COMPLETED SUCCESSFULLY ===';
PRINT '';

-- Display table counts
SELECT 
    'users' as table_name, 
    COUNT(*) as record_count 
FROM users
UNION ALL
SELECT 
    'activities' as table_name, 
    COUNT(*) as record_count 
FROM activities
UNION ALL
SELECT 
    'process_tracks' as table_name, 
    COUNT(*) as record_count 
FROM process_tracks
UNION ALL
SELECT 
    'tasks' as table_name, 
    COUNT(*) as record_count 
FROM tasks;

-- Display foreign key constraints
PRINT '';
PRINT 'Foreign Key Constraints Created:';
SELECT 
    fk.name AS constraint_name,
    tp.name AS parent_table,
    cp.name AS parent_column,
    tr.name AS referenced_table,
    cr.name AS referenced_column
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns cp ON fkc.parent_column_id = cp.column_id AND fkc.parent_object_id = cp.object_id
INNER JOIN sys.columns cr ON fkc.referenced_column_id = cr.column_id AND fkc.referenced_object_id = cr.object_id;

-- Display users created
PRINT '';
PRINT 'Users Created:';
SELECT id, username, email, role, active, created_at FROM users ORDER BY id;

PRINT '';
PRINT '=== SUMMARY ===';
PRINT '✓ Database recreated with proper schema';
PRINT '✓ Foreign key constraints implemented';
PRINT '✓ Orphaned activities issue FIXED';
PRINT '✓ Performance indexes created';
PRINT '✓ Sample data inserted';
PRINT '✓ All tables properly linked';
PRINT '';
PRINT 'Default Login Credentials:';
PRINT 'Username: admin';
PRINT 'Password: admin123';
PRINT '';
PRINT 'The database is now ready for use with the fixed backend application!';

GO
