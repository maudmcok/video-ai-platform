<template>
  <div class="max-w-7xl mx-auto px-4 py-8">
    <!-- Loading state -->
    <div v-if="isLoading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      <p class="mt-4 text-gray-600">Chargement...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="card bg-red-50 border border-red-200">
      <p class="text-red-800">❌ {{ error }}</p>
      <router-link to="/projects" class="btn btn-secondary mt-4">
        ← Retour aux projets
      </router-link>
    </div>

    <!-- Project content -->
    <div v-else-if="project" class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-start">
        <div>
          <router-link to="/projects" class="text-primary-600 hover:text-primary-800 mb-2 inline-block">
            ← Retour aux projets
          </router-link>
          <h1 class="text-3xl font-bold text-gray-900">{{ project.name }}</h1>
          <p v-if="project.description" class="text-gray-600 mt-2">{{ project.description }}</p>
        </div>

        <div class="flex items-center space-x-2">
          <span
            :class="['px-3 py-1 rounded-full text-sm font-semibold', getStatusClass(project.status)]"
          >
            {{ getStatusLabel(project.status) }}
          </span>
        </div>
      </div>

      <!-- Video Player -->
      <div class="card">
        <h2 class="text-xl font-semibold mb-4">📹 Vidéo</h2>

        <div v-if="project.videoUrl" class="bg-black rounded-lg overflow-hidden">
          <video
            ref="videoPlayer"
            :src="project.videoUrl"
            controls
            class="w-full"
            @loadedmetadata="onVideoLoaded"
          >
            Votre navigateur ne supporte pas la lecture vidéo.
          </video>
        </div>

        <div v-else class="text-center py-12 text-gray-500">
          Aucune vidéo disponible
        </div>

        <!-- Video info -->
        <div v-if="videoDuration" class="mt-4 text-sm text-gray-600">
          Durée: {{ formatDuration(videoDuration) }}
        </div>
      </div>

      <!-- Processing Metrics -->
      <div v-if="project.processingMetrics" class="card">
        <h2 class="text-xl font-semibold mb-4">📊 Métriques de Traitement</h2>

        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <p class="text-sm text-gray-600">Type de Worker</p>
            <p :class="['text-lg font-semibold', getWorkerClass(project.processingMetrics.workerType)]">
              {{ getWorkerLabel(project.processingMetrics.workerType) }}
            </p>
          </div>

          <div>
            <p class="text-sm text-gray-600">Modèle Utilisé</p>
            <p class="text-lg font-semibold text-gray-900">
              {{ project.processingMetrics.modelUsed }}
            </p>
          </div>

          <div>
            <p class="text-sm text-gray-600">Temps de Traitement</p>
            <p class="text-lg font-semibold text-gray-900">
              {{ formatDuration(project.processingMetrics.processingTime) }}
            </p>
          </div>

          <div v-if="project.processingMetrics.cost">
            <p class="text-sm text-gray-600">Coût</p>
            <p class="text-lg font-semibold text-green-600">
              {{ project.processingMetrics.cost.toFixed(4) }} €
            </p>
          </div>
        </div>

        <!-- Performance indicator -->
        <div v-if="project.processingMetrics.videoDuration" class="mt-4 p-3 bg-blue-50 rounded-lg">
          <p class="text-sm text-blue-800">
            ⚡ Vitesse de traitement:
            <strong>{{ getProcessingSpeed(project.processingMetrics) }}x</strong>
            ({{ formatDuration(project.processingMetrics.videoDuration) }} de vidéo traités en
            {{ formatDuration(project.processingMetrics.processingTime) }})
          </p>
        </div>
      </div>

      <!-- Transcription -->
      <div class="card">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-semibold">📝 Transcription</h2>

          <div v-if="project.transcription" class="space-x-2">
            <button @click="exportTranscription('txt')" class="btn btn-secondary text-sm">
              📄 TXT
            </button>
            <button @click="exportTranscription('srt')" class="btn btn-secondary text-sm">
              🎬 SRT
            </button>
            <button @click="exportTranscription('vtt')" class="btn btn-secondary text-sm">
              📹 VTT
            </button>
          </div>
        </div>

        <!-- Processing state -->
        <div v-if="project.status === 'PROCESSING'" class="text-center py-12">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          <p class="mt-4 text-gray-600">Transcription en cours...</p>
          <p class="text-sm text-gray-500 mt-2">Cela peut prendre quelques minutes</p>
        </div>

        <!-- Transcription content -->
        <div v-else-if="project.transcription" class="space-y-4">
          <!-- Full text -->
          <div class="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
            <p class="text-gray-800 whitespace-pre-wrap leading-relaxed">
              {{ project.transcription.text }}
            </p>
          </div>

          <!-- Segments (if available) -->
          <div v-if="project.transcription.segments && project.transcription.segments.length > 0">
            <h3 class="font-semibold text-gray-900 mb-2">Segments (avec timestamps)</h3>
            <div class="space-y-2 max-h-64 overflow-y-auto">
              <div
                v-for="segment in project.transcription.segments"
                :key="segment.id"
                class="flex gap-4 p-2 hover:bg-gray-50 rounded cursor-pointer"
                @click="seekToTime(segment.start)"
              >
                <span class="text-sm text-gray-500 font-mono whitespace-nowrap">
                  {{ formatTimestamp(segment.start) }}
                </span>
                <span class="text-sm text-gray-800">{{ segment.text }}</span>
              </div>
            </div>
          </div>

          <!-- Info -->
          <div class="text-sm text-gray-500">
            Langue détectée: {{ project.transcription.language || 'Français' }}
          </div>
        </div>

        <!-- No transcription -->
        <div v-else class="text-center py-12 text-gray-500">
          <p>Aucune transcription disponible</p>
          <button v-if="project.status === 'COMPLETED'" class="btn btn-primary mt-4">
            Relancer la transcription
          </button>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end space-x-4">
        <button @click="deleteProject" class="btn btn-danger">
          🗑️ Supprimer le projet
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useProjectsStore } from '@/stores/projects'
import { projectsService } from '@/services/projects'
import type { Project, ProjectStatus, WorkerType, ProcessingMetrics } from '@/types'

