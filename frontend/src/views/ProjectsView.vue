<template>
  <div class="max-w-7xl mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900">📁 Mes Projets</h1>

      <router-link to="/upload" class="btn btn-primary">
        + Nouveau Projet
      </router-link>
    </div>

    <!-- Stats Overview -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
      <div class="card">
        <p class="text-sm text-gray-600">Total</p>
        <p class="text-3xl font-bold text-gray-900">{{ projectsStore.projects.length }}</p>
      </div>

      <div class="card">
        <p class="text-sm text-gray-600">Complétés</p>
        <p class="text-3xl font-bold text-green-600">{{ projectsStore.completedProjects.length }}</p>
      </div>

      <div class="card">
        <p class="text-sm text-gray-600">En cours</p>
        <p class="text-3xl font-bold text-blue-600">{{ projectsStore.processingProjects.length }}</p>
      </div>

      <div class="card">
        <p class="text-sm text-gray-600">Échecs</p>
        <p class="text-3xl font-bold text-red-600">{{ projectsStore.failedProjects.length }}</p>
      </div>
    </div>

    <!-- Loading state -->
    <div v-if="projectsStore.isLoading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      <p class="mt-4 text-gray-600">Chargement des projets...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="projectsStore.error" class="card bg-red-50 border border-red-200">
      <p class="text-red-800">❌ {{ projectsStore.error }}</p>
      <button @click="projectsStore.fetchAll()" class="btn btn-secondary mt-4">
        Réessayer
      </button>
    </div>

    <!-- Empty state -->
    <div v-else-if="projectsStore.projects.length === 0" class="card text-center py-12">
      <div class="text-6xl mb-4">📭</div>
      <h2 class="text-2xl font-bold text-gray-900 mb-4">Aucun projet</h2>
      <p class="text-gray-600 mb-8">
        Commencez par uploader votre première vidéo pour la transcrire.
      </p>
      <router-link to="/upload" class="btn btn-primary">
        Créer mon premier projet
      </router-link>
    </div>

    <!-- Projects table -->
    <div v-else class="card overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Projet
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Statut
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Worker
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Date
              </th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="project in projectsStore.projects" :key="project.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div>
                  <div class="text-sm font-medium text-gray-900">{{ project.name }}</div>
                  <div v-if="project.description" class="text-sm text-gray-500">
                    {{ truncate(project.description, 50) }}
                  </div>
                </div>
              </td>

              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full',
                    getStatusClass(project.status)
                  ]"
                >
                  {{ getStatusLabel(project.status) }}
                </span>
              </td>

              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <span v-if="project.workerType" :class="getWorkerClass(project.workerType)">
                  {{ getWorkerLabel(project.workerType) }}
                </span>
                <span v-else class="text-gray-400">-</span>
              </td>

              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(project.createdAt) }}
              </td>

              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                <router-link
                  :to="`/projects/${project.id}`"
                  class="text-primary-600 hover:text-primary-900"
                >
                  Voir
                </router-link>
                <button
                  @click="deleteProject(project.id)"
                  class="text-red-600 hover:text-red-900"
                >
                  Supprimer
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useProjectsStore } from '@/stores/projects'
import type { ProjectStatus, WorkerType } from '@/types'

const projectsStore = useProjectsStore()

onMounted(async () => {
  await projectsStore.fetchAll()
  // Start polling for real-time updates
  projectsStore.startPolling(5000) // Poll every 5 seconds
})

onUnmounted(() => {
  projectsStore.stopPolling()
})

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
  return workerType === 'GPU_GCP'
    ? 'text-green-600 font-semibold'
    : 'text-blue-600'
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

function truncate(text: string, length: number): string {
  return text.length > length ? text.substring(0, length) + '...' : text
}

async function deleteProject(id: string) {
  if (confirm('Êtes-vous sûr de vouloir supprimer ce projet ?')) {
    await projectsStore.deleteProject(id)
  }
}
</script>
