<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 to-blue-100 flex items-center justify-center">
    <div class="max-w-4xl mx-auto px-4 py-16 text-center">
      <h1 class="text-6xl font-bold text-gray-900 mb-6">
        🎬 Video AI Platform
      </h1>

      <p class="text-xl text-gray-700 mb-12">
        Transcription vidéo alimentée par l'IA avec GPU NVIDIA T4 sur Google Cloud Platform
      </p>

      <div class="grid md:grid-cols-3 gap-8 mb-12">
        <div class="card">
          <div class="text-4xl mb-4">⚡</div>
          <h3 class="text-lg font-semibold mb-2">10x Plus Rapide</h3>
          <p class="text-gray-600">GPU NVIDIA T4 pour une transcription ultra-rapide</p>
        </div>

        <div class="card">
          <div class="text-4xl mb-4">💰</div>
          <h3 class="text-lg font-semibold mb-2">89% Moins Cher</h3>
          <p class="text-gray-600">Architecture hybride Proxmox + GCP</p>
        </div>

        <div class="card">
          <div class="text-4xl mb-4">🤖</div>
          <h3 class="text-lg font-semibold mb-2">IA OpenAI Whisper</h3>
          <p class="text-gray-600">Reconnaissance vocale de pointe</p>
        </div>
      </div>

      <div class="space-x-4">
        <button v-if="!authStore.isAuthenticated" @click="handleLogin" class="btn btn-primary text-lg px-8 py-3">
          Se Connecter
        </button>

        <router-link v-else to="/projects" class="btn btn-primary text-lg px-8 py-3">
          Mes Projets
        </router-link>

        <router-link v-if="authStore.isAuthenticated" to="/upload" class="btn btn-secondary text-lg px-8 py-3">
          Uploader une Vidéo
        </router-link>
      </div>

      <div class="mt-16 text-sm text-gray-600">
        <p>✅ Infrastructure prête • ✅ GPU disponible • ✅ API fonctionnelle</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const handleLogin = async () => {
  await authStore.login()
}
</script>
