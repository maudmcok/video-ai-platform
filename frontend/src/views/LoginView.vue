<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100">
    <div class="card max-w-md w-full">
      <div class="text-center mb-8">
        <h2 class="text-3xl font-bold text-gray-900">Video AI Platform</h2>
        <p class="text-gray-600 mt-2">Connectez-vous pour continuer</p>
      </div>

      <button @click="handleLogin" class="btn btn-primary w-full text-lg py-3">
        🔐 Se connecter avec Keycloak
      </button>

      <p class="text-sm text-gray-500 text-center mt-6">
        Authentification sécurisée via OAuth2
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter, useRoute } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()

onMounted(() => {
  // If already authenticated, redirect
  if (authStore.isAuthenticated) {
    const redirect = route.query.redirect as string || '/projects'
    router.push(redirect)
  }
})

const handleLogin = async () => {
  await authStore.login()
}
</script>
