<template>
  <div class="profile-modal" @click.self="$emit('close')">
    <div class="profile-card">
      <div class="profile-header">
        <h3>👤 Profile Settings</h3>
        <button @click="$emit('close')" class="close-button">✕</button>
      </div>

      <div class="profile-content">
        <div class="info-section">
          <p class="info-label">Email</p>
          <p class="info-value">{{ user.email }}</p>
        </div>

        <div class="info-section">
          <p class="info-label">User ID</p>
          <p class="info-value small">{{ user.id }}</p>
        </div>

        <div class="form-section">
          <label for="displayName">Display Name</label>
          <input
            id="displayName"
            v-model="displayName"
            type="text"
            placeholder="Enter your name"
            class="input-field"
          />
        </div>

        <div class="form-section">
          <label for="bio">Bio (optional)</label>
          <textarea
            id="bio"
            v-model="bio"
            placeholder="Tell your bandmates about yourself"
            class="input-field textarea"
            rows="3"
          ></textarea>
        </div>

        <p v-if="error" class="error-text">{{ error }}</p>
        <p v-if="success" class="success-text">✓ Profile updated!</p>

        <div class="button-group">
          <button @click="handleUpdateProfile" :disabled="isLoading" class="save-button">
            {{ isLoading ? 'Saving...' : 'Save Changes' }}
          </button>
          <button @click="handleSignOut" class="signout-button">
            Sign Out
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useAuth } from '../composables/useAuth.js';

const props = defineProps({
  user: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['close']);

const { updateProfile, signOut } = useAuth();

const displayName = ref('');
const bio = ref('');
const isLoading = ref(false);
const error = ref(null);
const success = ref(false);

onMounted(() => {
  // Load existing user metadata
  displayName.value = props.user.user_metadata?.display_name || '';
  bio.value = props.user.user_metadata?.bio || '';
});

async function handleUpdateProfile() {
  isLoading.value = true;
  error.value = null;
  success.value = false;

  try {
    await updateProfile({
      display_name: displayName.value,
      bio: bio.value
    });
    success.value = true;
    setTimeout(() => {
      success.value = false;
    }, 3000);
  } catch (err) {
    error.value = err.message;
  } finally {
    isLoading.value = false;
  }
}

async function handleSignOut() {
  try {
    await signOut();
    emit('close');
  } catch (err) {
    error.value = err.message;
  }
}
</script>

<style scoped>
.profile-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.profile-card {
  background: white;
  border-radius: 20px;
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.profile-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e0e0e0;
}

.profile-header h3 {
  margin: 0;
  color: #333;
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
  border-radius: 50%;
  transition: background 0.2s;
}

.close-button:hover {
  background: #f0f0f0;
}

.profile-content {
  padding: 1.5rem;
}

.info-section {
  margin-bottom: 1.5rem;
}

.info-label {
  font-size: 0.85rem;
  color: #999;
  margin-bottom: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-value {
  color: #333;
  font-size: 1rem;
  word-break: break-all;
}

.info-value.small {
  font-size: 0.85rem;
  font-family: monospace;
}

.form-section {
  margin-bottom: 1.5rem;
}

.form-section label {
  display: block;
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.input-field {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s;
  outline: none;
  font-family: inherit;
}

.input-field:focus {
  border-color: #667eea;
}

.textarea {
  resize: vertical;
  min-height: 80px;
}

.error-text {
  color: #d32f2f;
  font-size: 0.9rem;
  margin-bottom: 1rem;
}

.success-text {
  color: #4caf50;
  font-size: 0.9rem;
  margin-bottom: 1rem;
}

.button-group {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.save-button {
  padding: 0.75rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s;
}

.save-button:hover:not(:disabled) {
  transform: translateY(-2px);
}

.save-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.signout-button {
  padding: 0.75rem;
  background: transparent;
  color: #d32f2f;
  border: 2px solid #d32f2f;
  border-radius: 10px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
}

.signout-button:hover {
  background: #d32f2f;
  color: white;
}
</style>
