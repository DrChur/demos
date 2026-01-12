-- Migration: Add audio metadata columns to songs table
-- This adds support for storing audio file information

-- Add audio metadata columns to songs table if they don't exist
DO $$ 
BEGIN
  -- Add file_url column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'file_url'
  ) THEN
    ALTER TABLE songs ADD COLUMN file_url text;
  END IF;

  -- Add file_size column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'file_size'
  ) THEN
    ALTER TABLE songs ADD COLUMN file_size bigint;
  END IF;

  -- Add file_type column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'file_type'
  ) THEN
    ALTER TABLE songs ADD COLUMN file_type text;
  END IF;

  -- Add duration column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'duration'
  ) THEN
    ALTER TABLE songs ADD COLUMN duration integer;
  END IF;
END $$;

-- Also add file columns to song_versions table if they don't exist
DO $$ 
BEGIN
  -- Add file_url column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'song_versions' 
    AND column_name = 'file_url'
  ) THEN
    ALTER TABLE song_versions ADD COLUMN file_url text;
  END IF;

  -- Add original_file_url column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'song_versions' 
    AND column_name = 'original_file_url'
  ) THEN
    ALTER TABLE song_versions ADD COLUMN original_file_url text;
  END IF;
END $$;

-- Verify the columns were added
SELECT 'songs table columns:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'songs' 
ORDER BY ordinal_position;

SELECT 'song_versions table columns:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'song_versions' 
ORDER BY ordinal_position;
