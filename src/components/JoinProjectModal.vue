<template>
  <Teleport to="body">
    <div class="modal-overlay" @click="$emit('close')">
      <div class="modal-content" @click.stop>
        <h3>Join Project</h3>
        <p class="modal-description">Enter the invite code shared by a project member</p>
        
        <form @submit.prevent="handleJoinProject">
          <input
            v-model="inviteCode"
            type="text"
            placeholder="Enter invite code"
            class="modal-input"
            required
            autofocus
          />
          
          <div class="modal-actions">
            <button type="button" @click="$emit('close')" class="modal-button cancel">
              Cancel
            </button>
            <button type="submit" class="modal-button submit" :disabled="joining || !inviteCode">
              {{ joining ? 'Joining...' : 'Join Project' }}
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
import { ref } from 'vue';
import { useProjectStore } from '../stores/projectStore.js';

const emit = defineEmits(['close', 'success']);

const projectStore = useProjectStore();

const inviteCode = ref('');
const joining = ref(false);
const error = ref(null);
const success = ref(null);

async function handleJoinProject() {
  try {
    joining.value = true;
    error.value = null;
    success.value = null;

    await projectStore.joinProjectByCode(inviteCode.value);

    success.value = 'Successfully joined project!';
    
    setTimeout(() => {
      emit('success');
      emit('close');
    }, 1500);
  } catch (err) {
    error.value = err.message;
  } finally {
    joining.value = false;
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
  padding: 2rem;
  max-width: 500px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-content h3 {
  margin: 0 0 1rem 0;
  color: #333;
  font-size: 1.5rem;
}

.modal-description {
  color: #666;
  margin-bottom: 1.5rem;
  font-size: 0.9rem;
}

.modal-input {
  width: 100%;
  padding: 0.9rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  margin-bottom: 1rem;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.modal-input:focus {
  outline: none;
  border-color: #667eea;
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

.modal-button.cancel:hover {
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
