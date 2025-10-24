import Keycloak from 'keycloak-js'
import type { User } from '@/types'

class KeycloakService {
  private keycloak: Keycloak | null = null
  private isInitialized = false

  async init(): Promise<boolean> {
    if (this.isInitialized) {
      return this.keycloak?.authenticated || false
    }

    this.keycloak = new Keycloak({
      url: import.meta.env.VITE_KEYCLOAK_URL || 'http://192.168.1.23:8180',
      realm: import.meta.env.VITE_KEYCLOAK_REALM || 'videoai',
      clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || 'video-ai-platform'
    })

    try {
      const authenticated = await this.keycloak.init({
        onLoad: 'check-sso',
        silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
        pkceMethod: 'S256',
        checkLoginIframe: false
      })

      this.isInitialized = true

      // Auto-refresh token
      if (authenticated) {
        this.setupTokenRefresh()
      }

      return authenticated
    } catch (error) {
      console.error('Failed to initialize Keycloak:', error)
      throw error
    }
  }

  async login(): Promise<void> {
    if (!this.keycloak) {
      throw new Error('Keycloak not initialized')
    }
    await this.keycloak.login()
  }

  async logout(): Promise<void> {
    if (!this.keycloak) {
      throw new Error('Keycloak not initialized')
    }
    await this.keycloak.logout()
  }

  getToken(): string | undefined {
    return this.keycloak?.token
  }

  isAuthenticated(): boolean {
    return this.keycloak?.authenticated || false
  }

  getUser(): User | null {
    if (!this.keycloak?.tokenParsed) {
      return null
    }

    const token = this.keycloak.tokenParsed as any

    return {
      id: token.sub,
      username: token.preferred_username,
      email: token.email,
      firstName: token.given_name,
      lastName: token.family_name,
      roles: token.realm_access?.roles || []
    }
  }

  hasRole(role: string): boolean {
    return this.getUser()?.roles.includes(role) || false
  }

  isAdmin(): boolean {
    return this.hasRole('admin')
  }

  private setupTokenRefresh(): void {
    if (!this.keycloak) return

    // Refresh token every 5 minutes
    setInterval(() => {
      this.keycloak?.updateToken(300).catch(() => {
        console.error('Failed to refresh token')
        this.logout()
      })
    }, 300000)
  }

  async updateToken(minValidity: number = 5): Promise<boolean> {
    if (!this.keycloak) {
      throw new Error('Keycloak not initialized')
    }
    return this.keycloak.updateToken(minValidity)
  }
}

export const keycloakService = new KeycloakService()
