import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { projectsService } from '@/services/projects'
import type { Project, UploadProgress, ProjectStatus } from '@/types'

export const useProjectsStore = defineStore('projects', () => {
  const projects = ref<Project[]>([])
  const currentProject = ref<Project | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const uploadProgress = ref<Map<string, UploadProgress>>(new Map())

  const completedProjects = computed(() =>
    projects.value.filter((p) => p.status === 'COMPLETED')
  )

  const processingProjects = computed(() =>
    projects.value.filter((p) => p.status === 'PROCESSING' || p.status === 'UPLOADING')
  )

  const failedProjects = computed(() => projects.value.filter((p) => p.status === 'FAILED'))

  async function fetchAll() {
    isLoading.value = true
    error.value = null
    try {
      projects.value = await projectsService.getAll()
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch projects'
      console.error('Error fetching projects:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchById(id: string) {
    isLoading.value = true
    error.value = null
    try {
      currentProject.value = await projectsService.getById(id)
      return currentProject.value
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch project'
      console.error('Error fetching project:', err)
      return null
    } finally {
      isLoading.value = false
    }
  }

  async function create(data: { name: string; description?: string }) {
    isLoading.value = true
    error.value = null
    try {
      const project = await projectsService.create(data)
      projects.value.unshift(project)
      return project
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to create project'
      console.error('Error creating project:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function uploadVideo(projectId: string, file: File) {
    error.value = null
    try {
      await projectsService.uploadVideo(projectId, file, (progress) => {
        uploadProgress.value.set(projectId, progress)
      })

      // Update project status
      const project = projects.value.find((p) => p.id === projectId)
      if (project) {
        project.status = 'PROCESSING' as ProjectStatus
      }

      // Clear upload progress after a delay
      setTimeout(() => {
        uploadProgress.value.delete(projectId)
      }, 2000)
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to upload video'
      console.error('Error uploading video:', err)
      uploadProgress.value.delete(projectId)
      throw err
    }
  }

  async function startTranscription(projectId: string) {
    error.value = null
    try {
      await projectsService.startTranscription(projectId)
      const project = projects.value.find((p) => p.id === projectId)
      if (project) {
        project.status = 'PROCESSING' as ProjectStatus
      }
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to start transcription'
      console.error('Error starting transcription:', err)
      throw err
    }
  }

  async function deleteProject(id: string) {
    error.value = null
    try {
      await projectsService.delete(id)
      projects.value = projects.value.filter((p) => p.id !== id)
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to delete project'
      console.error('Error deleting project:', err)
      throw err
    }
  }

  function getUploadProgress(projectId: string): UploadProgress | undefined {
    return uploadProgress.value.get(projectId)
  }

  // Polling for project updates (for real-time status)
  let pollingInterval: number | null = null

  function startPolling(intervalMs: number = 5000) {
    if (pollingInterval) return

    pollingInterval = window.setInterval(() => {
      if (processingProjects.value.length > 0) {
        fetchAll()
      }
    }, intervalMs)
  }

  function stopPolling() {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
  }

  return {
    projects,
    currentProject,
    isLoading,
    error,
    completedProjects,
    processingProjects,
    failedProjects,
    fetchAll,
    fetchById,
    create,
    uploadVideo,
    startTranscription,
    deleteProject,
    getUploadProgress,
    startPolling,
    stopPolling
  }
})
