<template>
  <div v-if="currentSong" class="audio-player">
    <audio
      ref="audioElement"
      :src="currentSong.file_url"
      @timeupdate="handleTimeUpdate"
      @loadedmetadata="handleLoadedMetadata"
      @ended="handleEnded"
      @play="isPlaying = true"
      @pause="isPlaying = false"
    ></audio>

    <div class="player-content">
      <div class="song-info">
        <div class="song-details">
          <div class="song-title">{{ currentSong.title }}</div>
          <div class="song-meta">{{ formatDuration(currentTime) }} / {{ formatDuration(duration) }}</div>
        </div>
      </div>

      <div class="player-controls">
        <button @click="handlePrevious" class="control-button" :disabled="!hasPrevious">
          ⏮
        </button>
        <button @click="togglePlay" class="control-button play-button">
          <span v-if="isPlaying">⏸</span>
          <span v-else>▶</span>
        </button>
        <button @click="handleNext" class="control-button" :disabled="!hasNext">
          ⏭
        </button>
      </div>

      <div class="progress-section">
        <input
          type="range"
          min="0"
          :max="duration"
          v-model="currentTime"
          @input="handleSeek"
          class="progress-slider"
        />
      </div>

      <div class="volume-section">
        <button @click="toggleMute" class="volume-button">
          <span v-if="isMuted || volume === 0">🔇</span>
          <span v-else-if="volume < 0.5">🔉</span>
          <span v-else>🔊</span>
        </button>
        <input
          type="range"
          min="0"
          max="1"
          step="0.01"
          v-model="volume"
          @input="handleVolumeChange"
          class="volume-slider"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, onBeforeUnmount } from 'vue';
import { getSupabase } from '../supabase.js';
import { useProjectStore } from '../stores/projectStore.js';
import { storeToRefs } from 'pinia';

const props = defineProps({
  currentSong: {
    type: Object,
    default: null
  },
  playlist: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['song-change', 'playing-change']);

const projectStore = useProjectStore();
const { activeProject } = storeToRefs(projectStore);
const supabase = getSupabase();

const audioElement = ref(null);
const isPlaying = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const volume = ref(0.7);
const isMuted = ref(false);
const previousVolume = ref(0.7);

const hasPrevious = ref(false);
const hasNext = ref(false);

async function togglePlay() {
  if (!audioElement.value) return;

  if (isPlaying.value) {
    audioElement.value.pause();
  } else {
    try {
      await audioElement.value.play();
    } catch (err) {
      console.error('Error playing audio:', err);
      isPlaying.value = false;
    }
  }
}

function handleTimeUpdate() {
  if (audioElement.value) {
    currentTime.value = audioElement.value.currentTime;
  }
}

function handleLoadedMetadata() {
  if (audioElement.value) {
    duration.value = audioElement.value.duration;
    audioElement.value.volume = volume.value;
  }
}

function handleSeek(event) {
  if (audioElement.value) {
    audioElement.value.currentTime = event.target.value;
  }
}

function handleVolumeChange() {
  if (audioElement.value) {
    audioElement.value.volume = volume.value;
    isMuted.value = volume.value === 0;
  }
}

function toggleMute() {
  if (isMuted.value) {
    volume.value = previousVolume.value || 0.7;
    isMuted.value = false;
  } else {
    previousVolume.value = volume.value;
    volume.value = 0;
    isMuted.value = true;
  }
  handleVolumeChange();
}

function handlePrevious() {
  const currentIndex = props.playlist.findIndex(s => s.id === props.currentSong?.id);
  if (currentIndex > 0) {
    emit('song-change', props.playlist[currentIndex - 1]);
  }
}

function handleNext() {
  const currentIndex = props.playlist.findIndex(s => s.id === props.currentSong?.id);
  if (currentIndex < props.playlist.length - 1) {
    emit('song-change', props.playlist[currentIndex + 1]);
  }
}

async function handleEnded() {
  // Log play to history
  await logPlayHistory();
  
  // Auto-play next song if available
  if (hasNext.value) {
    handleNext();
  } else {
    isPlaying.value = false;
  }
}

async function logPlayHistory() {
  if (!props.currentSong || !activeProject.value) return;

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase
      .from('play_history')
      .insert([{
        project_id: activeProject.value.id,
        song_version_id: props.currentSong.id, // Using song_id as version_id for now
        played_by: user.id,
        played_at: new Date().toISOString()
      }]);
  } catch (err) {
    console.error('Error logging play history:', err);
  }
}

