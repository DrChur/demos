-- Complete Database Setup Migration
-- Run this ONCE to set up all missing columns and storage policies
-- Safe to run multiple times (uses IF NOT EXISTS checks)

-- ============================================
-- PART 1: ADD MISSING COLUMNS TO TABLES
-- ============================================

-- Add icon_url to projects table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'projects' 
    AND column_name = 'icon_url'
  ) THEN
    ALTER TABLE projects ADD COLUMN icon_url text;
    RAISE NOTICE 'Added icon_url column to projects table';
  ELSE
    RAISE NOTICE 'icon_url column already exists in projects table';
  END IF;
END $$;

-- Add audio columns to songs table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'file_url'
  ) THEN
    ALTER TABLE songs ADD COLUMN file_url text;
    RAISE NOTICE 'Added file_url column to songs table';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'file_size'
  ) THEN
    ALTER TABLE songs ADD COLUMN file_size bigint;
    RAISE NOTICE 'Added file_size column to songs table';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'file_type'
  ) THEN
    ALTER TABLE songs ADD COLUMN file_type text;
    RAISE NOTICE 'Added file_type column to songs table';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'songs' 
    AND column_name = 'duration'
  ) THEN
    ALTER TABLE songs ADD COLUMN duration integer;
    RAISE NOTICE 'Added duration column to songs table';
  END IF;
END $$;

-- Add file columns to song_versions table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'song_versions' 
    AND column_name = 'file_url'
  ) THEN
    ALTER TABLE song_versions ADD COLUMN file_url text;
    RAISE NOTICE 'Added file_url column to song_versions table';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'song_versions' 
    AND column_name = 'original_file_url'
  ) THEN
    ALTER TABLE song_versions ADD COLUMN original_file_url text;
    RAISE NOTICE 'Added original_file_url column to song_versions table';
  END IF;
END $$;

-- ============================================
-- PART 2: STORAGE BUCKET POLICIES
-- ============================================

-- Drop existing policies if they exist (to avoid conflicts on re-run)
DROP POLICY IF EXISTS "Authenticated users can upload audio files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their audio files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read audio files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their audio files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload project icons" ON storage.objects;
DROP POLICY IF EXISTS "Project members can update project icons" ON storage.objects;
DROP POLICY IF EXISTS "Public can read project icons" ON storage.objects;

-- AUDIO BUCKET POLICIES
CREATE POLICY "Authenticated users can upload audio files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'audio'
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Users can update their audio files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'audio'
  AND auth.uid() = owner
)
WITH CHECK (
  bucket_id = 'audio'
  AND auth.uid() = owner
);

CREATE POLICY "Authenticated users can read audio files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'audio');

CREATE POLICY "Users can delete their audio files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'audio'
  AND auth.uid() = owner
);

-- PROJECT ICONS BUCKET POLICIES
CREATE POLICY "Authenticated users can upload project icons"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'project-icons'
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Project members can update project icons"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'project-icons'
  AND auth.uid() IS NOT NULL
)
WITH CHECK (
  bucket_id = 'project-icons'
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Public can read project icons"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'project-icons');

-- ============================================
-- PART 3: VERIFICATION
-- ============================================

-- Verify columns
SELECT '✅ PROJECTS TABLE COLUMNS:' as status;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'projects' 
ORDER BY ordinal_position;

SELECT '✅ SONGS TABLE COLUMNS:' as status;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'songs' 
ORDER BY ordinal_position;

SELECT '✅ SONG_VERSIONS TABLE COLUMNS:' as status;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'song_versions' 
ORDER BY ordinal_position;

-- Verify storage policies
SELECT '✅ STORAGE POLICIES:' as status;
SELECT 
  policyname,
  cmd,
  roles::text
FROM pg_policies 
WHERE tablename = 'objects'
AND schemaname = 'storage'
ORDER BY policyname;

SELECT '🎉 SETUP COMPLETE! Refresh your app and try again.' as final_message;
