<template>
  <div class="max-w-7xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">⚙️ Configuration Système</h1>

    <!-- Navigation -->
    <div class="flex space-x-4 mb-8">
      <router-link to="/admin" class="btn btn-primary" active-class="bg-primary-700">
        Configuration
      </router-link>
      <router-link to="/admin/dashboard" class="btn btn-secondary" active-class="bg-gray-400">
        Dashboard
      </router-link>
      <router-link to="/admin/performance" class="btn btn-secondary" active-class="bg-gray-400">
        Performance
      </router-link>
    </div>

    <!-- Loading state -->
    <div v-if="configStore.isLoading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      <p class="mt-4 text-gray-600">Chargement de la configuration...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="configStore.error" class="card bg-red-50 border border-red-200">
      <p class="text-red-800">❌ {{ configStore.error }}</p>
      <button @click="configStore.fetchConfig()" class="btn btn-secondary mt-4">
        Réessayer
      </button>
    </div>

    <!-- Configuration form -->
    <div v-else class="space-y-6">
      <!-- Routing Strategy -->
      <div class="card">
        <h2 class="text-xl font-semibold mb-6">🎯 Stratégie de Routage</h2>

        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-3">
              Mode de traitement
            </label>

            <div class="space-y-3">
              <label class="flex items-center p-4 border rounded-lg cursor-pointer hover:bg-gray-50 transition-colors"
                     :class="localConfig.routingStrategy === 'ALL_LOCAL' ? 'border-primary-600 bg-primary-50' : 'border-gray-300'">
                <input
                  type="radio"
                  v-model="localConfig.routingStrategy"
                  value="ALL_LOCAL"
                  class="mr-3"
                />
                <div>
                  <div class="font-semibold text-gray-900">💻 CPU Local Uniquement</div>
                  <div class="text-sm text-gray-600">
                    Toutes les transcriptions sur le serveur Proxmox (gratuit mais lent)
                  </div>
                </div>
              </label>

              <label class="flex items-center p-4 border rounded-lg cursor-pointer hover:bg-gray-50 transition-colors"
                     :class="localConfig.routingStrategy === 'HYBRID' ? 'border-primary-600 bg-primary-50' : 'border-gray-300'">
                <input
                  type="radio"
                  v-model="localConfig.routingStrategy"
                  value="HYBRID"
                  class="mr-3"
                />
                <div>
                  <div class="font-semibold text-gray-900">⚡ Hybride (Recommandé)</div>
                  <div class="text-sm text-gray-600">
                    Courtes vidéos → CPU local • Longues vidéos → GPU GCP (optimal coût/performance)
                  </div>
                </div>
              </label>

              <label class="flex items-center p-4 border rounded-lg cursor-pointer hover:bg-gray-50 transition-colors"
                     :class="localConfig.routingStrategy === 'ALL_GCP' ? 'border-primary-600 bg-primary-50' : 'border-gray-300'">
                <input
                  type="radio"
                  v-model="localConfig.routingStrategy"
                  value="ALL_GCP"
                  class="mr-3"
                />
                <div>
                  <div class="font-semibold text-gray-900">☁️ GCP GPU Uniquement</div>
                  <div class="text-sm text-gray-600">
                    Toutes les transcriptions sur GPU NVIDIA T4 (ultra-rapide mais coûteux)
                  </div>
                </div>
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- GCP GPU Configuration -->
      <div class="card" :class="!localConfig.gcpGpuEnabled && 'opacity-50'">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-xl font-semibold">☁️ Configuration GCP GPU</h2>

          <label class="flex items-center cursor-pointer">
            <span class="mr-3 text-sm font-medium text-gray-700">
              Activer GCP GPU
            </span>
            <div class="relative">
              <input
                type="checkbox"
                v-model="localConfig.gcpGpuEnabled"
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-600 peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all"></div>
            </div>
          </label>
        </div>

        <div class="space-y-4" :class="!localConfig.gcpGpuEnabled && 'pointer-events-none'">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Seuil de durée vidéo (mode hybride)
            </label>
            <div class="flex items-center space-x-4">
              <input
                type="range"
                v-model.number="localConfig.videoDurationThreshold"
                min="60"
                max="1800"
                step="60"
                class="flex-1"
                :disabled="localConfig.routingStrategy !== 'HYBRID'"
              />
              <span class="text-gray-900 font-semibold w-24 text-right">
                {{ formatDuration(localConfig.videoDurationThreshold) }}
              </span>
            </div>
            <p class="text-sm text-gray-500 mt-2">
              Vidéos de plus de {{ formatDuration(localConfig.videoDurationThreshold) }} seront traitées par le GPU GCP
            </p>
          </div>

          <div class="p-4 bg-blue-50 rounded-lg">
            <h4 class="font-semibold text-blue-900 mb-2">💡 Recommandations</h4>
            <ul class="text-sm text-blue-800 space-y-1">
              <li>• Vidéos &lt; 5 min: CPU local (gratuit, acceptable)</li>
              <li>• Vidéos 5-30 min: GPU GCP (10x plus rapide)</li>
              <li>• Vidéos &gt; 30 min: GPU GCP obligatoire (temps CPU prohibitif)</li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Whisper Model Configuration -->
      <div class="card">
        <h2 class="text-xl font-semibold mb-6">🤖 Modèle Whisper</h2>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Modèle par défaut
          </label>
          <select v-model="localConfig.defaultWhisperModel" class="input">
            <option value="tiny">Tiny (rapide, moins précis)</option>
            <option value="base">Base (équilibré) ⭐ Recommandé</option>
            <option value="small">Small (plus précis, plus lent)</option>
            <option value="medium">Medium (très précis, 2x plus lent)</option>
            <option value="large-v2">Large v2 (maximum précision, 5x plus lent)</option>
          </select>

          <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div class="p-3 bg-gray-50 rounded">
              <p class="text-gray-600">Taille</p>
              <p class="font-semibold text-gray-900">{{ getModelSize(localConfig.defaultWhisperModel) }}</p>
            </div>
            <div class="p-3 bg-gray-50 rounded">
              <p class="text-gray-600">Temps (1h vidéo)</p>
              <p class="font-semibold text-gray-900">{{ getModelTime(localConfig.defaultWhisperModel) }}</p>
            </div>
            <div class="p-3 bg-gray-50 rounded">
              <p class="text-gray-600">Précision</p>
              <p class="font-semibold text-gray-900">{{ getModelAccuracy(localConfig.defaultWhisperModel) }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Cost Estimation -->
      <div class="card bg-gradient-to-br from-green-50 to-blue-50">
        <h2 class="text-xl font-semibold mb-6">💰 Estimation des Coûts</h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <p class="text-sm text-gray-600 mb-2">Configuration Actuelle</p>
            <p class="text-3xl font-bold text-gray-900">{{ getCostEstimate() }} €/mois</p>
            <p class="text-xs text-gray-500 mt-1">Base: 100 vidéos/mois</p>
          </div>

          <div>
            <p class="text-sm text-gray-600 mb-2">Économies vs Full GCP</p>
            <p class="text-3xl font-bold text-green-600">-{{ getSavingsPercent() }}%</p>
            <p class="text-xs text-gray-500 mt-1">~{{ getSavingsAmount() }} €/mois</p>
          </div>

          <div>
            <p class="text-sm text-gray-600 mb-2">Vitesse Moyenne</p>
            <p class="text-3xl font-bold text-blue-600">{{ getAvgSpeed() }}x</p>
            <p class="text-xs text-gray-500 mt-1">Vs temps réel vidéo</p>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-between">
        <button @click="resetConfig" class="btn btn-secondary">
          ↻ Réinitialiser
        </button>

        <div class="space-x-4">
          <button @click="fetchConfig" class="btn btn-secondary">
            Annuler
          </button>
          <button
            @click="saveConfig"
            :disabled="!hasChanges || isSaving"
            class="btn btn-primary"
          >
            {{ isSaving ? 'Enregistrement...' : '✓ Enregistrer' }}
          </button>
        </div>
      </div>

      <!-- Success message -->
      <div v-if="saveSuccess" class="card bg-green-50 border border-green-200">
        <p class="text-green-800">✅ Configuration enregistrée avec succès!</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useConfigStore } from '@/stores/config'
