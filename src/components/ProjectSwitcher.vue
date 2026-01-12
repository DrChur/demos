<template>
  <div class="project-switcher">
    <button @click="toggleDropdown" class="switcher-button">
      <div class="project-icon">
        <img v-if="activeProject?.icon_url" :src="activeProject.icon_url" alt="Project icon" />
        <span v-else class="icon-placeholder">🎵</span>
      </div>
      <span class="project-name">{{ activeProject?.name || 'Select Project' }}</span>
      <span class="dropdown-arrow">▼</span>
    </button>

    <Teleport to="body">
      <div v-if="showDropdown" class="dropdown-overlay" @click="toggleDropdown">
        <div class="dropdown-menu" @click.stop>
          <div class="dropdown-header">
            <h3>Projects</h3>
            <button @click="toggleDropdown" class="close-button">✕</button>
          </div>

          <div class="projects-list">
            <button
              v-for="project in projects"
              :key="project.id"
              @click="selectProject(project.id)"
              class="project-item"
              :class="{ active: project.id === activeProject?.id }"
            >
              <div class="project-icon-small">
                <img v-if="project.icon_url" :src="project.icon_url" alt="Project icon" />
                <span v-else class="icon-placeholder-small">🎵</span>
              </div>
              <div class="project-info">
                <span class="project-name-text">{{ project.name }}</span>
                <span class="project-members">{{ project.member_count || 0 }} members</span>
              </div>
              <span v-if="project.id === activeProject?.id" class="check-icon">✓</span>
            </button>
          </div>

          <div class="dropdown-actions">
            <button @click="showCreateModal = true" class="action-button create">
              <span class="button-icon">➕</span> Create New Project
            </button>
            <button @click="showJoinModal = true" class="action-button join">
              <span class="button-icon">🔗</span> Join by Invite Code
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Create Project Modal -->
    <Teleport to="body">
      <div v-if="showCreateModal" class="modal-overlay" @click="showCreateModal = false">
        <div class="modal-content" @click.stop>
          <h3>Create New Project</h3>
          <form @submit.prevent="handleCreateProject">
            <input
              v-model="newProjectName"
              type="text"
              placeholder="Project name"
              class="modal-input"
              required
            />
            <div class="file-upload-section">
              <label for="project-icon" class="file-upload-label">
                <span class="upload-icon">📁</span>
                <span>{{ iconFile ? iconFile.name : 'Choose project icon (optional)' }}</span>
              </label>
              <input
                id="project-icon"
                type="file"
                accept="image/*"
                @change="handleIconSelect"
                class="file-input"
              />
            </div>
            <div class="modal-actions">
              <button type="button" @click="showCreateModal = false" class="modal-button cancel">
                Cancel
              </button>
              <button type="submit" class="modal-button submit" :disabled="creating || !newProjectName">
                {{ creating ? 'Creating...' : 'Create Project' }}
              </button>
            </div>
            <p v-if="createError" class="error-text">{{ createError }}</p>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- Join Project Modal (placeholder for next todo) -->
    <Teleport to="body">
      <div v-if="showJoinModal" class="modal-overlay" @click="showJoinModal = false">
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
            />
            <div class="modal-actions">
              <button type="button" @click="showJoinModal = false" class="modal-button cancel">
                Cancel
              </button>
              <button type="submit" class="modal-button submit" :disabled="joining || !inviteCode">
                {{ joining ? 'Joining...' : 'Join Project' }}
              </button>
            </div>
            <p v-if="joinError" class="error-text">{{ joinError }}</p>
            <p v-if="joinSuccess" class="success-text">{{ joinSuccess }}</p>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useProjectStore } from '../stores/projectStore.js';
import { storeToRefs } from 'pinia';

const projectStore = useProjectStore();
const { projects, activeProject } = storeToRefs(projectStore);

const showDropdown = ref(false);
const showCreateModal = ref(false);
const showJoinModal = ref(false);

const newProjectName = ref('');
const iconFile = ref(null);
const creating = ref(false);
const createError = ref(null);

