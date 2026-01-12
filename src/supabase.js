import { createClient } from '@supabase/supabase-js';

// Load config
let supabase = null;

export async function initSupabase() {
  try {
    const response = await fetch('/config.json');
    const config = await response.json();
    
    supabase = createClient(config.supabase.url, config.supabase.anonKey);
    return supabase;
  } catch (error) {
    console.error('Failed to initialize Supabase:', error);
    throw error;
  }
}

export function getSupabase() {
  if (!supabase) {
    throw new Error('Supabase not initialized. Call initSupabase() first.');
  }
  return supabase;
}
