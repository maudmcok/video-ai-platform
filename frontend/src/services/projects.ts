import { apiService } from './api'
import type { Project, ApiResponse, UploadProgress } from '@/types'

export class ProjectsService {
  private basePath = '/projects'

  async getAll(): Promise<Project[]> {
    const response = await apiService.get<ApiResponse<Project[]>>(this.basePath)
    return response.data.data
  }

  async getById(id: string): Promise<Project> {
    const response = await apiService.get<ApiResponse<Project>>(`${this.basePath}/${id}`)
    return response.data.data
  }

  async create(data: { name: string; description?: string }): Promise<Project> {
    const response = await apiService.post<ApiResponse<Project>>(this.basePath, data)
    return response.data.data
  }

  async update(id: string, data: Partial<Project>): Promise<Project> {
    const response = await apiService.put<ApiResponse<Project>>(`${this.basePath}/${id}`, data)
    return response.data.data
  }

  async delete(id: string): Promise<void> {
    await apiService.delete(`${this.basePath}/${id}`)
  }

  async uploadVideo(
    projectId: string,
    file: File,
    onProgress?: (progress: UploadProgress) => void
  ): Promise<void> {
    const formData = new FormData()
    formData.append('file', file)

    await apiService.post(`${this.basePath}/${projectId}/upload`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          const progress: UploadProgress = {
            projectId,
            loaded: progressEvent.loaded,
            total: progressEvent.total,
            percentage: Math.round((progressEvent.loaded * 100) / progressEvent.total)
          }
          onProgress(progress)
        }
      }
    })
  }

  async startTranscription(projectId: string): Promise<void> {
    await apiService.post(`${this.basePath}/${projectId}/transcribe`)
  }

  async getTranscription(projectId: string): Promise<string> {
    const response = await apiService.get<ApiResponse<{ text: string }>>(
      `${this.basePath}/${projectId}/transcription`
    )
    return response.data.data.text
  }

  async exportTranscription(projectId: string, format: 'txt' | 'srt' | 'vtt'): Promise<Blob> {
    const response = await apiService.get(`${this.basePath}/${projectId}/export`, {
      params: { format },
      responseType: 'blob'
    })
    return response.data
  }
}

export const projectsService = new ProjectsService()
