# Fix Audio Streaming Issue

## Problem
Error: `NotSupportedError: The element has no supported sources`

This happens because the `audio` storage bucket is not public, so the browser cannot access the audio files.

## Solution - Option 1: Make Audio Bucket Public (Recommended)

This is the simplest solution for streaming audio files.

### Steps:

1. Go to [Supabase Storage Dashboard](https://swsfsvyfjhwdpomyhxet.supabase.co/project/_/storage/buckets)
2. Find the `audio` bucket
3. Click the three dots (⋮) menu next to it
4. Click **"Edit bucket"**
5. Check the box for **"Public bucket"**
6. Click **"Save"**
7. Refresh your app and try playing a song ✅

### Why This Works:
- Public buckets allow direct URL access to files
- The browser can stream audio directly using `<audio src="url">`
- Still respects RLS policies for upload/delete operations

---

## Solution - Option 2: Use Signed URLs (More Secure)

If you want to keep the bucket private and use authenticated access:

### Steps:

1. Keep the `audio` bucket as **private**
2. Apply the code changes below to generate signed URLs

### Code Changes Required:

**Update `src/components/SongList.vue`** - Add signed URL generation when loading songs:

```javascript
async function loadSongs() {
  if (!activeProject.value) return;

  try {
    loading.value = true;
    error.value = null;

    const { data, error: fetchError } = await supabase
      .from('songs')
      .select('*')
      .eq('project_id', activeProject.value.id)
      .order('created_at', { ascending: false });

    if (fetchError) throw fetchError;

    // Generate signed URLs for each song
    const songsWithSignedUrls = await Promise.all(
      (data || []).map(async (song) => {
        // Extract storage path from public URL
        const pathMatch = song.file_url.match(/audio\/(.+)$/);
        if (pathMatch) {
          const path = pathMatch[1];
          const { data: signedUrlData } = await supabase.storage
            .from('audio')
            .createSignedUrl(path, 3600); // 1 hour expiry
          
          return {
            ...song,
            file_url: signedUrlData?.signedUrl || song.file_url
          };
        }
        return song;
      })
    );

    songs.value = songsWithSignedUrls;
  } catch (err) {
    error.value = err.message;
    console.error('Error loading songs:', err);
  } finally {
    loading.value = false;
  }
}
```

### Pros and Cons:

**Public Bucket:**
- ✅ Simple, direct streaming
- ✅ No URL expiration issues
- ✅ Better for public music demos
- ⚠️ Anyone with the URL can access files

**Signed URLs:**
- ✅ More secure, authenticated access only
- ✅ URLs expire after set time
- ⚠️ More complex implementation
- ⚠️ Need to refresh URLs periodically

---

## Recommended: Public Bucket

For a band demo sharing app, making the `audio` bucket **public** is the best approach:
- Simpler implementation
- Better streaming performance
- You still control who can upload/delete via RLS policies
- Users who know project members can already access via invite codes

Just make sure the `project-icons` bucket is also public for project icons to display.
