<template>
  <div class="app-container">
    <!-- Show login view if not authenticated -->
    <LoginView v-if="!authLoading && !user" />

    <!-- Show main app if authenticated -->
    <template v-else-if="!authLoading && user">
      <header class="app-header">
        <div class="header-content">
          <div class="left-section">
            <ProjectSwitcher v-if="hasProjects" />
            <div v-else>
              <h1>🎵 Band Demos</h1>
              <p class="subtitle">Share and stream your music</p>
            </div>
          </div>
          <div class="user-section">
            <span class="user-name">
              {{ user.user_metadata?.display_name || user.email }}
            </span>
            <button 
              v-if="activeProject"
              @click="showSettings = true" 
              class="settings-button"
            >
              ⚙️ Settings
            </button>
            <button @click="showProfile = true" class="profile-button">
              👤 Profile
            </button>
          </div>
        </div>
      </header>

      <main class="main-content">
        <div v-if="loading" class="loading">
          <div class="spinner"></div>
          <p>Loading projects...</p>
        </div>

        <div v-else-if="error" class="error-message">
          <h3>⚠️ Error</h3>
          <p>{{ error }}</p>
          <p class="hint">Make sure your config.json is set up correctly.</p>
        </div>

        <div v-else-if="!hasProjects" class="empty-state">
          <h3>📭 No Projects Yet</h3>
          <p>Create a new project or join one using an invite code.</p>
        </div>

        <div v-else-if="activeProject" class="project-dashboard">
          <div class="dashboard-header">
            <h2>{{ activeProject.name }}</h2>
            <p class="dashboard-subtitle">{{ activeProject.member_count || 0 }} members</p>
          </div>
          
          <div class="dashboard-content">
            <SongList 
              :current-song="currentSong"
              :is-playing="isPlaying"
              @play-song="handlePlaySong"
              @pause-song="handlePauseSong"
            />
          </div>
        </div>
      </main>

      <footer class="app-footer">
        <p>Connected to Supabase ✅ • Signed in as {{ user.email }}</p>
      </footer>

      <!-- Profile Settings Modal -->
      <ProfileSettings 
        v-if="showProfile" 
        :user="user" 
        @close="showProfile = false"
      />

      <!-- Project Settings Modal -->
      <ProjectSettingsModal
        v-if="showSettings && activeProject"
        :project="activeProject"
        @close="showSettings = false"
      />

      <!-- Audio Player -->
      <AudioPlayer 
        v-if="currentSong"
        ref="audioPlayerRef"
        :current-song="currentSong"
        :playlist="[]"
        @song-change="handleSongChange"
        @playing-change="handlePlayingChange"
      />
    </template>

    <!-- Loading state during auth check -->
    <div v-else class="auth-loading">
      <div class="spinner"></div>
      <p>Checking authentication...</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useAuth } from './composables/useAuth.js';
import { useProjectStore } from './stores/projectStore.js';
import { storeToRefs } from 'pinia';
import LoginView from './components/LoginView.vue';
import ProfileSettings from './components/ProfileSettings.vue';
import ProjectSwitcher from './components/ProjectSwitcher.vue';
import ProjectSettingsModal from './components/ProjectSettingsModal.vue';
import SongList from './components/SongList.vue';
import AudioPlayer from './components/AudioPlayer.vue';

const { user, loading: authLoading, initAuth } = useAuth();
const projectStore = useProjectStore();
const { projects, activeProject, loading, error, hasProjects } = storeToRefs(projectStore);

const showProfile = ref(false);
const showSettings = ref(false);

const audioPlayerRef = ref(null);
const currentSong = ref(null);
const isPlaying = ref(false);

function handlePlaySong(song) {
  // If it's the same song, just resume playback
  if (currentSong.value?.id === song.id) {
    isPlaying.value = true;
    // Resume playback on the existing audio element
    if (audioPlayerRef.value?.audioElement) {
      audioPlayerRef.value.audioElement.play().catch(err => {
        console.error('Error resuming playback:', err);
      });
    }
  } else {
    // Different song - let the watch handler take care of it
    currentSong.value = song;
    isPlaying.value = true;
  }
}

function handlePauseSong() {
  isPlaying.value = false;
  // Actually pause the audio element
  if (audioPlayerRef.value?.audioElement) {
    audioPlayerRef.value.audioElement.pause();
  }
}

function handleSongChange(song) {
  currentSong.value = song;
}

function handlePlayingChange(playing) {
  isPlaying.value = playing;
}

// Watch for user changes and reload projects
watch(user, (newUser) => {
  if (newUser) {
    projectStore.loadProjects();
  }
});

onMounted(async () => {
  await initAuth();
  
  if (user.value) {
    await projectStore.loadProjects();
    projectStore.initFromStorage();
  }
});
</script>

<style scoped>
.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  padding: 1.5rem 2rem;
  box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  flex-wrap: wrap;
  gap: 1rem;
}

.left-section {
  flex: 1;
}

.app-header h1 {
  font-size: 2rem;
  color: #333;
  margin-bottom: 0.25rem;
}

.subtitle {
  color: #666;
  font-size: 1rem;
}

.user-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-name {
  color: #666;
  font-size: 0.9rem;
}

.profile-button, .settings-button {
  padding: 0.6rem 1.2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: transform 0.2s;
  white-space: nowrap;
}

.profile-button:hover, .settings-button:hover {
  transform: translateY(-2px);
}

.settings-button {
  background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
}

.main-content {
  flex: 1;
  padding: 2rem;
  padding-bottom: 120px; /* Space for audio player */
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: white;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 2rem;
  text-align: center;
  color: #d32f2f;
}

.error-message .hint {
  margin-top: 1rem;
  color: #666;
  font-size: 0.9rem;
}

.empty-state {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 3rem;
  text-align: center;
  color: #666;
}

.project-dashboard {
  width: 100%;
}

.dashboard-header {
  margin-bottom: 2rem;
  text-align: center;
}

.dashboard-header h2 {
  color: #333;
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.dashboard-subtitle {
  color: #666;
  font-size: 1rem;
}

.dashboard-content {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 2rem;
  min-height: 400px;
}

.placeholder-content {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.placeholder-content .hint {
  font-size: 0.85rem;
  color: #999;
  margin-top: 0.5rem;
}

.app-footer {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  padding: 1rem;
  text-align: center;
  color: white;
  font-size: 0.9rem;
}

.auth-loading {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: white;
}
</style>
