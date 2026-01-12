# Band Demos App - Deployment Guide

This guide covers the steps needed to deploy and configure the Band Demos application.

## Prerequisites

- Node.js 16+ installed
- Supabase account and project created
- Supabase CLI installed: `npm install -g supabase`

## Step 1: Database Setup

1. Copy the contents of `schema.sql` to your Supabase SQL Editor and execute it
2. Copy the contents of `storage-setup.sql` to your Supabase SQL Editor and execute it

## Step 2: Storage Configuration

### Create Storage Buckets

In your Supabase Dashboard (Storage section):

1. **Create `project-icons` bucket:**
   - Name: `project-icons`
   - Public: Yes
   - File size limit: 5MB (recommended)
   - Allowed MIME types: `image/*`

2. **Create `audio` bucket:**
   - Name: `audio`
   - Public: Yes (or Authenticated based on preference)
   - File size limit: 100MB (or higher based on needs)
   - Allowed MIME types: `audio/wav, audio/mpeg, audio/mp3`

### Apply Storage Policies

The RLS policies in `storage-setup.sql` will automatically secure your buckets.

## Step 3: Configure Application

1. Copy `public/config.json.example` to `public/config.json`:
   ```bash
   cp public/config.json.example public/config.json
   ```

2. Update `public/config.json` with your Supabase credentials:
   ```json
   {
     "supabaseUrl": "https://your-project.supabase.co",
     "supabaseKey": "your-anon-key"
   }
   ```

3. Add `public/config.json` to `.gitignore` (already done)

## Step 4: Install Dependencies

```bash
npm install
```

## Step 5: Run Development Server

```bash
npm run dev
```

The app should now be running at `http://localhost:3000`

## Step 6: Edge Function Deployment (Optional)

The WAV to MP3 conversion Edge Function is optional for the MVP. To deploy it:

1. Link your Supabase project:
   ```bash
   supabase link --project-ref your-project-ref
   ```

2. Deploy the function:
   ```bash
   supabase functions deploy convert-audio
   ```

3. See `supabase/functions/convert-audio/README.md` for implementation details

**Note:** The current Edge Function is a placeholder. For production, implement actual audio conversion using one of the methods described in the README.

## Step 7: Production Deployment

### Deploy to Vercel, Netlify, or similar:

1. Build the application:
   ```bash
   npm run build
   ```

2. Deploy the `dist` folder to your hosting platform

3. Ensure `public/config.json` is created on the server with production credentials (or use environment variables)

### Environment Variables (Alternative to config.json)

Instead of `config.json`, you can use environment variables:

1. Update `src/supabase.js` to read from `import.meta.env`:
   ```javascript
   const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
   const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
   ```

2. Set environment variables in your hosting platform:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

## Testing Checklist

- [ ] User can sign up/login with magic link email
- [ ] User can create a new project
- [ ] User can join a project using invite code
- [ ] Project switcher shows all user projects
- [ ] User can upload project icon
- [ ] User can update project name
- [ ] User can upload audio files (MP3)
- [ ] Songs display in project dashboard
- [ ] Audio player plays songs
- [ ] Play history is recorded
- [ ] User can delete songs
- [ ] User can delete projects

## Troubleshooting

### "Failed to load Supabase configuration"
- Ensure `public/config.json` exists and contains valid credentials
- Check that the Supabase URL and key are correct

### "Row Level Security policy violation"
- Ensure all RLS policies from `schema.sql` and `storage-setup.sql` are applied
- Check that you're authenticated when performing operations

### Songs won't play
- Ensure the `audio` bucket is public or accessible to authenticated users
- Check browser console for CORS errors
- Verify the file URLs are accessible

### Upload fails
- Check bucket permissions in Supabase Dashboard
- Verify file size limits
- Ensure storage policies are correctly applied

## Next Steps

After deployment, consider:

1. Implementing actual audio conversion (see Edge Function README)
2. Adding song versioning functionality
3. Implementing comments system
4. Adding playlist features
5. Creating "Recently Played" section
6. Optimizing for mobile devices
