import { defineStore } from 'pinia'
import { ref } from 'vue'
import { apiService } from '@/services/api'
import type { SystemConfig, RoutingStrategy, DashboardStats, PerformanceMetric } from '@/types'

export const useConfigStore = defineStore('config', () => {
  const config = ref<SystemConfig>({
    gcpGpuEnabled: true,
    routingStrategy: 'HYBRID' as RoutingStrategy,
    videoDurationThreshold: 300, // 5 minutes in seconds
    defaultWhisperModel: 'base'
  })

  const dashboardStats = ref<DashboardStats | null>(null)
  const performanceMetrics = ref<PerformanceMetric[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  async function fetchConfig() {
    isLoading.value = true
    error.value = null
    try {
      const response = await apiService.get<{ data: SystemConfig }>('/admin/config')
      config.value = response.data.data
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch configuration'
      console.error('Error fetching config:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function updateConfig(newConfig: Partial<SystemConfig>) {
    isLoading.value = true
    error.value = null
    try {
      const response = await apiService.put<{ data: SystemConfig }>('/admin/config', newConfig)
      config.value = response.data.data
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to update configuration'
      console.error('Error updating config:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function fetchDashboardStats() {
    isLoading.value = true
    error.value = null
    try {
      const response = await apiService.get<{ data: DashboardStats }>('/admin/stats')
      dashboardStats.value = response.data.data
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch dashboard stats'
      console.error('Error fetching stats:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchPerformanceMetrics(from?: string, to?: string) {
    isLoading.value = true
    error.value = null
    try {
      const params: any = {}
      if (from) params.from = from
      if (to) params.to = to

      const response = await apiService.get<{ data: PerformanceMetric[] }>('/admin/metrics', {
        params
      })
      performanceMetrics.value = response.data.data
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch performance metrics'
      console.error('Error fetching metrics:', err)
    } finally {
      isLoading.value = false
    }
  }

  // Polling for dashboard updates
  let pollingInterval: number | null = null

  function startPolling(intervalMs: number = 10000) {
    if (pollingInterval) return

    pollingInterval = window.setInterval(() => {
      fetchDashboardStats()
    }, intervalMs)
  }

  function stopPolling() {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
  }

  return {
    config,
    dashboardStats,
    performanceMetrics,
    isLoading,
    error,
    fetchConfig,
    updateConfig,
    fetchDashboardStats,
    fetchPerformanceMetrics,
    startPolling,
    stopPolling
  }
})
