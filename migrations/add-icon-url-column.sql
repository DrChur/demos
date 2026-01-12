-- Migration: Add icon_url column to projects table
-- This adds support for project icons/logos

-- Add icon_url column to projects table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'projects' 
    AND column_name = 'icon_url'
  ) THEN
    ALTER TABLE projects ADD COLUMN icon_url text;
  END IF;
END $$;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'projects' 
ORDER BY ordinal_position;
