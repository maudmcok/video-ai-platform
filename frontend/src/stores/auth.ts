import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { keycloakService } from '@/services/keycloak'
import type { User } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | undefined>(undefined)
  const isInitialized = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => user.value?.roles.includes('admin') || false)

  async function init() {
    try {
      const authenticated = await keycloakService.init()

      if (authenticated) {
        user.value = keycloakService.getUser()
        token.value = keycloakService.getToken()
      }

      isInitialized.value = true
      return authenticated
    } catch (error) {
      console.error('Failed to initialize auth:', error)
      isInitialized.value = true
      return false
    }
  }

  async function login() {
    await keycloakService.login()
  }

  async function logout() {
    await keycloakService.logout()
    user.value = null
    token.value = undefined
  }

  function hasRole(role: string): boolean {
    return user.value?.roles.includes(role) || false
  }

  return {
    user,
    token,
    isInitialized,
    isAuthenticated,
    isAdmin,
    init,
    login,
    logout,
    hasRole
  }
})
