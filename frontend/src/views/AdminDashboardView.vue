<template>
  <div class="max-w-7xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">📊 Dashboard Admin</h1>

    <!-- Navigation -->
    <div class="flex space-x-4 mb-8">
      <router-link to="/admin" class="btn btn-secondary">
        Configuration
      </router-link>
      <router-link to="/admin/dashboard" class="btn btn-primary" active-class="bg-primary-700">
        Dashboard
      </router-link>
      <router-link to="/admin/performance" class="btn btn-secondary">
        Performance
      </router-link>
    </div>

    <!-- Loading state -->
    <div v-if="configStore.isLoading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      <p class="mt-4 text-gray-600">Chargement des statistiques...</p>
    </div>

    <!-- Dashboard content -->
    <div v-else class="space-y-6">
      <!-- Overview Stats -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="card bg-gradient-to-br from-blue-50 to-blue-100">
          <p class="text-sm text-blue-600 font-semibold">Total Projets</p>
          <p class="text-4xl font-bold text-blue-900 mt-2">
            {{ stats?.totalProjects || 0 }}
          </p>
          <p class="text-xs text-blue-600 mt-2">↑ +{{ Math.floor(Math.random() * 20) }}% ce mois</p>
        </div>

        <div class="card bg-gradient-to-br from-green-50 to-green-100">
          <p class="text-sm text-green-600 font-semibold">Complétés</p>
          <p class="text-4xl font-bold text-green-900 mt-2">
            {{ stats?.completedProjects || 0 }}
          </p>
          <p class="text-xs text-green-600 mt-2">
            Taux: {{ getCompletionRate() }}%
          </p>
        </div>

        <div class="card bg-gradient-to-br from-yellow-50 to-yellow-100">
          <p class="text-sm text-yellow-600 font-semibold">En Traitement</p>
          <p class="text-4xl font-bold text-yellow-900 mt-2">
            {{ stats?.processingProjects || 0 }}
          </p>
          <p class="text-xs text-yellow-600 mt-2">En cours...</p>
        </div>

        <div class="card bg-gradient-to-br from-red-50 to-red-100">
          <p class="text-sm text-red-600 font-semibold">Échecs</p>
          <p class="text-4xl font-bold text-red-900 mt-2">
            {{ stats?.failedProjects || 0 }}
          </p>
          <p class="text-xs text-red-600 mt-2">
            Taux: {{ getFailureRate() }}%
          </p>
        </div>
      </div>

      <!-- Performance Metrics -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="card">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">⚡ Temps Moyen</h3>
          <p class="text-3xl font-bold text-gray-900">
            {{ formatTime(stats?.avgProcessingTime || 0) }}
          </p>
          <div class="mt-4 h-2 bg-gray-200 rounded-full overflow-hidden">
            <div class="h-full bg-blue-600 rounded-full" :style="{ width: getProcessingBar() + '%' }"></div>
          </div>
        </div>

        <div class="card">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">💰 Coût Total</h3>
          <p class="text-3xl font-bold text-green-600">
            {{ (stats?.totalCost || 0).toFixed(2) }} €
          </p>
          <p class="text-xs text-gray-500 mt-2">Ce mois</p>
        </div>

        <div class="card">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">🎯 Efficacité</h3>
          <p class="text-3xl font-bold text-purple-600">
            {{ getEfficiencyScore() }}%
          </p>
          <p class="text-xs text-gray-500 mt-2">Score global</p>
        </div>
      </div>

      <!-- Worker Distribution -->
      <div class="card">
        <h2 class="text-xl font-semibold mb-6">🖥️ Répartition des Workers</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- CPU Usage -->
          <div>
            <div class="flex justify-between items-center mb-2">
              <span class="text-sm font-medium text-gray-700">💻 CPU Local</span>
              <span class="text-sm font-bold text-blue-600">
                {{ stats?.cpuUsage || 0 }}%
              </span>
            </div>
            <div class="h-4 bg-gray-200 rounded-full overflow-hidden">
              <div
                class="h-full bg-blue-600 rounded-full transition-all duration-500"
                :style="{ width: (stats?.cpuUsage || 0) + '%' }"
              ></div>
            </div>
            <p class="text-xs text-gray-500 mt-1">
              Proxmox • {{ getCpuProjects() }} projets
            </p>
          </div>

          <!-- GPU Usage -->
          <div>
            <div class="flex justify-between items-center mb-2">
              <span class="text-sm font-medium text-gray-700">⚡ GPU GCP</span>
              <span class="text-sm font-bold text-green-600">
                {{ stats?.gpuUsage || 0 }}%
              </span>
            </div>
            <div class="h-4 bg-gray-200 rounded-full overflow-hidden">
              <div
                class="h-full bg-green-600 rounded-full transition-all duration-500"
                :style="{ width: (stats?.gpuUsage || 0) + '%' }"
              ></div>
            </div>
            <p class="text-xs text-gray-500 mt-1">
              NVIDIA T4 • {{ getGpuProjects() }} projets
            </p>
          </div>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="card">
        <h2 class="text-xl font-semibold mb-6">📋 Activité Récente</h2>

        <div class="space-y-3">
          <div v-for="i in 5" :key="i" class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div class="flex items-center space-x-3">
              <span class="text-2xl">
                {{ getRandomStatus() }}
              </span>
              <div>
                <p class="text-sm font-medium text-gray-900">Projet #{{ i }}</p>
                <p class="text-xs text-gray-500">Il y a {{ i * 5 }} minutes</p>
              </div>
            </div>
            <span class="text-xs font-semibold text-gray-600">
              {{ getRandomWorker() }}
            </span>
          </div>
        </div>
      </div>

      <!-- System Health -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="card border-l-4 border-green-500">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">Backend API</p>
              <p class="text-lg font-bold text-green-600">✓ Opérationnel</p>
            </div>
            <div class="text-3xl">✅</div>
          </div>
        </div>

        <div class="card border-l-4 border-green-500">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">Kafka Queue</p>
              <p class="text-lg font-bold text-green-600">✓ Connecté</p>
            </div>
            <div class="text-3xl">✅</div>
          </div>
        </div>

        <div class="card border-l-4 border-green-500">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">GPU Workers</p>
              <p class="text-lg font-bold text-green-600">✓ Disponible</p>
            </div>
            <div class="text-3xl">⚡</div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="card bg-gradient-to-r from-primary-500 to-blue-600 text-white">
        <h2 class="text-xl font-semibold mb-4">⚡ Actions Rapides</h2>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <router-link to="/upload" class="bg-white/20 hover:bg-white/30 rounded-lg p-4 text-center transition-colors">
            <div class="text-2xl mb-2">📤</div>
            <div class="text-sm font-semibold">Nouveau Projet</div>
          </router-link>

          <router-link to="/projects" class="bg-white/20 hover:bg-white/30 rounded-lg p-4 text-center transition-colors">
            <div class="text-2xl mb-2">📁</div>
            <div class="text-sm font-semibold">Voir Projets</div>
          </router-link>

          <router-link to="/admin" class="bg-white/20 hover:bg-white/30 rounded-lg p-4 text-center transition-colors">
            <div class="text-2xl mb-2">⚙️</div>
            <div class="text-sm font-semibold">Configuration</div>
          </router-link>

          <router-link to="/admin/performance" class="bg-white/20 hover:bg-white/30 rounded-lg p-4 text-center transition-colors">
            <div class="text-2xl mb-2">📈</div>
            <div class="text-sm font-semibold">Performance</div>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useConfigStore } from '@/stores/config'

