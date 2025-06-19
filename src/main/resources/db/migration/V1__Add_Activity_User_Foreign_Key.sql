-- Add foreign key constraint to activities table to prevent orphaned activities
-- This migration adds referential integrity between activities and users tables

-- First, clean up any existing orphaned activities (if any exist)
DELETE FROM activities 
WHERE user_id NOT IN (SELECT id FROM users);

-- Add the foreign key constraint
ALTER TABLE activities 
ADD CONSTRAINT fk_activities_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) 
ON DELETE CASCADE;

-- Create index for better performance on foreign key lookups
CREATE INDEX idx_activities_user_id ON activities(user_id);

-- Add comment to document the constraint
EXEC sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Foreign key constraint to ensure activities cannot exist without a corresponding user. Cascades on delete to maintain data integrity.',
    @level0type = N'SCHEMA',
    @level0name = N'dbo',
    @level1type = N'TABLE',
    @level1name = N'activities',
    @level2type = N'CONSTRAINT',
    @level2name = N'fk_activities_user_id';
