<template>
  <div class="max-w-7xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">📈 Performance Monitoring</h1>

    <!-- Navigation -->
    <div class="flex space-x-4 mb-8">
      <router-link to="/admin" class="btn btn-secondary">
        Configuration
      </router-link>
      <router-link to="/admin/dashboard" class="btn btn-secondary">
        Dashboard
      </router-link>
      <router-link to="/admin/performance" class="btn btn-primary" active-class="bg-primary-700">
        Performance
      </router-link>
    </div>

    <!-- Time Range Selector -->
    <div class="card mb-6">
      <div class="flex flex-wrap gap-2">
        <button
          v-for="range in timeRanges"
          :key="range.value"
          @click="selectedRange = range.value"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-colors',
            selectedRange === range.value
              ? 'bg-primary-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
        >
          {{ range.label }}
        </button>
      </div>
    </div>

    <!-- Performance Comparison -->
    <div class="card mb-6">
      <h2 class="text-xl font-semibold mb-6">⚡ CPU vs GPU Performance</h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <!-- CPU Stats -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <h3 class="font-semibold text-gray-900">💻 CPU Local (Proxmox)</h3>
            <span class="text-2xl">🐢</span>
          </div>

          <div class="space-y-3">
            <div>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-600">Temps moyen (1h vidéo)</span>
                <span class="font-bold text-blue-600">~30 min</span>
              </div>
              <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
                <div class="h-full bg-blue-600 rounded-full" style="width: 100%"></div>
              </div>
            </div>

            <div>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-600">Coût</span>
                <span class="font-bold text-green-600">0 €</span>
              </div>
              <div class="text-xs text-gray-500">Infrastructure déjà amortie</div>
            </div>

            <div>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-600">Disponibilité</span>
                <span class="font-bold text-gray-900">24/7</span>
              </div>
            </div>

            <div class="p-3 bg-blue-50 rounded-lg">
              <p class="text-sm text-blue-800">
                <strong>Idéal pour:</strong> Vidéos courtes (&lt;5 min), tests, dev
              </p>
            </div>
          </div>
        </div>

        <!-- GPU Stats -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <h3 class="font-semibold text-gray-900">⚡ GPU GCP (NVIDIA T4)</h3>
            <span class="text-2xl">🚀</span>
          </div>

          <div class="space-y-3">
            <div>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-600">Temps moyen (1h vidéo)</span>
                <span class="font-bold text-green-600">~3 min</span>
              </div>
              <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
                <div class="h-full bg-green-600 rounded-full" style="width: 10%"></div>
              </div>
            </div>

            <div>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-600">Coût (Spot)</span>
                <span class="font-bold text-yellow-600">~0.01 €</span>
              </div>
              <div class="text-xs text-gray-500">$0.16/heure, ~3 min/vidéo</div>
            </div>

            <div>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-600">Speedup</span>
                <span class="font-bold text-purple-600">10x</span>
              </div>
            </div>

            <div class="p-3 bg-green-50 rounded-lg">
              <p class="text-sm text-green-800">
                <strong>Idéal pour:</strong> Vidéos longues, prod, volumes élevés
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Metrics Table -->
    <div class="card">
      <h2 class="text-xl font-semibold mb-6">📊 Métriques Récentes</h2>

      <div v-if="configStore.isLoading" class="text-center py-8">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-600">Chargement...</p>
      </div>

      <div v-else-if="metrics.length === 0" class="text-center py-12 text-gray-500">
        <p>Aucune métrique disponible</p>
        <p class="text-sm mt-2">Les métriques apparaîtront après les premières transcriptions</p>
      </div>

      <div v-else class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Worker</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Durée Vidéo</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Temps Traitement</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Speedup</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Coût</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="metric in metrics" :key="metric.timestamp" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(metric.timestamp) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span :class="['text-sm font-semibold', metric.workerType === 'GPU_GCP' ? 'text-green-600' : 'text-blue-600']">
                  {{ metric.workerType === 'GPU_GCP' ? '⚡ GPU' : '💻 CPU' }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ formatDuration(metric.videoDuration) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ formatDuration(metric.processingTime) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-purple-600">
                {{ (metric.videoDuration / metric.processingTime).toFixed(1) }}x
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-green-600">
                {{ metric.cost.toFixed(4) }} €
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Cost Analysis -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
      <div class="card">
        <h3 class="font-semibold text-gray-900 mb-4">💰 Analyse des Coûts</h3>

        <div class="space-y-4">
          <div>
            <div class="flex justify-between text-sm mb-2">
              <span class="text-gray-600">Coût Total (ce mois)</span>
              <span class="font-bold text-green-600">{{ getTotalCost() }} €</span>
            </div>
            <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
              <div class="h-full bg-green-600 rounded-full" :style="{ width: getCostBar() + '%' }"></div>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p class="text-gray-600">CPU Local</p>
              <p class="font-bold text-blue-600">0 €</p>
            </div>
            <div>
              <p class="text-gray-600">GPU GCP</p>
              <p class="font-bold text-green-600">{{ getTotalCost() }} €</p>
            </div>
          </div>

          <div class="p-3 bg-green-50 rounded-lg">
            <p class="text-xs text-green-800">
              💡 Économies vs Full GCP: <strong>-80%</strong>
            </p>
          </div>
        </div>
      </div>

      <div class="card">
        <h3 class="font-semibold text-gray-900 mb-4">⚡ Performance Globale</h3>

        <div class="space-y-4">
          <div>
            <div class="flex justify-between text-sm mb-2">
              <span class="text-gray-600">Speedup Moyen</span>
              <span class="font-bold text-purple-600">{{ getAvgSpeedup() }}x</span>
            </div>
            <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
              <div class="h-full bg-purple-600 rounded-full" :style="{ width: getSpeedupBar() + '%' }"></div>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p class="text-gray-600">Vidéos Traitées</p>
              <p class="font-bold text-gray-900">{{ metrics.length }}</p>
            </div>
            <div>
              <p class="text-gray-600">Temps Économisé</p>
              <p class="font-bold text-blue-600">{{ getTimeSaved() }}h</p>
            </div>
          </div>

          <div class="p-3 bg-purple-50 rounded-lg">
            <p class="text-xs text-purple-800">
              🚀 En moyenne <strong>{{ getAvgSpeedup() }}x plus rapide</strong> que le temps réel
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useConfigStore } from '@/stores/config'