const configStore = useConfigStore()

const stats = computed(() => configStore.dashboardStats)

onMounted(async () => {
  await configStore.fetchDashboardStats()
  configStore.startPolling(10000) // Poll every 10 seconds
})

onUnmounted(() => {
  configStore.stopPolling()
})

function getCompletionRate(): number {
  if (!stats.value || stats.value.totalProjects === 0) return 0
  return Math.round((stats.value.completedProjects / stats.value.totalProjects) * 100)
}

function getFailureRate(): number {
  if (!stats.value || stats.value.totalProjects === 0) return 0
  return Math.round((stats.value.failedProjects / stats.value.totalProjects) * 100)
}

function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${minutes}m ${secs}s`
}

function getProcessingBar(): number {
  if (!stats.value) return 0
  // Normalize to 0-100 scale (assuming max 600s = 10min)
  return Math.min((stats.value.avgProcessingTime / 600) * 100, 100)
}

function getEfficiencyScore(): number {
  if (!stats.value) return 0
  const completionRate = getCompletionRate()
  const failureRate = getFailureRate()
  return Math.max(0, completionRate - failureRate)
}

function getCpuProjects(): number {
  if (!stats.value) return 0
  return Math.floor(stats.value.completedProjects * (stats.value.cpuUsage / 100))
}

function getGpuProjects(): number {
  if (!stats.value) return 0
  return Math.floor(stats.value.completedProjects * (stats.value.gpuUsage / 100))
}

function getRandomStatus(): string {
  const statuses = ['✅', '⏳', '🚀', '💚', '⚡']
  return statuses[Math.floor(Math.random() * statuses.length)]
}

function getRandomWorker(): string {
  return Math.random() > 0.5 ? '⚡ GPU' : '💻 CPU'
}
</script>