function formatDuration(seconds) {
  if (!seconds || isNaN(seconds)) return '0:00';
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function updatePlaylistButtons() {
  const currentIndex = props.playlist.findIndex(s => s.id === props.currentSong?.id);
  hasPrevious.value = currentIndex > 0;
  hasNext.value = currentIndex < props.playlist.length - 1 && currentIndex !== -1;
}

// Watch for song changes
watch(() => props.currentSong, async (newSong, oldSong) => {
  if (newSong && newSong.id !== oldSong?.id) {
    currentTime.value = 0;
    if (audioElement.value) {
      // Pause any current playback
      audioElement.value.pause();
      
      // Load the new song
      audioElement.value.load();
      
      // Wait for the audio to be ready before playing
      try {
        await new Promise((resolve, reject) => {
          const onCanPlay = () => {
            audioElement.value.removeEventListener('canplay', onCanPlay);
            audioElement.value.removeEventListener('error', onError);
            resolve();
          };
          const onError = (e) => {
            audioElement.value.removeEventListener('canplay', onCanPlay);
            audioElement.value.removeEventListener('error', onError);
            reject(e);
          };
          audioElement.value.addEventListener('canplay', onCanPlay, { once: true });
          audioElement.value.addEventListener('error', onError, { once: true });
        });
        
        // Now play the audio
        await audioElement.value.play();
      } catch (err) {
        console.error('Error playing audio:', err);
        isPlaying.value = false;
      }
    }
  }
  updatePlaylistButtons();
});

// Watch for playlist changes
watch(() => props.playlist, () => {
  updatePlaylistButtons();
}, { deep: true });

// Watch for playing state changes
watch(isPlaying, (playing) => {
  emit('playing-change', playing);
});

onMounted(() => {
  if (audioElement.value) {
    audioElement.value.volume = volume.value;
  }
  updatePlaylistButtons();
});

onBeforeUnmount(() => {
  if (audioElement.value) {
    audioElement.value.pause();
  }
});

// Expose audioElement so parent can control it
defineExpose({
  audioElement,
  togglePlay,
  isPlaying
});
</script>

<style scoped>
.audio-player {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.98);
  backdrop-filter: blur(10px);
  border-top: 2px solid #e0e0e0;
  box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.1);
  z-index: 900;
}

.player-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem 2rem;
  display: grid;
  grid-template-columns: 1fr auto 2fr auto;
  gap: 2rem;
  align-items: center;
}

.song-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  min-width: 0;
}

.song-details {
  min-width: 0;
  flex: 1;
}

.song-title {
  font-weight: 600;
  color: #333;
  font-size: 1rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.song-meta {
  color: #666;
  font-size: 0.85rem;
  margin-top: 0.25rem;
}

.player-controls {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.control-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #333;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s;
}

.control-button:hover:not(:disabled) {
  background: #f0f4ff;
  color: #667eea;
}

.control-button:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.control-button.play-button {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-size: 1.3rem;
}

.control-button.play-button:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.progress-section {
  flex: 1;
  min-width: 0;
}

.progress-slider {
  width: 100%;
  height: 6px;
  border-radius: 3px;
  outline: none;
  -webkit-appearance: none;
  appearance: none;
  background: linear-gradient(
    to right,
    #667eea 0%,
    #667eea var(--progress, 0%),
    #e0e0e0 var(--progress, 0%),
    #e0e0e0 100%
  );
  cursor: pointer;
}

.progress-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #667eea;
  cursor: pointer;
  transition: all 0.2s;
}

.progress-slider::-webkit-slider-thumb:hover {
  transform: scale(1.3);
  box-shadow: 0 0 8px rgba(102, 126, 234, 0.6);
}

.progress-slider::-moz-range-thumb {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #667eea;
  cursor: pointer;
  border: none;
  transition: all 0.2s;
}

.progress-slider::-moz-range-thumb:hover {
  transform: scale(1.3);
  box-shadow: 0 0 8px rgba(102, 126, 234, 0.6);
}

.volume-section {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 120px;
}

.volume-button {
  background: none;
  border: none;
  font-size: 1.3rem;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 6px;
  transition: background 0.2s;
}

.volume-button:hover {
  background: #f0f4ff;
}

.volume-slider {
  flex: 1;
  height: 4px;
  border-radius: 2px;
  outline: none;
  -webkit-appearance: none;
  appearance: none;
  background: #e0e0e0;
  cursor: pointer;
}

.volume-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #667eea;
  cursor: pointer;
}

.volume-slider::-moz-range-thumb {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #667eea;
  cursor: pointer;
  border: none;
}

/* Responsive */
@media (max-width: 1024px) {
  .player-content {
    grid-template-columns: 1fr auto;
    gap: 1rem;
  }

  .progress-section {
    grid-column: 1 / -1;
  }

  .volume-section {
    grid-column: 2;
  }
}

@media (max-width: 768px) {
  .player-content {
    padding: 1rem;
    grid-template-columns: 1fr;
  }

  .song-info {
    grid-column: 1;
    grid-row: 1;
  }

  .progress-section {
    grid-column: 1;
    grid-row: 2;
  }

  .player-controls {
    grid-column: 1;
    grid-row: 3;
    justify-content: center;
  }

  .volume-section {
    display: none;
  }
}
</style>
