<template>
  <div id="app" class="min-h-screen flex flex-col">
    <NavBar v-if="authStore.isAuthenticated" />

    <main class="flex-1">
      <RouterView />
    </main>

    <Footer v-if="authStore.isAuthenticated" />
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import NavBar from '@/components/NavBar.vue'
import Footer from '@/components/Footer.vue'

const authStore = useAuthStore()

onMounted(async () => {
  await authStore.init()
})
</script>

<style scoped>
#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}
</style>
