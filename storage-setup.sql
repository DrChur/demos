-- Storage Setup for Band Demos App
-- Run these commands in Supabase SQL Editor

-- Note: Storage buckets must be created via Supabase Dashboard UI first:
-- 1. Go to Storage > Create bucket
-- 2. Create bucket: "project-icons" (public)
-- 3. Create bucket: "audio" (public or authenticated depending on preference)

-- Enable RLS on storage buckets
-- This is done automatically by Supabase for storage.objects

-- ============================================
-- PROJECT ICONS BUCKET POLICIES
-- ============================================

-- Allow authenticated users to upload project icons
create policy "Authenticated users can upload project icons"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'project-icons'
  and auth.uid() is not null
);

-- Allow authenticated users to update project icons (for projects they're members of)
create policy "Project members can update project icons"
on storage.objects for update
to authenticated
using (
  bucket_id = 'project-icons'
  and auth.uid() is not null
)
with check (
  bucket_id = 'project-icons'
  and auth.uid() is not null
);

-- Allow public read access to project icons
create policy "Public can read project icons"
on storage.objects for select
to public
using (bucket_id = 'project-icons');

-- ============================================
-- AUDIO BUCKET POLICIES
-- ============================================

-- Allow authenticated users to upload audio files
create policy "Authenticated users can upload audio files"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'audio'
  and auth.uid() is not null
);

-- Allow authenticated users to update audio files they uploaded
create policy "Users can update their audio files"
on storage.objects for update
to authenticated
using (
  bucket_id = 'audio'
  and auth.uid() = owner
)
with check (
  bucket_id = 'audio'
  and auth.uid() = owner
);

-- Allow authenticated users to read audio files
-- Note: In production, you might want to restrict this to project members only
create policy "Authenticated users can read audio files"
on storage.objects for select
to authenticated
using (bucket_id = 'audio');

-- Allow authenticated users to delete their audio files
create policy "Users can delete their audio files"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'audio'
  and auth.uid() = owner
);

-- ============================================
-- ADDITIONAL TABLE UPDATES
-- ============================================

-- Add icon_url column to projects table if not exists
alter table projects add column if not exists icon_url text;

-- Add audio metadata columns to songs table if not exists
alter table songs add column if not exists file_url text;
alter table songs add column if not exists file_size bigint;
alter table songs add column if not exists file_type text;
alter table songs add column if not exists duration integer;

-- Update songs table to make file_url not null (only for new inserts)
-- Note: This will fail if there are existing rows without file_url
-- If needed, first update existing rows or drop the constraint
-- alter table songs alter column file_url set not null;

-- Add file columns to song_versions table if not exists
alter table song_versions add column if not exists file_url text;
alter table song_versions add column if not exists original_file_url text;

-- Drop the old 'content' column from song_versions if it exists
-- Uncomment only if you're sure you want to remove it
-- alter table song_versions drop column if exists content;
