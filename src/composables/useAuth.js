import { ref } from 'vue';
import { getSupabase } from '../supabase.js';

const user = ref(null);
const session = ref(null);
const loading = ref(true);

export function useAuth() {
  // Get supabase instance lazily when methods are called
  const getSupabaseClient = () => getSupabase();

  async function signInWithEmail(email) {
    const supabase = getSupabaseClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: window.location.origin,
      }
    });

    if (error) {
      throw error;
    }
  }

  async function signOut() {
    const supabase = getSupabaseClient();
    const { error } = await supabase.auth.signOut();
    if (error) {
      throw error;
    }
    user.value = null;
    session.value = null;
  }

  async function updateProfile(updates) {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.updateUser({
      data: updates
    });

    if (error) {
      throw error;
    }

    user.value = data.user;
    return data.user;
  }

  async function getCurrentUser() {
    const supabase = getSupabaseClient();
    const { data: { user: currentUser } } = await supabase.auth.getUser();
    user.value = currentUser;
    return currentUser;
  }

  async function initAuth() {
    loading.value = true;
    
    const supabase = getSupabaseClient();
    
    // Get current session
    const { data: { session: currentSession } } = await supabase.auth.getSession();
    session.value = currentSession;
    user.value = currentSession?.user ?? null;

    // Listen for auth changes
    supabase.auth.onAuthStateChange((_event, newSession) => {
      session.value = newSession;
      user.value = newSession?.user ?? null;
    });

    loading.value = false;
  }

  return {
    user,
    session,
    loading,
    signInWithEmail,
    signOut,
    updateProfile,
    getCurrentUser,
    initAuth
  };
}
