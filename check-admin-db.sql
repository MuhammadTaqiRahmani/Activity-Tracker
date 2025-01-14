-- First ensure the table exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[users]') AND type in (N'U'))
BEGIN
    CREATE TABLE users (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        username VARCHAR(255) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL,
        active BIT NOT NULL DEFAULT 1,
        created_at DATETIME2 NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Users table created.';
END

-- Clear existing admin user to avoid conflicts
DELETE FROM users WHERE username = 'admin';
PRINT 'Cleared existing admin user.';

-- Insert fresh admin user with encoded password
INSERT INTO users (username, email, password, role, active, created_at)
VALUES (
    'admin',
    'admin@system.com',
    '$2a$10$GVJRz0KgL8XTt0DJn.J2/.6Bow4SKGLmxzHxgRxgaIc4zQnRlDHhi',  -- password: admin123
    'ROLE_ADMIN',
    1,
    GETDATE()
);
PRINT 'Admin user created successfully.';

-- Verify admin exists
SELECT id, username, email, role, active, created_at 
FROM users 
WHERE username = 'admin';