const configStore = useConfigStore()

const selectedRange = ref('7d')
const timeRanges = [
  { label: '24h', value: '24h' },
  { label: '7 jours', value: '7d' },
  { label: '30 jours', value: '30d' },
  { label: 'Tout', value: 'all' }
]

const metrics = computed(() => configStore.performanceMetrics)

onMounted(async () => {
  await configStore.fetchPerformanceMetrics()
})

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = Math.floor(seconds % 60)

  if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else if (minutes > 0) {
    return `${minutes}m ${secs}s`
  } else {
    return `${secs}s`
  }
}

function getTotalCost(): string {
  const total = metrics.value.reduce((sum, m) => sum + m.cost, 0)
  return total.toFixed(2)
}

function getCostBar(): number {
  const total = parseFloat(getTotalCost())
  return Math.min((total / 50) * 100, 100) // Normalize to max 50€
}

function getAvgSpeedup(): string {
  if (metrics.value.length === 0) return '0'

  const totalSpeedup = metrics.value.reduce((sum, m) => {
    return sum + (m.videoDuration / m.processingTime)
  }, 0)

  return (totalSpeedup / metrics.value.length).toFixed(1)
}

function getSpeedupBar(): number {
  const avg = parseFloat(getAvgSpeedup())
  return Math.min((avg / 10) * 100, 100) // Normalize to max 10x
}

function getTimeSaved(): string {
  const totalSaved = metrics.value.reduce((sum, m) => {
    return sum + (m.videoDuration - m.processingTime)
  }, 0)

  return (totalSaved / 3600).toFixed(1)
}
</script>
