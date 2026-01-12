# Quick Fixes for Common Setup Issues

## ⚡ FASTEST FIX - Run Complete Setup (Recommended)

If you're encountering multiple errors, run this **ONE** migration to fix everything:

1. Go to [Supabase SQL Editor](https://swsfsvyfjhwdpomyhxet.supabase.co/project/_/sql)
2. Copy the contents of `migrations/complete-setup.sql`
3. Paste and run
4. Wait for "🎉 SETUP COMPLETE!" message
5. Refresh your app

This will:
- ✅ Add `icon_url` to projects table
- ✅ Add audio columns (`file_url`, `file_size`, `file_type`, `duration`) to songs table
- ✅ Add file columns to song_versions table
- ✅ Create all storage bucket policies
- ✅ Verify everything is set up correctly

**Then refresh your browser and everything should work!**

---

## Individual Fixes (If You Prefer Step-by-Step)

## Issue 1: Missing icon_url Column

### Problem
The `icon_url` column is missing from your Supabase `projects` table, causing the app to fail when loading projects.

### Solution

### Step 1: Apply the Migration

1. Open your Supabase Dashboard: https://swsfsvyfjhwdpomyhxet.supabase.co
2. Navigate to **SQL Editor** (in the left sidebar)
3. Click **New Query**
4. Copy and paste the contents of `migrations/add-icon-url-column.sql`
5. Click **Run** or press `Cmd/Ctrl + Enter`

### Step 2: Verify the Fix

After running the migration, you should see output showing all columns in the `projects` table, including the new `icon_url` column.

### Step 3: Reload Your App

Refresh your browser and the error should be gone!

## Alternative: One-Line Fix

If you prefer a quick one-liner, run this in the Supabase SQL Editor:

```sql
ALTER TABLE projects ADD COLUMN IF NOT EXISTS icon_url text;
```

## What This Does

- Adds the `icon_url` column to your existing `projects` table
- Preserves all existing data
- Sets the column to allow NULL values (existing projects will have NULL icons)
- Does not fail if the column already exists

## After the Fix

Once applied, you'll be able to:
- Upload project icons through the Project Settings modal
- See project icons in the Project Switcher
- Update and delete project icons

---

## Issue 2: Audio Upload Fails with RLS Policy Error

### Problem
Error: `StorageApiError: new row violates row-level security policy`

This happens when trying to upload audio files because the storage bucket policies haven't been created yet.

### Solution

#### Step 1: Ensure Storage Buckets Exist

1. Go to [Supabase Dashboard > Storage](https://swsfsvyfjhwdpomyhxet.supabase.co/project/_/storage/buckets)
2. Verify these buckets exist:
   - **audio** (set to public)
   - **project-icons** (set to public)
3. If they don't exist, create them:
   - Click "New bucket"
   - Name: `audio`
   - Public bucket: ✓ Yes
   - Click "Create bucket"
   - Repeat for `project-icons`

#### Step 2: Apply Storage Policies

1. Go to [Supabase SQL Editor](https://swsfsvyfjhwdpomyhxet.supabase.co/project/_/sql)
2. Open the file `migrations/fix-audio-upload.sql`
3. Copy all its contents
4. Paste into SQL Editor and run

**OR** use the complete setup:

1. Copy contents of `storage-setup.sql`
2. Paste and run in SQL Editor

#### Step 3: Verify Policies

After running the migration, you should see several policies created for the `storage.objects` table. The verification query at the end will show all policies.

#### Step 4: Test Upload

1. Refresh your app
2. Try uploading an audio file again
3. ✅ It should work now!

### What This Does

- Creates RLS policies for the `audio` bucket allowing authenticated users to:
  - ✅ Upload audio files
  - ✅ Read audio files
  - ✅ Update their own audio files
  - ✅ Delete their own audio files
- Creates RLS policies for the `project-icons` bucket allowing:
  - ✅ Authenticated users to upload/update icons
  - ✅ Public read access to icons

---

## Issue 3: Audio Files Won't Stream / Play

### Problem
Error: `NotSupportedError: The element has no supported sources`

Audio files upload successfully but won't play because the `audio` storage bucket is not public.

### Quick Fix

1. Go to [Supabase Storage](https://swsfsvyfjhwdpomyhxet.supabase.co/project/_/storage/buckets)
2. Find the `audio` bucket
3. Click the menu (⋮) → **"Edit bucket"**
4. Check **"Public bucket"** ✓
5. Click **"Save"**
6. Also check that `project-icons` bucket is public
7. Refresh your app and try playing a song ✅

### Why This Is Needed

- The browser's `<audio>` element needs direct URL access to stream files
- Public buckets allow this while still respecting RLS policies for upload/delete
- For a band demo app, public audio is appropriate (anyone with invite can access anyway)

See `migrations/fix-audio-streaming.md` for alternative solutions using signed URLs if you prefer private buckets.

---

## Issue 4: Missing Audio Columns in Songs Table

### Problem
Error: `Could not find the 'duration' column of 'songs' in the schema cache`

This happens when trying to upload songs because the `songs` table is missing the audio metadata columns.

### Solution

1. Go to [Supabase SQL Editor](https://swsfsvyfjhwdpomyhxet.supabase.co/project/_/sql)
2. Copy contents of `migrations/add-audio-columns.sql`
3. Paste and run

**OR** use the complete setup migration above (recommended).

### What This Does

Adds these columns to the `songs` table:
- `file_url` (text) - Path to audio file in storage
- `file_size` (bigint) - File size in bytes
- `file_type` (text) - MIME type (audio/wav, audio/mpeg)
- `duration` (integer) - Duration in seconds

Also adds these columns to `song_versions` table:
- `file_url` (text) - Path to streaming file
- `original_file_url` (text) - Path to original file

---

## Complete Setup (If You Haven't Run Any Migrations Yet)

If this is your first time setting up the database, run these in order:

1. **Database Schema**: Copy and run `schema.sql`
2. **Storage Policies**: Copy and run `storage-setup.sql`
3. **Create Storage Buckets** in Supabase Dashboard (audio, project-icons)

Then refresh your app!
