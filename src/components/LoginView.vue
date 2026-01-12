<template>
  <div class="login-container">
    <div class="login-card">
      <h2>🎵 Welcome to Band Demos</h2>
      <p class="description">Sign in with your email to access your projects</p>

      <div v-if="!emailSent" class="login-form">
        <input
          v-model="email"
          type="email"
          placeholder="Enter your email"
          @keyup.enter="handleLogin"
          class="email-input"
        />
        
        <button 
          @click="handleLogin" 
          :disabled="isLoading || !email"
          class="login-button"
        >
          {{ isLoading ? 'Sending...' : 'Send Magic Link' }}
        </button>

        <p v-if="error" class="error-text">{{ error }}</p>
      </div>

      <div v-else class="success-message">
        <div class="success-icon">✉️</div>
        <h3>Check your email!</h3>
        <p>We've sent a magic link to <strong>{{ email }}</strong></p>
        <p class="hint">Click the link in the email to sign in.</p>
        <button @click="resetForm" class="reset-button">
          Use different email
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useAuth } from '../composables/useAuth.js';

const { signInWithEmail } = useAuth();

const email = ref('');
const emailSent = ref(false);
const isLoading = ref(false);
const error = ref(null);

async function handleLogin() {
  if (!email.value) return;

  isLoading.value = true;
  error.value = null;

  try {
    await signInWithEmail(email.value);
    emailSent.value = true;
  } catch (err) {
    error.value = err.message;
  } finally {
    isLoading.value = false;
  }
}

function resetForm() {
  email.value = '';
  emailSent.value = false;
  error.value = null;
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.login-card {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 3rem;
  max-width: 450px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.login-card h2 {
  color: #333;
  margin-bottom: 0.5rem;
  font-size: 2rem;
  text-align: center;
}

.description {
  color: #666;
  text-align: center;
  margin-bottom: 2rem;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.email-input {
  padding: 1rem;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s;
  outline: none;
}

.email-input:focus {
  border-color: #667eea;
}

.login-button {
  padding: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.login-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
}

.login-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-text {
  color: #d32f2f;
  font-size: 0.9rem;
  text-align: center;
}

.success-message {
  text-align: center;
}

.success-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.success-message h3 {
  color: #333;
  margin-bottom: 1rem;
}

.success-message p {
  color: #666;
  margin-bottom: 0.5rem;
  line-height: 1.6;
}

.hint {
  font-size: 0.9rem;
  color: #999;
  margin-top: 1rem;
  margin-bottom: 1.5rem;
}

.reset-button {
  padding: 0.75rem 1.5rem;
  background: transparent;
  color: #667eea;
  border: 2px solid #667eea;
  border-radius: 10px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
}

.reset-button:hover {
  background: #667eea;
  color: white;
}
</style>
