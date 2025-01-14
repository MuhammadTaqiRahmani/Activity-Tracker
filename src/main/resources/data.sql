-- Check if admin user exists
IF NOT EXISTS (SELECT * FROM users WHERE username = 'admin')
BEGIN
    -- Insert admin with encoded password
    INSERT INTO users (username, email, password, role, active, created_at)
    VALUES (
        'admin',
        'admin@system.com',
        '$2a$10$GVJRz0KgL8XTt0DJn.J2/.6Bow4SKGLmxzHxgRxgaIc4zQnRlDHhi',  -- password: admin123
        'ROLE_ADMIN',
        1,
        GETDATE()
    );
    PRINT 'Admin user created successfully';
END
ELSE
BEGIN
    PRINT 'Admin user already exists';
END

-- Verify admin exists
SELECT * FROM users WHERE username = 'admin';
