// Project types
export interface Project {
  id: string
  name: string
  description?: string
  videoUrl: string
  status: ProjectStatus
  createdAt: string
  updatedAt: string
  transcription?: Transcription
  processingMetrics?: ProcessingMetrics
  workerType?: WorkerType
}

export enum ProjectStatus {
  PENDING = 'PENDING',
  UPLOADING = 'UPLOADING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED'
}

export enum WorkerType {
  CPU_LOCAL = 'CPU_LOCAL',
  GPU_GCP = 'GPU_GCP'
}

export interface Transcription {
  id: string
  projectId: string
  text: string
  language: string
  segments?: TranscriptionSegment[]
  createdAt: string
}

export interface TranscriptionSegment {
  id: number
  start: number
  end: number
  text: string
}

export interface ProcessingMetrics {
  videoDuration: number
  processingTime: number
  workerType: WorkerType
  modelUsed: string
  startedAt: string
  completedAt?: string
  cost?: number
}

// Upload types
export interface UploadProgress {
  projectId: string
  loaded: number
  total: number
  percentage: number
}

// Configuration types
export interface SystemConfig {
  gcpGpuEnabled: boolean
  routingStrategy: RoutingStrategy
  videoDurationThreshold: number
  defaultWhisperModel: string
}

export enum RoutingStrategy {
  ALL_LOCAL = 'ALL_LOCAL',
  ALL_GCP = 'ALL_GCP',
  HYBRID = 'HYBRID'
}

// Dashboard types
export interface DashboardStats {
  totalProjects: number
  completedProjects: number
  processingProjects: number
  failedProjects: number
  avgProcessingTime: number
  totalCost: number
  cpuUsage: number
  gpuUsage: number
}

export interface PerformanceMetric {
  timestamp: string
  workerType: WorkerType
  videoDuration: number
  processingTime: number
  cost: number
}

// Auth types
export interface User {
  id: string
  username: string
  email: string
  roles: string[]
  firstName?: string
  lastName?: string
}

// API Response types
export interface ApiResponse<T> {
  data: T
  message?: string
  timestamp: string
}

export interface ApiError {
  message: string
  code: string
  timestamp: string
}
