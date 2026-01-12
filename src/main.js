import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import { initSupabase } from './supabase.js';

// Initialize Supabase before mounting the app
initSupabase().then(() => {
  const app = createApp(App);
  const pinia = createPinia();
  
  app.use(pinia);
  app.mount('#app');
}).catch((error) => {
  console.error('Failed to initialize Supabase:', error);
  document.body.innerHTML = `
    <div style="display: flex; align-items: center; justify-content: center; min-height: 100vh; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-family: system-ui;">
      <div style="background: white; padding: 2rem; border-radius: 1rem; max-width: 500px; text-align: center;">
        <h2 style="color: #d32f2f; margin-bottom: 1rem;">⚠️ Configuration Error</h2>
        <p style="color: #666; margin-bottom: 1rem;">Failed to load Supabase configuration.</p>
        <p style="color: #999; font-size: 0.9rem;">Make sure <code>public/config.json</code> exists and is properly configured.</p>
      </div>
    </div>
  `;
});
