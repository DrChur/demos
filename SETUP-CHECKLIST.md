# 🎯 Setup Checklist

Follow this checklist to get your Band Demos app up and running.

## ✅ Pre-Development Setup (One-time)

### 1. Supabase Project Setup
- [ ] Create Supabase account at https://supabase.com
- [ ] Create a new project
- [ ] Note down your project URL and anon key

### 2. Database Configuration
- [ ] Go to SQL Editor in Supabase Dashboard
- [ ] Copy and run `schema.sql` (creates tables and RLS policies)
- [ ] Copy and run `storage-setup.sql` (creates storage policies)

### 3. Storage Buckets
- [ ] Go to Storage in Supabase Dashboard
- [ ] Create bucket: `project-icons` (set as public)
- [ ] Create bucket: `audio` (set as public)

### 4. Application Configuration
- [ ] Copy `public/config.json.example` to `public/config.json`
- [ ] Edit `public/config.json` with your Supabase credentials:
  ```json
  {
    "supabaseUrl": "YOUR_SUPABASE_URL",
    "supabaseKey": "YOUR_SUPABASE_ANON_KEY"
  }
  ```

### 5. Dependencies
- [ ] Run `npm install` in project directory
- [ ] Verify Pinia is installed (should be in package.json)

## 🚀 Running the App

### Development Mode
```bash
npm run dev
```
App will be available at http://localhost:3000

### First Time Usage
1. [ ] Open the app in browser
2. [ ] Enter your email address
3. [ ] Check email for magic link
4. [ ] Click the magic link to authenticate
5. [ ] Create your first project!

## 🧪 Testing Checklist

### Authentication
- [ ] Can send magic link email
- [ ] Can click magic link and login
- [ ] User stays logged in after refresh
- [ ] Can logout from profile settings

### Project Management
- [ ] Can create new project
- [ ] Can add project icon
- [ ] Project appears in switcher
- [ ] Can switch between projects
- [ ] Dashboard updates when switching

### Invite System
- [ ] Can copy invite code from project settings
- [ ] Can join project using invite code
- [ ] New member can see project in switcher
- [ ] New member can access project songs

### Audio Upload
- [ ] Can upload MP3 file
- [ ] Can upload WAV file
- [ ] File appears in song list
- [ ] Song metadata displays correctly
- [ ] Can see file size and duration

### Audio Playback
- [ ] Can click play on song
- [ ] Audio player appears at bottom
- [ ] Can pause/resume playback
- [ ] Progress bar updates during playback
- [ ] Can seek within song
- [ ] Volume control works
- [ ] Song auto-advances (if playlist)

### Project Settings
- [ ] Can update project name
- [ ] Can update project icon
- [ ] Can see project members
- [ ] Can copy invite code
- [ ] Can delete project (with confirmation)

### Song Management
- [ ] Songs display in table format
- [ ] Can sort/filter songs (if implemented)
- [ ] Can delete songs
- [ ] Deleted songs removed from storage

## 🐛 Common Issues & Fixes

### "Failed to load Supabase configuration"
**Fix:** Ensure `public/config.json` exists with correct credentials

### "Row Level Security policy violation"
**Fix:** Run `schema.sql` and `storage-setup.sql` in Supabase SQL Editor

### Songs won't upload
**Fix:** 
- Check storage buckets exist
- Verify bucket permissions are public
- Check file size limits in Supabase settings

### Audio won't play
**Fix:**
- Verify audio bucket is public
- Check browser console for CORS errors
- Test file URL directly in browser

### Can't see other members' projects
**Fix:**
- Ensure you're added to `project_members` table
- Check RLS policies are correctly applied
- Verify project_id and user_id match

## 📊 Database Quick Check

Run this in Supabase SQL Editor to verify setup:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('projects', 'project_members', 'songs', 'song_versions', 'comments', 'play_history');

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check your user's projects
SELECT p.id, p.name, pm.role 
FROM projects p
JOIN project_members pm ON p.id = pm.project_id
WHERE pm.user_id = auth.uid();
```

## 🔧 Advanced Configuration

### Edge Function (Optional - for WAV conversion)
- [ ] Install Supabase CLI: `npm install -g supabase`
- [ ] Link project: `supabase link --project-ref YOUR_PROJECT_REF`
- [ ] Deploy function: `supabase functions deploy convert-audio`

Note: Current Edge Function is a placeholder. See `supabase/functions/convert-audio/README.md` for production implementation options.

### Custom Domain (Production)
- [ ] Deploy to Vercel/Netlify
- [ ] Configure custom domain
- [ ] Update Supabase authentication URLs
- [ ] Test magic link redirects

### Email Templates
- [ ] Customize magic link email in Supabase Dashboard
- [ ] Update branding and colors
- [ ] Test email delivery

## 📝 Next Steps

After successful setup:

1. **Invite your band members** - Share project invite codes
2. **Upload your demos** - Start with MP3 for simplicity
3. **Organize your music** - Create clear naming conventions
4. **Plan Milestone 3** - Albums, comments, playlists

## 🆘 Need Help?

If you encounter issues:
1. Check this checklist again
2. Review browser console for errors
3. Check Supabase logs for API errors
4. Verify RLS policies in database
5. Test with a fresh incognito window

## ✨ Success Indicators

You're ready to go when:
- ✅ You can login with magic link
- ✅ You can create and switch projects
- ✅ You can upload and play songs
- ✅ Other users can join via invite code
- ✅ Audio player works smoothly

Happy collaborating! 🎸🎹🥁
