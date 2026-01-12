<template>
  <div class="app-container">
    <!-- Show login view if not authenticated -->
    <LoginView v-if="!authLoading && !user" />

    <!-- Show main app if authenticated -->
    <template v-else-if="!authLoading && user">
      <header class="app-header">
        <div class="header-content">
          <div>
            <h1>🎵 Band Demos</h1>
            <p class="subtitle">Share and stream your music</p>
          </div>
          <div class="user-section">
            <span class="user-name">
              {{ user.user_metadata?.display_name || user.email }}
            </span>
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

        <div v-else-if="projects.length === 0" class="empty-state">
          <h3>📭 No Projects Yet</h3>
          <p>Start by creating your first project!</p>
        </div>

        <div v-else class="projects-grid">
          <div v-for="project in projects" :key="project.id" class="project-card">
            <h3>{{ project.name }}</h3>
            <div class="project-details">
              <p><strong>Invite Code:</strong> {{ project.invite_code }}</p>
              <p><strong>Members:</strong> {{ project.member_count || 0 }}</p>
              <p><strong>Created:</strong> {{ formatDate(project.created_at) }}</p>
            </div>
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
import { initSupabase, getSupabase } from './supabase.js';
import { useAuth } from './composables/useAuth.js';
import LoginView from './components/LoginView.vue';
import ProfileSettings from './components/ProfileSettings.vue';

const { user, loading: authLoading, initAuth } = useAuth();

const projects = ref([]);
const loading = ref(true);
const error = ref(null);
const showProfile = ref(false);

async function loadProjects() {
  try {
    loading.value = true;
    error.value = null;

    const supabase = getSupabase();

    // Fetch projects (without nested project_members to avoid RLS recursion)
    const { data, error: fetchError } = await supabase
      .from('projects')
      .select('id, name, invite_code, created_at')
      .order('created_at', { ascending: false });

    if (fetchError) {
      throw new Error(fetchError.message);
    }

    // Fetch member counts separately for each project
    if (data && data.length > 0) {
      const projectsWithCounts = await Promise.all(
        data.map(async (project) => {
          const { count } = await supabase
            .from('project_members')
            .select('*', { count: 'exact', head: true })
            .eq('project_id', project.id);
          
          return {
            ...project,
            member_count: count || 0
          };
        })
      );
      
      projects.value = projectsWithCounts;
    } else {
      projects.value = data || [];
    }
  } catch (err) {
    error.value = err.message;
    console.error('Error loading projects:', err);
  } finally {
    loading.value = false;
  }
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

// Watch for user changes and reload projects
watch(user, (newUser) => {
  if (newUser) {
    loadProjects();
  } else {
    projects.value = [];
  }
});

onMounted(async () => {
  // Supabase is already initialized in main.js
  await initAuth();
  
  if (user.value) {
    loadProjects();
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

.profile-button {
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

.profile-button:hover {
  transform: translateY(-2px);
}

.main-content {
  flex: 1;
  padding: 2rem;
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

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.project-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s, box-shadow 0.2s;
}

.project-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.project-card h3 {
  color: #333;
  margin-bottom: 1rem;
  font-size: 1.3rem;
}

.project-details {
  color: #666;
  font-size: 0.9rem;
}

.project-details p {
  margin: 0.5rem 0;
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