import type { SystemConfig } from '@/types'

const configStore = useConfigStore()

const localConfig = ref<SystemConfig>({
  gcpGpuEnabled: true,
  routingStrategy: 'HYBRID',
  videoDurationThreshold: 300,
  defaultWhisperModel: 'base'
})

const isSaving = ref(false)
const saveSuccess = ref(false)

onMounted(async () => {
  await configStore.fetchConfig()
  localConfig.value = { ...configStore.config }
})

const hasChanges = computed(() => {
  return JSON.stringify(localConfig.value) !== JSON.stringify(configStore.config)
})

async function saveConfig() {
  isSaving.value = true
  saveSuccess.value = false

  try {
    await configStore.updateConfig(localConfig.value)
    saveSuccess.value = true

    setTimeout(() => {
      saveSuccess.value = false
    }, 3000)
  } catch (err) {
    console.error('Error saving config:', err)
  } finally {
    isSaving.value = false
  }
}

async function fetchConfig() {
  await configStore.fetchConfig()
  localConfig.value = { ...configStore.config }
}

function resetConfig() {
  localConfig.value = {
    gcpGpuEnabled: true,
    routingStrategy: 'HYBRID',
    videoDurationThreshold: 300,
    defaultWhisperModel: 'base'
  }
}

function formatDuration(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  return `${minutes} min`
}

function getModelSize(model: string): string {
  const sizes: Record<string, string> = {
    tiny: '39 MB',
    base: '74 MB',
    small: '244 MB',
    medium: '769 MB',
    'large-v2': '1.5 GB'
  }
  return sizes[model] || 'N/A'
}

function getModelTime(model: string): string {
  const times: Record<string, string> = {
    tiny: '~2 min',
    base: '~3 min',
    small: '~5 min',
    medium: '~8 min',
    'large-v2': '~15 min'
  }
  return times[model] || 'N/A'
}

function getModelAccuracy(model: string): string {
  const accuracy: Record<string, string> = {
    tiny: '★★☆☆☆',
    base: '★★★☆☆',
    small: '★★★★☆',
    medium: '★★★★☆',
    'large-v2': '★★★★★'
  }
  return accuracy[model] || 'N/A'
}

function getCostEstimate(): number {
  // Base: 100 videos/month, avg 10 min/video
  const strategy = localConfig.value.routingStrategy

  if (strategy === 'ALL_LOCAL') {
    return 0 // Proxmox cost not included (hardware already owned)
  } else if (strategy === 'ALL_GCP') {
    return 50 // ~$0.50 per video * 100
  } else {
    // Hybrid: 50% local, 50% GCP
    return 20
  }
}

function getSavingsPercent(): number {
  const current = getCostEstimate()
  const fullGcp = 50
  return Math.round(((fullGcp - current) / fullGcp) * 100)
}

function getSavingsAmount(): number {
  return 50 - getCostEstimate()
}

function getAvgSpeed(): string {
  const strategy = localConfig.value.routingStrategy

  if (strategy === 'ALL_LOCAL') {
    return '2'
  } else if (strategy === 'ALL_GCP') {
    return '10'
  } else {
    return '6' // Average of local and GCP
  }
}
</script>
