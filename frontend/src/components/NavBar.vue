<template>
  <nav class="bg-white shadow-lg">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between h-16">
        <!-- Logo and main navigation -->
        <div class="flex">
          <div class="flex-shrink-0 flex items-center">
            <router-link to="/" class="text-2xl font-bold text-primary-600">
              🎬 Video AI
            </router-link>
          </div>

          <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
            <router-link
              to="/projects"
              class="inline-flex items-center px-1 pt-1 text-sm font-medium text-gray-900 border-b-2 hover:border-primary-500 transition-colors"
              active-class="border-primary-600"
            >
              Projets
            </router-link>

            <router-link
              to="/upload"
              class="inline-flex items-center px-1 pt-1 text-sm font-medium text-gray-900 border-b-2 border-transparent hover:border-primary-500 transition-colors"
              active-class="border-primary-600"
            >
              Upload
            </router-link>

            <router-link
              v-if="authStore.isAdmin"
              to="/admin"
              class="inline-flex items-center px-1 pt-1 text-sm font-medium text-gray-900 border-b-2 border-transparent hover:border-primary-500 transition-colors"
              active-class="border-primary-600"
            >
              Admin
            </router-link>
          </div>
        </div>

        <!-- User menu -->
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <span class="text-sm text-gray-700 mr-4">
              👤 {{ authStore.user?.username }}
            </span>
            <button @click="handleLogout" class="btn btn-secondary">
              Déconnexion
            </button>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>
