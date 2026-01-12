import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getSupabase } from '../supabase.js';

export const useProjectStore = defineStore('project', () => {
  const supabase = getSupabase();
  
  // State
  const projects = ref([]);
  const activeProject = ref(null);
  const loading = ref(false);
  const error = ref(null);

  // Computed
  const activeProjectId = computed(() => activeProject.value?.id);
  const hasProjects = computed(() => projects.value.length > 0);

  // Actions
  async function loadProjects() {
    try {
      loading.value = true;
      error.value = null;

      // Fetch projects (without nested project_members to avoid RLS recursion)
      const { data, error: fetchError } = await supabase
        .from('projects')
        .select('id, name, invite_code, icon_url, created_at')
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

      // Set active project to first one if none selected
      if (!activeProject.value && projects.value.length > 0) {
        activeProject.value = projects.value[0];
      }
    } catch (err) {
      error.value = err.message;
      console.error('Error loading projects:', err);
    } finally {
      loading.value = false;
    }
  }

  async function setActiveProject(projectId) {
    const project = projects.value.find(p => p.id === projectId);
    if (project) {
      activeProject.value = project;
      // Store in localStorage for persistence
      localStorage.setItem('activeProjectId', projectId);
    }
  }

  async function createProject(name, iconFile = null) {
    try {
      loading.value = true;
      error.value = null;

      // Create project
      const { data: project, error: createError } = await supabase
        .from('projects')
        .insert([{ name }])
        .select()
        .single();

      if (createError) throw createError;

      // Add creator as project member
      const { data: { user } } = await supabase.auth.getUser();
      const { error: memberError } = await supabase
        .from('project_members')
        .insert([{
          project_id: project.id,
          user_id: user.id,
          role: 'owner'
        }]);

      if (memberError) throw memberError;

      // Upload icon if provided
      if (iconFile) {
        await uploadProjectIcon(project.id, iconFile);
      }

      // Reload projects
      await loadProjects();
      
      // Set as active project
      await setActiveProject(project.id);

      return project;
    } catch (err) {
      error.value = err.message;
      console.error('Error creating project:', err);
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function updateProject(projectId, updates) {
    try {
      loading.value = true;
      error.value = null;

      const { data, error: updateError } = await supabase
        .from('projects')
        .update(updates)
        .eq('id', projectId)
        .select()
        .single();

      if (updateError) throw updateError;

      // Update in local state
      const index = projects.value.findIndex(p => p.id === projectId);
      if (index !== -1) {
        projects.value[index] = { ...projects.value[index], ...data };
      }

      // Update active project if it's the one being updated
      if (activeProject.value?.id === projectId) {
        activeProject.value = { ...activeProject.value, ...data };
      }

      return data;
    } catch (err) {
      error.value = err.message;
      console.error('Error updating project:', err);
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function uploadProjectIcon(projectId, file) {
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${projectId}.${fileExt}`;
      const filePath = `${projectId}/${fileName}`;

      // Upload to Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from('project-icons')
        .upload(filePath, file, { upsert: true });

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('project-icons')
        .getPublicUrl(filePath);

      // Update project with icon URL
      await updateProject(projectId, { icon_url: publicUrl });

      return publicUrl;
    } catch (err) {
      error.value = err.message;
      console.error('Error uploading project icon:', err);
      throw err;
    }
  }

  async function joinProjectByCode(inviteCode) {
    try {
      loading.value = true;
      error.value = null;

      // Find project by invite code
      const { data: project, error: findError } = await supabase
        .from('projects')
        .select('id, name')
        .eq('invite_code', inviteCode)
        .single();

      if (findError || !project) {
        throw new Error('Invalid invite code');
      }

      // Check if already a member
      const { data: { user } } = await supabase.auth.getUser();
      const { data: existingMember } = await supabase
        .from('project_members')
        .select('id')
        .eq('project_id', project.id)
        .eq('user_id', user.id)
        .single();

      if (existingMember) {
        throw new Error('You are already a member of this project');
      }

      // Add user as project member
      const { error: joinError } = await supabase
        .from('project_members')
        .insert([{
          project_id: project.id,
          user_id: user.id,
          role: 'member'
        }]);

      if (joinError) throw joinError;

      // Reload projects
      await loadProjects();
      
      // Set as active project
      await setActiveProject(project.id);

      return project;
    } catch (err) {
      error.value = err.message;
      console.error('Error joining project:', err);
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function deleteProject(projectId) {
    try {
      loading.value = true;
      error.value = null;

      const { error: deleteError } = await supabase
        .from('projects')
        .delete()
        .eq('id', projectId);

      if (deleteError) throw deleteError;

      // Remove from local state
      projects.value = projects.value.filter(p => p.id !== projectId);

      // Clear active project if it was deleted
      if (activeProject.value?.id === projectId) {
        activeProject.value = projects.value.length > 0 ? projects.value[0] : null;
      }
    } catch (err) {
      error.value = err.message;
      console.error('Error deleting project:', err);
      throw err;
    } finally {
      loading.value = false;
    }
  }

  // Initialize from localStorage
  function initFromStorage() {
    const storedProjectId = localStorage.getItem('activeProjectId');
    if (storedProjectId) {
      const project = projects.value.find(p => p.id === storedProjectId);
      if (project) {
        activeProject.value = project;
      }
    }
  }

  return {
    // State
    projects,
    activeProject,
    loading,
    error,
    
    // Computed
    activeProjectId,
    hasProjects,
    
    // Actions
    loadProjects,
    setActiveProject,
    createProject,
    updateProject,
    uploadProjectIcon,
    joinProjectByCode,
    deleteProject,
    initFromStorage
  };
});
