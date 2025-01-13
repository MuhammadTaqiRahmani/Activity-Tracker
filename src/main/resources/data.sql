-- First, clear existing admin user
DELETE FROM users WHERE username = 'admin';

-- Insert admin with encoded password (generated from BCrypt with strength 10)
INSERT INTO users (username, email, password, role, active, created_at)
VALUES (
    'admin',
    'admin@system.com',
    '$2a$10$GVJRz0KgL8XTt0DJn.J2/.6Bow4SKGLmxzHxgRxgaIc4zQnRlDHhi',  -- admin123
    'ROLE_ADMIN',
    1,
    CURRENT_TIMESTAMP
);