const route = useRoute()
const router = useRouter()
const projectsStore = useProjectsStore()

const project = ref<Project | null>(null)
const isLoading = ref(true)
const error = ref<string | null>(null)
const videoDuration = ref<number | null>(null)
const videoPlayer = ref<HTMLVideoElement | null>(null)

onMounted(async () => {
  const projectId = route.params.id as string
  await loadProject(projectId)

  // Poll for updates if processing
  if (project.value?.status === 'PROCESSING') {
    startPolling()
  }
})

onUnmounted(() => {
  stopPolling()
})

let pollingInterval: number | null = null

function startPolling() {
  if (pollingInterval) return

  pollingInterval = window.setInterval(async () => {
    const projectId = route.params.id as string
    await loadProject(projectId)

    // Stop polling when completed or failed
    if (project.value && ['COMPLETED', 'FAILED'].includes(project.value.status)) {
      stopPolling()
    }
  }, 5000)
}

function stopPolling() {
  if (pollingInterval) {
    clearInterval(pollingInterval)
    pollingInterval = null
  }
}

async function loadProject(id: string) {
  try {
    project.value = await projectsStore.fetchById(id)
    isLoading.value = false
  } catch (err: any) {
    error.value = err.message || 'Failed to load project'
    isLoading.value = false
  }
}

function onVideoLoaded() {
  if (videoPlayer.value) {
    videoDuration.value = videoPlayer.value.duration
  }
}

function seekToTime(seconds: number) {
  if (videoPlayer.value) {
    videoPlayer.value.currentTime = seconds
    videoPlayer.value.play()
  }
}

async function exportTranscription(format: 'txt' | 'srt' | 'vtt') {
  if (!project.value) return

  try {
    const blob = await projectsService.exportTranscription(project.value.id, format)
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${project.value.name}.${format}`
    document.body.appendChild(a)
    a.click()
    window.URL.revokeObjectURL(url)
    document.body.removeChild(a)
  } catch (err: any) {
    error.value = `Erreur lors de l'export: ${err.message}`
  }
}

async function deleteProject() {
  if (!project.value) return

  if (confirm(`Êtes-vous sûr de vouloir supprimer le projet "${project.value.name}" ?`)) {
    try {
      await projectsStore.deleteProject(project.value.id)
      router.push('/projects')
    } catch (err: any) {
      error.value = `Erreur lors de la suppression: ${err.message}`
    }
  }
}

function getStatusLabel(status: ProjectStatus): string {
  const labels: Record<ProjectStatus, string> = {
    PENDING: 'En attente',
    UPLOADING: 'Upload',
    PROCESSING: 'Traitement',
    COMPLETED: 'Terminé',
    FAILED: 'Échec'
  }
  return labels[status] || status
}

function getStatusClass(status: ProjectStatus): string {
  const classes: Record<ProjectStatus, string> = {
    PENDING: 'bg-gray-100 text-gray-800',
    UPLOADING: 'bg-blue-100 text-blue-800',
    PROCESSING: 'bg-yellow-100 text-yellow-800',
    COMPLETED: 'bg-green-100 text-green-800',
    FAILED: 'bg-red-100 text-red-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

function getWorkerLabel(workerType: WorkerType): string {
  return workerType === 'GPU_GCP' ? '⚡ GPU GCP' : '💻 CPU Local'
}

function getWorkerClass(workerType: WorkerType): string {
  return workerType === 'GPU_GCP' ? 'text-green-600' : 'text-blue-600'
}

function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = Math.floor(seconds % 60)

  if (hours > 0) {
    return `${hours}h ${minutes}m ${secs}s`
  } else if (minutes > 0) {
    return `${minutes}m ${secs}s`
  } else {
    return `${secs}s`
  }
}

function formatTimestamp(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

function getProcessingSpeed(metrics: ProcessingMetrics): string {
  if (!metrics.videoDuration || !metrics.processingTime) return 'N/A'
  const speed = metrics.videoDuration / metrics.processingTime
  return speed.toFixed(1)
}
</script>