const inviteCode = ref('');
const joining = ref(false);
const joinError = ref(null);
const joinSuccess = ref(null);

function toggleDropdown() {
  showDropdown.value = !showDropdown.value;
}

async function selectProject(projectId) {
  await projectStore.setActiveProject(projectId);
  showDropdown.value = false;
}

function handleIconSelect(event) {
  const file = event.target.files[0];
  if (file) {
    iconFile.value = file;
  }
}

async function handleCreateProject() {
  try {
    creating.value = true;
    createError.value = null;

    await projectStore.createProject(newProjectName.value, iconFile.value);

    // Close modal and reset form
    showCreateModal.value = false;
    showDropdown.value = false;
    newProjectName.value = '';
    iconFile.value = null;
  } catch (err) {
    createError.value = err.message;
  } finally {
    creating.value = false;
  }
}

async function handleJoinProject() {
  try {
    joining.value = true;
    joinError.value = null;
    joinSuccess.value = null;

    await projectStore.joinProjectByCode(inviteCode.value);

    joinSuccess.value = 'Successfully joined project!';
    
    setTimeout(() => {
      showJoinModal.value = false;
      showDropdown.value = false;
      inviteCode.value = '';
      joinSuccess.value = null;
    }, 1500);
  } catch (err) {
    joinError.value = err.message;
  } finally {
    joining.value = false;
  }
}
</script>

<style scoped>
.project-switcher {
  position: relative;
}

.switcher-button {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.6rem 1rem;
  background: rgba(255, 255, 255, 0.95);
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.95rem;
  color: #333;
}

.switcher-button:hover {
  border-color: #667eea;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}

.project-icon {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.project-icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.icon-placeholder {
  font-size: 1.2rem;
}

.project-name {
  font-weight: 600;
  max-width: 150px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.dropdown-arrow {
  font-size: 0.7rem;
  margin-left: 0.25rem;
  opacity: 0.6;
}

.dropdown-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: flex-start;
  justify-content: flex-start;
  padding: 1rem;
  z-index: 1000;
}

.dropdown-menu {
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  min-width: 320px;
  max-width: 400px;
  margin-top: 4rem;
  margin-left: 1rem;
  max-height: calc(100vh - 6rem);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.dropdown-header {
  padding: 1.25rem;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dropdown-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.1rem;
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

.projects-list {
  overflow-y: auto;
  max-height: 400px;
}

.project-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  background: none;
  border: none;
  width: 100%;
  text-align: left;
  cursor: pointer;
  transition: background 0.2s;
  color: #333;
}

.project-item:hover {
  background: #f8f9fa;
}

.project-item.active {
  background: #f0f4ff;
}

.project-icon-small {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  flex-shrink: 0;
}

.project-icon-small img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.icon-placeholder-small {
  font-size: 1.5rem;
}

.project-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.project-name-text {
  font-weight: 600;
  font-size: 0.95rem;
}

.project-members {
  font-size: 0.8rem;
  color: #999;
}

.check-icon {
  color: #667eea;
  font-weight: bold;
  font-size: 1.2rem;
}

.dropdown-actions {
  padding: 1rem;
  border-top: 1px solid #e0e0e0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.action-button {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.9rem;
  font-weight: 600;
  color: #333;
}

.action-button:hover {
  border-color: #667eea;
  background: #f8f9fa;
  transform: translateY(-1px);
}

.action-button.create {
  border-color: #667eea;
  color: #667eea;
}

.action-button.join {
  border-color: #764ba2;
  color: #764ba2;
}

.button-icon {
  font-size: 1.1rem;
}

/* Modal Styles */
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
  margin: 0 0 1.5rem 0;
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

.file-upload-section {
  margin-bottom: 1.5rem;
}

.file-upload-label {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.9rem;
  border: 2px dashed #e0e0e0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  color: #666;
}

.file-upload-label:hover {
  border-color: #667eea;
  background: #f8f9fa;
}

.upload-icon {
  font-size: 1.5rem;
}

.file-input {
  display: none;
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
