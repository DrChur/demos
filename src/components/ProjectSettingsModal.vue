<template>
  <Teleport to="body">
    <div class="modal-overlay" @click="$emit('close')">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Project Settings</h3>
          <button @click="$emit('close')" class="close-button">✕</button>
        </div>

        <div class="settings-section">
          <h4>Project Details</h4>
          
          <div class="form-group">
            <label>Project Name</label>
            <input
              v-model="projectName"
              type="text"
              placeholder="Project name"
              class="modal-input"
            />
          </div>

          <div class="form-group">
            <label>Project Icon</label>
            <div class="icon-upload-section">
              <div class="current-icon">
                <img v-if="currentIconUrl" :src="currentIconUrl" alt="Project icon" />
                <span v-else class="icon-placeholder">🎵</span>
              </div>
              <div class="icon-actions">
                <label for="icon-file" class="upload-button">
                  <span>{{ newIconFile ? 'Change Icon' : 'Upload Icon' }}</span>
                </label>
                <input
                  id="icon-file"
                  type="file"
                  accept="image/*"
                  @change="handleIconSelect"
                  class="file-input"
                />
                <span v-if="newIconFile" class="file-name">{{ newIconFile.name }}</span>
              </div>
            </div>
          </div>

          <div class="form-actions">
            <button @click="handleUpdateProject" class="action-button save" :disabled="updating">
              {{ updating ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
          
          <p v-if="updateError" class="error-text">{{ updateError }}</p>
          <p v-if="updateSuccess" class="success-text">{{ updateSuccess }}</p>
        </div>

        <div class="settings-section">
          <h4>Invite Members</h4>
          <p class="section-description">Share this invite code with others to let them join the project</p>
          
          <div class="invite-code-display">
            <code class="invite-code">{{ project?.invite_code }}</code>
            <button @click="copyInviteCode" class="copy-button">
              {{ codeCopied ? '✓ Copied' : '📋 Copy' }}
            </button>
          </div>
        </div>

        <div class="settings-section">
          <h4>Members</h4>
          <div v-if="loadingMembers" class="loading-text">Loading members...</div>
          <div v-else-if="members.length === 0" class="empty-text">No members yet</div>
          <div v-else class="members-list">
            <div v-for="member in members" :key="member.id" class="member-item">
              <div class="member-info">
                <span class="member-name">{{ member.user_email || 'Unknown User' }}</span>
                <span class="member-role">{{ member.role }}</span>
              </div>
              <button
                v-if="member.role !== 'owner' && canManageMembers"
                @click="handleRemoveMember(member.id)"
                class="remove-button"
                :disabled="removingMember === member.id"
              >
                {{ removingMember === member.id ? '...' : '✕' }}
              </button>
            </div>
          </div>
        </div>

        <div class="settings-section danger-zone">
          <h4>Danger Zone</h4>
          <p class="section-description">Once you delete a project, there is no going back.</p>
          <button @click="showDeleteConfirm = true" class="action-button delete">
            Delete Project
          </button>
        </div>

        <!-- Delete Confirmation Modal -->
        <Teleport to="body">
          <div v-if="showDeleteConfirm" class="modal-overlay" @click="showDeleteConfirm = false">
            <div class="confirm-modal" @click.stop>
              <h4>Delete Project?</h4>
              <p>This action cannot be undone. All songs, comments, and project data will be permanently deleted.</p>
              <div class="confirm-actions">
                <button @click="showDeleteConfirm = false" class="modal-button cancel">
                  Cancel
                </button>
                <button @click="handleDeleteProject" class="modal-button delete-confirm" :disabled="deleting">
                  {{ deleting ? 'Deleting...' : 'Delete Project' }}
                </button>
              </div>
            </div>
          </div>
        </Teleport>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useProjectStore } from '../stores/projectStore.js';
import { getSupabase } from '../supabase.js';
import { storeToRefs } from 'pinia';

const props = defineProps({
  project: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['close']);

const projectStore = useProjectStore();
const { activeProject } = storeToRefs(projectStore);
const supabase = getSupabase();

const projectName = ref(props.project.name);
const currentIconUrl = ref(props.project.icon_url);
const newIconFile = ref(null);
const updating = ref(false);
const updateError = ref(null);
const updateSuccess = ref(null);

const codeCopied = ref(false);
const showDeleteConfirm = ref(false);
const deleting = ref(false);

const members = ref([]);
const loadingMembers = ref(false);
const removingMember = ref(null);

const canManageMembers = computed(() => {
  // In a real app, check if current user is owner/admin
  return true;
});

onMounted(() => {
  loadMembers();
});

async function loadMembers() {
  try {
    loadingMembers.value = true;

    const { data, error } = await supabase
      .from('project_members')
      .select('id, user_id, role, created_at')
      .eq('project_id', props.project.id)
      .order('created_at', { ascending: true });

    if (error) throw error;

    // Fetch user emails from auth.users (via RPC or direct query if available)
    // For now, just show user_id
    members.value = data.map(member => ({
      ...member,
      user_email: member.user_id.substring(0, 8) + '...' // Simplified
    }));
  } catch (err) {
    console.error('Error loading members:', err);
  } finally {
    loadingMembers.value = false;
  }
}

function handleIconSelect(event) {
  const file = event.target.files[0];
  if (file) {
    newIconFile.value = file;
    // Preview the new icon
    const reader = new FileReader();
    reader.onload = (e) => {
      currentIconUrl.value = e.target.result;
    };
    reader.readAsDataURL(file);
  }
}

async function handleUpdateProject() {
  try {
    updating.value = true;
    updateError.value = null;
    updateSuccess.value = null;

    const updates = {};
    
    // Update name if changed
    if (projectName.value !== props.project.name) {
      updates.name = projectName.value;
    }

    // Upload new icon if selected
    if (newIconFile.value) {
      await projectStore.uploadProjectIcon(props.project.id, newIconFile.value);
    } else if (Object.keys(updates).length > 0) {
      await projectStore.updateProject(props.project.id, updates);
    }

    updateSuccess.value = 'Project updated successfully!';
    
    setTimeout(() => {
      updateSuccess.value = null;
    }, 3000);
  } catch (err) {
    updateError.value = err.message;
  } finally {
    updating.value = false;
  }
}

async function copyInviteCode() {
  try {
    await navigator.clipboard.writeText(props.project.invite_code);
    codeCopied.value = true;
    setTimeout(() => {
      codeCopied.value = false;
    }, 2000);
  } catch (err) {
    console.error('Failed to copy:', err);
  }
}

async function handleRemoveMember(memberId) {
  try {
    removingMember.value = memberId;

    const { error } = await supabase
      .from('project_members')
      .delete()
      .eq('id', memberId);

    if (error) throw error;

    // Remove from local list
    members.value = members.value.filter(m => m.id !== memberId);
  } catch (err) {
    console.error('Error removing member:', err);
  } finally {
    removingMember.value = null;
  }
}

async function handleDeleteProject() {
  try {
    deleting.value = true;

    await projectStore.deleteProject(props.project.id);

    emit('close');
  } catch (err) {
    console.error('Error deleting project:', err);
  } finally {
    deleting.value = false;
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
  padding: 0;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e0e0e0;
  position: sticky;
  top: 0;
  background: white;
  z-index: 1;
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

.settings-section {
  padding: 2rem;
  border-bottom: 1px solid #e0e0e0;
}

.settings-section:last-child {
  border-bottom: none;
}

.settings-section h4 {
  margin: 0 0 1rem 0;
  color: #333;
  font-size: 1.1rem;
}

.section-description {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 1rem;
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

.icon-upload-section {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.current-icon {
  width: 80px;
  height: 80px;
  border-radius: 12px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  flex-shrink: 0;
}

.current-icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.icon-placeholder {
  font-size: 2.5rem;
}

.icon-actions {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.upload-button {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
  font-weight: 600;
}

.upload-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.file-input {
  display: none;
}

.file-name {
  color: #666;
  font-size: 0.85rem;
}

.form-actions {
  margin-top: 1.5rem;
}

.action-button {
  padding: 0.9rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.action-button.save {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.action-button.save:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.action-button.delete {
  background: #d32f2f;
  color: white;
}

.action-button.delete:hover {
  background: #b71c1c;
  transform: translateY(-2px);
}

.action-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.invite-code-display {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 8px;
}

.invite-code {
  flex: 1;
  font-size: 1.2rem;
  font-weight: 700;
  color: #667eea;
  letter-spacing: 0.1em;
}

.copy-button {
  padding: 0.6rem 1rem;
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.9rem;
  white-space: nowrap;
}

.copy-button:hover {
  border-color: #667eea;
  background: #f0f4ff;
}

.members-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.member-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.member-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.member-name {
  font-weight: 600;
  color: #333;
}

.member-role {
  font-size: 0.85rem;
  color: #666;
  text-transform: capitalize;
}

.remove-button {
  background: #fff;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  color: #999;
}

.remove-button:hover:not(:disabled) {
  border-color: #d32f2f;
  color: #d32f2f;
  background: #ffebee;
}

.remove-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading-text, .empty-text {
  text-align: center;
  color: #999;
  padding: 2rem;
}

.danger-zone {
  background: #fff5f5;
}

.error-text {
  color: #d32f2f;
  font-size: 0.9rem;
  margin-top: 0.75rem;
}

.success-text {
  color: #2e7d32;
  font-size: 0.9rem;
  margin-top: 0.75rem;
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
</style>
