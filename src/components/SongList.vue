<template>
  <div class="song-list-container">
    <div class="song-list-header">
      <h3>Songs</h3>
      <button @click="showUploadModal = true" class="upload-button">
        ➕ Upload Song
      </button>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading songs...</p>
    </div>

    <div v-else-if="error" class="error-state">
      <p>{{ error }}</p>
    </div>

    <div v-else-if="songs.length === 0" class="empty-state">
      <div class="empty-icon">🎵</div>
      <p>No songs yet</p>
      <p class="hint">Upload your first song to get started!</p>
    </div>

    <div v-else class="songs-table">
      <table>
        <thead>
          <tr>
            <th class="col-play"></th>
            <th class="col-title">Title</th>
            <th class="col-duration">Duration</th>
            <th class="col-size">Size</th>
            <th class="col-uploaded">Uploaded</th>
            <th class="col-actions"></th>
          </tr>
        </thead>
        <tbody>
          <tr 
            v-for="song in songs" 
            :key="song.id" 
            class="song-row"
            :class="{ playing: currentSong?.id === song.id }"
          >
            <td class="col-play">
              <button @click="handlePlaySong(song)" class="play-button">
                <span v-if="currentSong?.id === song.id && isPlaying">⏸</span>
                <span v-else>▶</span>
              </button>
            </td>
            <td class="col-title">
              <div class="song-title">{{ song.title }}</div>
            </td>
            <td class="col-duration">
              {{ formatDuration(song.duration) }}
            </td>
            <td class="col-size">
              {{ formatFileSize(song.file_size) }}
            </td>
            <td class="col-uploaded">
              {{ formatDate(song.created_at) }}
            </td>
            <td class="col-actions">
              <button @click="handleDeleteSong(song.id)" class="delete-button" title="Delete song">
                🗑️
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Upload Modal -->
    <UploadSongModal 
      v-if="showUploadModal"
      @close="showUploadModal = false"
      @success="handleUploadSuccess"
    />

    <!-- Delete Confirmation -->
    <Teleport to="body">
      <div v-if="showDeleteConfirm" class="modal-overlay" @click="showDeleteConfirm = false">
        <div class="confirm-modal" @click.stop>
          <h4>Delete Song?</h4>
          <p>This action cannot be undone. The song file and all its data will be permanently deleted.</p>
          <div class="confirm-actions">
            <button @click="showDeleteConfirm = false" class="modal-button cancel">
              Cancel
            </button>
            <button @click="confirmDelete" class="modal-button delete-confirm" :disabled="deleting">
              {{ deleting ? 'Deleting...' : 'Delete Song' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { getSupabase } from '../supabase.js';
import { useProjectStore } from '../stores/projectStore.js';
import { storeToRefs } from 'pinia';
import UploadSongModal from './UploadSongModal.vue';

const props = defineProps({
  currentSong: {
    type: Object,
    default: null
  },
  isPlaying: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['play-song', 'pause-song']);

const projectStore = useProjectStore();
const { activeProject } = storeToRefs(projectStore);
const supabase = getSupabase();

const songs = ref([]);
const loading = ref(false);
const error = ref(null);
const showUploadModal = ref(false);
const showDeleteConfirm = ref(false);
const songToDelete = ref(null);
const deleting = ref(false);

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

    songs.value = data || [];
  } catch (err) {
    error.value = err.message;
    console.error('Error loading songs:', err);
  } finally {
    loading.value = false;
  }
}

function handlePlaySong(song) {
  if (props.currentSong?.id === song.id && props.isPlaying) {
    emit('pause-song');
  } else {
    emit('play-song', song);
  }
}

function handleDeleteSong(songId) {
  songToDelete.value = songId;
  showDeleteConfirm.value = true;
}

async function confirmDelete() {
  if (!songToDelete.value) return;

  try {
    deleting.value = true;

    // Find song to get file path
    const song = songs.value.find(s => s.id === songToDelete.value);
    if (!song) throw new Error('Song not found');

    // Delete from database (this will trigger cascade delete for related records)
    const { error: dbError } = await supabase
      .from('songs')
      .delete()
      .eq('id', songToDelete.value);

    if (dbError) throw dbError;

    // Delete from storage
    // Extract path from URL
    const url = new URL(song.file_url);
    const pathMatch = url.pathname.match(/\/audio\/(.+)/);
    if (pathMatch) {
      const filePath = pathMatch[1];
      await supabase.storage
        .from('audio')
        .remove([filePath]);
    }

    // Remove from local list
    songs.value = songs.value.filter(s => s.id !== songToDelete.value);

    showDeleteConfirm.value = false;
    songToDelete.value = null;
  } catch (err) {
    error.value = err.message;
    console.error('Error deleting song:', err);
  } finally {
    deleting.value = false;
  }
}

function handleUploadSuccess() {
  loadSongs();
}

function formatDuration(seconds) {
  if (!seconds) return '--:--';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function formatFileSize(bytes) {
  if (!bytes) return '--';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function formatDate(dateString) {
  if (!dateString) return '--';
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

// Watch for active project changes
watch(activeProject, () => {
  loadSongs();
}, { immediate: true });

onMounted(() => {
  loadSongs();
});
</script>

<style scoped>
.song-list-container {
  width: 100%;
}

.song-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.song-list-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.5rem;
}

.upload-button {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.upload-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.loading-state, .error-state, .empty-state {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e0e0e0;
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-state .hint {
  color: #999;
  font-size: 0.9rem;
  margin-top: 0.5rem;
}

.songs-table {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

table {
  width: 100%;
  border-collapse: collapse;
}

thead {
  background: #f8f9fa;
}

th {
  padding: 1rem;
  text-align: left;
  font-weight: 600;
  color: #666;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.col-play {
  width: 60px;
  text-align: center;
}

.col-title {
  min-width: 200px;
}

.col-duration {
  width: 100px;
}

.col-size {
  width: 100px;
}

.col-uploaded {
  width: 120px;
}

.col-actions {
  width: 80px;
  text-align: center;
}

.song-row {
  border-bottom: 1px solid #e0e0e0;
  transition: background 0.2s;
}

.song-row:hover {
  background: #f8f9fa;
}

.song-row.playing {
  background: #f0f4ff;
}

td {
  padding: 1rem;
  color: #333;
  font-size: 0.95rem;
}

.play-button {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
  transition: all 0.2s;
  margin: 0 auto;
}

.play-button:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.song-title {
  font-weight: 600;
}

.delete-button {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  opacity: 0.6;
  transition: all 0.2s;
  padding: 0.5rem;
}

.delete-button:hover {
  opacity: 1;
  transform: scale(1.2);
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 1rem;
}

.confirm-modal {
  background: white;
  border-radius: 16px;
  padding: 2rem;
  max-width: 450px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.confirm-modal h4 {
  margin: 0 0 1rem 0;
  color: #d32f2f;
  font-size: 1.3rem;
}

.confirm-modal p {
  color: #666;
  margin-bottom: 1.5rem;
  line-height: 1.6;
}

.confirm-actions {
  display: flex;
  gap: 0.75rem;
}

.modal-button {
  flex: 1;
  padding: 0.9rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.modal-button.cancel {
  background: #f5f5f5;
  color: #666;
}

.modal-button.cancel:hover {
  background: #e0e0e0;
}

.modal-button.delete-confirm {
  background: #d32f2f;
  color: white;
}

.modal-button.delete-confirm:hover:not(:disabled) {
  background: #b71c1c;
  transform: translateY(-2px);
}

.modal-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Responsive */
@media (max-width: 768px) {
  .col-size, .col-uploaded {
    display: none;
  }
}
</style>
