<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">📤 Upload de Vidéo</h1>

    <!-- Step 1: Project Info -->
    <div v-if="step === 1" class="card">
      <h2 class="text-xl font-semibold mb-6">1. Informations du projet</h2>

      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Nom du projet *
          </label>
          <input
            v-model="projectName"
            type="text"
            placeholder="Ma transcription vidéo"
            class="input"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Description (optionnel)
          </label>
          <textarea
            v-model="projectDescription"
            rows="3"
            placeholder="Description du projet..."
            class="input"
          ></textarea>
        </div>

        <button
          @click="createProject"
          :disabled="!projectName || isCreating"
          class="btn btn-primary w-full"
        >
          {{ isCreating ? 'Création...' : 'Créer le projet' }}
        </button>
      </div>
    </div>

    <!-- Step 2: Video Upload -->
    <div v-if="step === 2" class="card">
      <h2 class="text-xl font-semibold mb-6">2. Upload de la vidéo</h2>

      <!-- Drag and drop zone -->
      <div
        @drop.prevent="handleDrop"
        @dragover.prevent="isDragging = true"
        @dragleave="isDragging = false"
        :class="[
          'border-2 border-dashed rounded-lg p-12 text-center transition-colors',
          isDragging ? 'border-primary-500 bg-primary-50' : 'border-gray-300'
        ]"
      >
        <div v-if="!selectedFile">
          <div class="text-6xl mb-4">🎬</div>
          <p class="text-lg text-gray-700 mb-2">
            Glissez votre vidéo ici ou
          </p>
          <label class="btn btn-secondary cursor-pointer">
            Parcourir
            <input
              ref="fileInput"
              type="file"
              accept="video/*"
              @change="handleFileSelect"
              class="hidden"
            />
          </label>
          <p class="text-sm text-gray-500 mt-4">
            Formats supportés: MP4, MOV, AVI, MKV (max 2GB)
          </p>
        </div>

        <div v-else>
          <div class="text-6xl mb-4">✅</div>
          <p class="text-lg font-semibold text-gray-900">{{ selectedFile.name }}</p>
          <p class="text-sm text-gray-600 mt-2">
            {{ formatFileSize(selectedFile.size) }} • {{ selectedFile.type }}
          </p>
          <button @click="selectedFile = null" class="btn btn-secondary mt-4">
            Changer de fichier
          </button>
        </div>
      </div>

      <!-- Upload progress -->
      <div v-if="uploadProgress" class="mt-6">
        <div class="flex justify-between text-sm text-gray-700 mb-2">
          <span>Upload en cours...</span>
          <span>{{ uploadProgress.percentage }}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div
            class="bg-primary-600 h-2 rounded-full transition-all duration-300"
            :style="{ width: uploadProgress.percentage + '%' }"
          ></div>
        </div>
        <p class="text-xs text-gray-500 mt-2">
          {{ formatFileSize(uploadProgress.loaded) }} / {{ formatFileSize(uploadProgress.total) }}
        </p>
      </div>

      <!-- Actions -->
      <div class="flex space-x-4 mt-6">
        <button @click="step = 1" class="btn btn-secondary flex-1">
          ← Retour
        </button>
        <button
          @click="uploadVideo"
          :disabled="!selectedFile || isUploading"
          class="btn btn-primary flex-1"
        >
          {{ isUploading ? 'Upload en cours...' : 'Upload et Transcrire' }}
        </button>
      </div>
    </div>

    <!-- Step 3: Success -->
    <div v-if="step === 3" class="card text-center">
      <div class="text-6xl mb-4">🎉</div>
      <h2 class="text-2xl font-bold text-gray-900 mb-4">
        Transcription en cours!
      </h2>
      <p class="text-gray-600 mb-8">
        Votre vidéo a été uploadée avec succès. La transcription va démarrer automatiquement.
      </p>

      <div class="space-x-4">
        <router-link :to="`/projects/${createdProjectId}`" class="btn btn-primary">
          Voir le projet
        </router-link>
        <router-link to="/projects" class="btn btn-secondary">
          Retour aux projets
        </router-link>
      </div>
    </div>

    <!-- Error message -->
    <div v-if="error" class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
      <p class="text-red-800">❌ {{ error }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useProjectsStore } from '@/stores/projects'
import type { UploadProgress } from '@/types'

const projectsStore = useProjectsStore()

const step = ref(1)
const projectName = ref('')
const projectDescription = ref('')
const selectedFile = ref<File | null>(null)
const isDragging = ref(false)
const isCreating = ref(false)
const isUploading = ref(false)
const uploadProgress = ref<UploadProgress | null>(null)
const createdProjectId = ref<string | null>(null)
const error = ref<string | null>(null)

async function createProject() {
  if (!projectName.value) return

  isCreating.value = true
  error.value = null

  try {
    const project = await projectsStore.create({
      name: projectName.value,
      description: projectDescription.value
    })

    createdProjectId.value = project.id
    step.value = 2
  } catch (err: any) {
    error.value = err.message || 'Erreur lors de la création du projet'
  } finally {
    isCreating.value = false
  }
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    selectedFile.value = target.files[0]
  }
}

function handleDrop(event: DragEvent) {
  isDragging.value = false

  if (event.dataTransfer?.files && event.dataTransfer.files.length > 0) {
    selectedFile.value = event.dataTransfer.files[0]
  }
}

async function uploadVideo() {
  if (!selectedFile.value || !createdProjectId.value) return

  isUploading.value = true
  error.value = null

  try {
    await projectsStore.uploadVideo(createdProjectId.value, selectedFile.value)

    // Get upload progress
    const interval = setInterval(() => {
      const progress = projectsStore.getUploadProgress(createdProjectId.value!)
      if (progress) {
        uploadProgress.value = progress
        if (progress.percentage === 100) {
          clearInterval(interval)
          setTimeout(() => {
            step.value = 3
            isUploading.value = false
          }, 1000)
        }
      }
    }, 100)
  } catch (err: any) {
    error.value = err.message || "Erreur lors de l'upload de la vidéo"
    isUploading.value = false
  }
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
}
</script>
