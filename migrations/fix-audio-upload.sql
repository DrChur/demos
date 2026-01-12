-- Migration: Fix audio upload RLS policies
-- This enables authenticated users to upload, read, update, and delete audio files

-- First, check if buckets exist
-- You must create these buckets in the Supabase Dashboard > Storage first:
-- 1. project-icons (public)
-- 2. audio (public)

-- ============================================
-- AUDIO BUCKET POLICIES
-- ============================================

-- Drop existing policies if they exist (to avoid conflicts)
drop policy if exists "Authenticated users can upload audio files" on storage.objects;
drop policy if exists "Users can update their audio files" on storage.objects;
drop policy if exists "Authenticated users can read audio files" on storage.objects;
drop policy if exists "Users can delete their audio files" on storage.objects;

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
-- PROJECT ICONS BUCKET POLICIES
-- ============================================

-- Drop existing policies if they exist
drop policy if exists "Authenticated users can upload project icons" on storage.objects;
drop policy if exists "Project members can update project icons" on storage.objects;
drop policy if exists "Public can read project icons" on storage.objects;

-- Allow authenticated users to upload project icons
create policy "Authenticated users can upload project icons"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'project-icons'
  and auth.uid() is not null
);

-- Allow authenticated users to update project icons
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

-- Verify policies were created
select 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
from pg_policies 
where tablename = 'objects'
order by policyname;
