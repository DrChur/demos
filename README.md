# 🎵 Band Demos - Music Collaboration Platform

A private music streaming and collaboration platform for bands to share song demos, add comments, create playlists, and collaborate on music projects.

## 🚀 Features

### Milestone 1 - Auth + Project Switching ✅
- **Magic Link Authentication**: Passwordless email-based login
- **Project Management**: Create, update, and delete projects
- **Project Switcher**: Easy navigation between multiple projects with visual icons
- **Invite System**: Share invite codes to add members to projects
- **Project Settings**: Manage project details, icons, and members

### Milestone 2 - Upload + Playback ✅
- **Audio Upload**: Upload WAV or MP3 files to projects
- **File Storage**: Secure cloud storage via Supabase
- **Song List**: Browse all songs in a project with metadata
- **Audio Player**: Full-featured in-browser playback with controls
- **Play History**: Track listening history per user
- **Conversion Ready**: Edge Function scaffold for WAV→MP3 conversion

### Coming Soon (Milestone 3)
- **Albums/Groups**: Organize song versions into albums
- **Comments**: Add comments to specific song versions
- **Recently Played**: Spotify-like "Recently Played" section
- **Version Control**: Track multiple versions of songs
- **Playlists**: Create and share custom playlists

## 🛠️ Tech Stack

- **Frontend**: Vue.js 3 (Composition API) + Vite
- **State Management**: Pinia
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Authentication**: Magic Link (OTP)
- **Storage**: Supabase Storage with RLS
- **Deployment**: Ready for Vercel/Netlify

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd demos
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure Supabase**
   ```bash
   cp public/config.json.example public/config.json
   ```
   
   Edit `public/config.json` with your Supabase credentials:
   ```json
   {
     "supabaseUrl": "https://your-project.supabase.co",
     "supabaseKey": "your-anon-key"
   }
   ```

4. **Set up database**
   - Go to your Supabase SQL Editor
   - Run `schema.sql`
   - Run `storage-setup.sql`

5. **Create storage buckets**
   In Supabase Dashboard → Storage:
   - Create `project-icons` bucket (public)
   - Create `audio` bucket (public)

6. **Start development server**
   ```bash
   npm run dev
   ```

Visit `http://localhost:3000` to see the app!

## 📁 Project Structure

```
demos/
├── src/
│   ├── components/
│   │   ├── AudioPlayer.vue          # Bottom sticky audio player
│   │   ├── JoinProjectModal.vue     # Join by invite code
│   │   ├── LoginView.vue            # Magic link login
│   │   ├── ProfileSettings.vue      # User profile management
│   │   ├── ProjectSettingsModal.vue # Project CRUD operations
│   │   ├── ProjectSwitcher.vue      # Project navigation dropdown
│   │   ├── SongList.vue             # Display project songs
│   │   └── UploadSongModal.vue      # Upload audio files
│   ├── composables/
│   │   └── useAuth.js               # Authentication composable
│   ├── stores/
│   │   └── projectStore.js          # Pinia project state
│   ├── App.vue                      # Main application
│   ├── main.js                      # App entry point
│   └── supabase.js                  # Supabase client
├── supabase/
│   └── functions/
│       └── convert-audio/           # Edge Function for conversion
├── public/
│   ├── config.json                  # Supabase config (gitignored)
│   └── config.json.example          # Config template
├── schema.sql                       # Database schema
├── storage-setup.sql                # Storage bucket policies
├── DEPLOYMENT.md                    # Deployment guide
└── package.json
```

## 🎮 Usage

### Creating a Project
1. Click on the project switcher in the header
2. Click "Create New Project"
3. Enter project name and optional icon
4. Project is created with you as owner

### Joining a Project
1. Get an invite code from a project member
2. Click "Join by Invite Code" in project switcher
3. Enter the code
4. You're added as a member!

### Uploading Songs
1. Switch to your project
2. Click "Upload Song" button
3. Select audio file (WAV or MP3)
4. Enter song title
5. Upload!

### Playing Music
1. Browse songs in the project
2. Click play button on any song
3. Use the bottom player to control playback
4. Enjoy your music!

## 🔧 Configuration

### Database Schema
The app uses PostgreSQL with Row Level Security (RLS):
- `projects` - Project information and invite codes
- `project_members` - User-project relationships
- `songs` - Audio files and metadata
- `song_versions` - Version history (future)
- `comments` - Comments on songs (future)
- `play_history` - Listening history

### Storage Buckets
- `project-icons` - Project avatar images
- `audio` - Song files (original and converted)

### Environment Variables
You can use environment variables instead of `config.json`:
```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

## 🚢 Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

Quick deploy to Vercel:
```bash
npm run build
vercel deploy
```

## 🔐 Security

- Row Level Security (RLS) enabled on all tables
- Storage policies restrict access to project members
- Magic link authentication (no passwords to leak)
- Service role key kept secure (never in client code)

## 🐛 Troubleshooting

**Songs won't upload**
- Check storage bucket exists and is public
- Verify RLS policies are applied
- Check file size limits

**Can't see other members' songs**
- Ensure you're a member of the project
- Check RLS policies on songs table
- Verify project_members has correct entries

**Audio won't play**
- Check bucket permissions
- Verify file URLs are accessible
- Check browser console for errors

## 🗺️ Roadmap

- [ ] Song versioning system
- [ ] Comments on songs
- [ ] Albums/grouping functionality
- [ ] Recently played section
- [ ] Playlist creation
- [ ] Mobile app (React Native)
- [ ] Real-time collaboration
- [ ] Waveform visualization
- [ ] Social features (likes, shares)

## 📝 License

Private project - All rights reserved

## 🤝 Contributing

This is a private project for band collaboration. Contact the repository owner for access.

## 📧 Support

For issues or questions, please contact the development team.

---

Built with ❤️ by music lovers, for music lovers.
