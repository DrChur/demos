<template>
  <Teleport to="body">
    <div class="modal-overlay" @click="$emit('close')">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Upload Song</h3>
          <button @click="$emit('close')" class="close-button">✕</button>
        </div>

        <form @submit.prevent="handleUpload" class="upload-form">
          <div class="form-group">
            <label>Song Title</label>
            <input
              v-model="songTitle"
              type="text"
              placeholder="Enter song title"
              class="modal-input"
              required
            />
          </div>

          <div class="form-group">
            <label>Audio File</label>
            <div class="file-upload-area">
              <input
                ref="fileInput"
                type="file"
                accept="audio/wav,audio/mp3,audio/mpeg"
                @change="handleFileSelect"
                class="file-input"
                id="audio-file"
                required
              />
              <label for="audio-file" class="file-upload-label">
                <div class="upload-icon">🎵</div>
                <div class="upload-text">
                  <span class="upload-title">
                    {{ audioFile ? audioFile.name : 'Choose audio file' }}
                  </span>
                  <span class="upload-subtitle">WAV or MP3 files only</span>
                </div>
              </label>
            </div>

            <div v-if="audioFile" class="file-info">
              <div class="file-detail">
                <span class="label">File size:</span>
                <span class="value">{{ formatFileSize(audioFile.size) }}</span>
              </div>
              <div class="file-detail">
                <span class="label">Type:</span>
                <span class="value">{{ audioFile.type }}</span>
              </div>
              <div v-if="duration" class="file-detail">
                <span class="label">Duration:</span>
                <span class="value">{{ formatDuration(duration) }}</span>
              </div>
            </div>
          </div>

          <div v-if="uploading" class="upload-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: `${uploadProgress}%` }"></div>
            </div>
            <p class="progress-text">{{ uploadStatus }}</p>
          </div>

          <div class="modal-actions">
            <button type="button" @click="$emit('close')" class="modal-button cancel" :disabled="uploading">
              Cancel
            </button>
            <button type="submit" class="modal-button submit" :disabled="uploading || !audioFile || !songTitle">
              {{ uploading ? 'Uploading...' : 'Upload Song' }}
            </button>
          </div>

          <p v-if="error" class="error-text">{{ error }}</p>
          <p v-if="success" class="success-text">{{ success }}</p>
        </form>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed } from 'vue';
import { getSupabase } from '../supabase.js';
import { useProjectStore } from '../stores/projectStore.js';
import { storeToRefs } from 'pinia';

const emit = defineEmits(['close', 'success']);

const projectStore = useProjectStore();
const { activeProject } = storeToRefs(projectStore);
const supabase = getSupabase();

const songTitle = ref('');
const audioFile = ref(null);
const duration = ref(null);
const fileInput = ref(null);

const uploading = ref(false);
const uploadProgress = ref(0);
const uploadStatus = ref('');
const error = ref(null);
const success = ref(null);

function handleFileSelect(event) {
  const file = event.target.files[0];
  if (file) {
    audioFile.value = file;
    error.value = null;
    
    // Get duration from audio file
    getDuration(file);
  }
}

function getDuration(file) {
  const audio = new Audio();
  const url = URL.createObjectURL(file);
  
  audio.addEventListener('loadedmetadata', () => {
    duration.value = Math.round(audio.duration);
    URL.revokeObjectURL(url);
  });
  
  audio.src = url;
}

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function formatDuration(seconds) {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

async function handleUpload() {
  if (!audioFile.value || !songTitle.value || !activeProject.value) {
    error.value = 'Please fill in all required fields';
    return;
  }

  try {
    uploading.value = true;
    uploadProgress.value = 0;
    error.value = null;
    success.value = null;

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    // Generate song ID
    const songId = crypto.randomUUID();
    
    // Determine file extension
    const fileExt = audioFile.value.name.split('.').pop().toLowerCase();
    const isWav = fileExt === 'wav';
    
    // Upload path: {project_id}/{song_id}/original.{ext}
    const uploadPath = `${activeProject.value.id}/${songId}/original.${fileExt}`;
    
    uploadStatus.value = 'Uploading file...';
    
    // Upload to Supabase Storage
    const { error: uploadError } = await supabase.storage
      .from('audio')
      .upload(uploadPath, audioFile.value, {
        cacheControl: '3600',
        upsert: false,
        onUploadProgress: (progress) => {
          uploadProgress.value = Math.round((progress.loaded / progress.total) * 100);
        }
      });

    if (uploadError) throw uploadError;

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('audio')
      .getPublicUrl(uploadPath);

    uploadStatus.value = 'Creating song record...';

    // Create song record in database
    const { data: song, error: dbError } = await supabase
      .from('songs')
      .insert([{
        id: songId,
        project_id: activeProject.value.id,
        title: songTitle.value,
        file_url: publicUrl,
        file_size: audioFile.value.size,
        file_type: audioFile.value.type,
        duration: duration.value,
        created_by: user.id
      }])
      .select()
      .single();

    if (dbError) throw dbError;

    // If WAV file, trigger conversion (placeholder for now)
    if (isWav) {
      uploadStatus.value = 'Converting to MP3...';
      // TODO: Trigger Edge Function for conversion
      // For now, we'll just use the original file
      console.log('WAV file uploaded - conversion to be implemented');
    }

    success.value = 'Song uploaded successfully!';
    uploadProgress.value = 100;
    uploadStatus.value = 'Upload complete!';

    setTimeout(() => {
      emit('success', song);
      emit('close');
    }, 1500);
  } catch (err) {
    error.value = err.message;
    console.error('Upload error:', err);
  } finally {
    uploading.value = false;
  }
}
</script>

<style scoped>
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

.modal-content {
  background: white;
  border-radius: 16px;
  max-width: 550px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e0e0e0;
}

.modal-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.5rem;
}

.close-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #999;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  transition: all 0.2s;
}

.close-button:hover {
  background: #f5f5f5;
  color: #333;
}

.upload-form {
  padding: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #666;
  font-size: 0.9rem;
  font-weight: 600;
}

.modal-input {
  width: 100%;
  padding: 0.9rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.modal-input:focus {
  outline: none;
  border-color: #667eea;
}

.file-upload-area {
  position: relative;
}

.file-input {
  display: none;
}

.file-upload-label {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  border: 3px dashed #e0e0e0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s;
  background: #f8f9fa;
}

.file-upload-label:hover {
  border-color: #667eea;
  background: #f0f4ff;
}

.upload-icon {
  font-size: 3rem;
  line-height: 1;
}

.upload-text {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.upload-title {
  font-weight: 600;
  color: #333;
  font-size: 1rem;
}

.upload-subtitle {
  color: #999;
  font-size: 0.85rem;
}

.file-info {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.file-detail {
  display: flex;
  justify-content: space-between;
  font-size: 0.9rem;
}

.file-detail .label {
  color: #666;
  font-weight: 600;
}

.file-detail .value {
  color: #333;
}

.upload-progress {
  margin-bottom: 1.5rem;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e0e0e0;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  transition: width 0.3s ease;
}

.progress-text {
  text-align: center;
  color: #666;
  font-size: 0.9rem;
}

.modal-actions {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.5rem;
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

.modal-button.cancel:hover:not(:disabled) {
  background: #e0e0e0;
}

.modal-button.submit {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.modal-button.submit:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.modal-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-text {
  color: #d32f2f;
  font-size: 0.9rem;
  margin-top: 0.75rem;
  text-align: center;
}

.success-text {
  color: #2e7d32;
  font-size: 0.9rem;
  margin-top: 0.75rem;
  text-align: center;
}
</style>
