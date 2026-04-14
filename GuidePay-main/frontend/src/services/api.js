import axios from 'axios'

const rawApiUrl = import.meta.env.VITE_API_URL
const isPlaceholderUrl =
  !rawApiUrl ||
  rawApiUrl.includes('your-railway-app') ||
  rawApiUrl.includes('your-app.onrender.com') ||
  rawApiUrl.includes('your-render-url.onrender.com')

const BASE_URL = isPlaceholderUrl ? 'http://127.0.0.1:8000' : rawApiUrl.replace(/\/$/, '')
export const API_URL = `${BASE_URL}/api/v1`
export const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true'

export const workerApi = axios.create({
  baseURL: API_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
})

export const adminApi = axios.create({
  baseURL: API_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
})

const isTimeoutError = (error) =>
  error?.code === 'ECONNABORTED' || error?.name === 'AbortError' || /timeout/i.test(error?.message || '')

const requestWithRetry = async (apiInstance, requestFn, retries = 1) => {
  let lastError
  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      return await requestFn()
    } catch (error) {
      lastError = error
      if (attempt === retries || !isTimeoutError(error)) {
        throw error
      }
    }
  }
  throw lastError
}

workerApi.interceptors.request.use((config) => {
  const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

adminApi.interceptors.request.use((config) => {
  const token = localStorage.getItem('gp-admin-token') || localStorage.getItem('gp-admin-access-token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

const errorHandler = (isAdmin) => (error) => {
  console.error('[API ERROR]', error?.response?.status, error?.message)
  if (error.response?.status === 401) {
    if (isAdmin) {
      localStorage.removeItem('gp-admin-token')
      localStorage.removeItem('gp-admin-access-token')
      if (!window.location.pathname.includes('/admin/login')) window.location.href = '/admin/login'
    } else {
      localStorage.removeItem('gp-token')
      localStorage.removeItem('gp-access-token')
      if (!window.location.pathname.includes('/login')) window.location.href = '/login'
    }
  }
  return Promise.reject(error.response?.data || error)
}

workerApi.interceptors.response.use((r) => r.data, errorHandler(false))
adminApi.interceptors.response.use((r) => r.data, errorHandler(true))

export const loginWithFirebase = (token, name, phone) => workerApi.post('/auth/login', { firebase_token: token, name, phone })
export const getUserByUid = (uid) => workerApi.get(`/auth/user/${uid}`)
export const createUserProfile = (data) => workerApi.post('/auth/create-user', data)
export const adminLogin = (username, password) => adminApi.post('/auth/admin/login', { username, password })

export const api = {
  async getWorker(id) { return workerApi.get(`/workers/${id}`) },
}

export const getMyProfile = () => requestWithRetry(workerApi, () => workerApi.get('/workers/me'))
export const updateMyProfile = (data) => workerApi.put('/workers/me', data)
export const getMyRiskScore = () => workerApi.get('/workers/me/risk-score')
export const getMyPremiumBreakdown = (zone) => workerApi.get('/workers/me/premium-breakdown', { params: { zone } })
export const getZonePremiumCompare = () => workerApi.get('/workers/premium-compare')
export const getMyEarnings = () => workerApi.get('/workers/me/earnings')
export const getCommunityStats = () => adminApi.get('/admin/community-stats')
export const updateLastOrder = () => workerApi.post('/workers/me/update-last-order')
export const getWellnessScore = () => workerApi.get('/workers/wellness-score')
export const getEarningsShieldSummary = () => workerApi.get('/workers/earnings-shield-summary')
export const getEarningsIntelligence = () => workerApi.get('/workers/earnings-intelligence')
export const getSmartNotifications = () => workerApi.get('/workers/me/notifications')
export const getFeatureImportance = () => workerApi.get('/ml/feature-importance')
export const getFraudFeatureImportance = () => workerApi.get('/ml/fraud-feature-importance')
export const getActuarialMetrics = () => adminApi.get('/admin/actuarial-metrics')

export const getActivePolicy = () => workerApi.get('/policies/my/active')
export const getZoneHistory = () => workerApi.get('/workers/zone-history')
export const getMyPolicies = () => workerApi.get('/policies/my')
export const downloadProtectionCertificate = async (policyId) => {
  try {
    const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')
    const response = await axios.get(`${API_URL}/policies/${policyId}/certificate`, {
      responseType: 'blob',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    })

    const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }))
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `GuidePay_Protection_Certificate_${policyId}.pdf`)
    document.body.appendChild(link)
    link.click()
    link.parentNode.removeChild(link)
    window.URL.revokeObjectURL(url)
    return { success: true }
  } catch (error) {
    console.error('Certificate download failed:', error)
    throw error
  }
}

export const createPaymentOrder = (planId, amount = 0) => workerApi.post('/payments/create-order', { plan_id: planId, amount })
export const verifyPayment = (data) => workerApi.post('/payments/verify', data)

export const getMyClaims = (status, limit = 20, skip = 0) => workerApi.get('/claims/my', { params: { status, limit, skip } })
export const getClaimDetail = (id) => workerApi.get(`/claims/${id}`)
export const getClaimAuditTrail = (claimId) => workerApi.get(`/claims/${claimId}/audit-trail`)

export const getActiveTriggers = () => workerApi.get('/triggers/active')
export const getMyZoneTriggers = () => workerApi.get('/triggers/my-zone')
export const getTriggerTypes = () => workerApi.get('/triggers/types')

export const getZoneForecast = () => workerApi.get('/forecast/zones')
export const getMyZoneForecast = () => workerApi.get('/forecast/my-zone')
export const getZoneIntel = (zone) => workerApi.get(`/forecast/zone-intel/${zone}`)

export const getMyNotifications = () => workerApi.get('/notifications/me')
export const markNotificationRead = (id) => workerApi.patch(`/notifications/me/${id}/read`)
export const markAllNotificationsRead = () => workerApi.patch('/notifications/me/read-all')

export const getMySupportTickets = () => workerApi.get('/support/my')
export const createSupportTicket = (data) => workerApi.post('/support/my', data)
export const getSupportTicket = (ticketId) => workerApi.get(`/support/my/${ticketId}`)
export const sendSupportMessage = (ticketId, text) => workerApi.post(`/support/my/${ticketId}/messages`, { text })

export const getAdminStats = () => adminApi.get('/admin/stats')
export const getActuarialSummary = () => adminApi.get('/actuarial/summary')
export const getActuarialExposure = () => adminApi.get('/actuarial/exposure')
export const getActuarialReserve = () => adminApi.get('/actuarial/reserve')
export const simulateActuarialScenario = (payload) => adminApi.post('/actuarial/simulate', payload)
export const getClaimsQueue = (status = 'ALL') => adminApi.get('/admin/claims/queue', { params: { status } })
export const getAdminClaims = (params) => adminApi.get('/admin/claims/queue', { params });
export const getAdminAnalytics = (days = 30) => adminApi.get('/admin/analytics', { params: { days } })
export const getAnalytics = getAdminAnalytics
export const getWorkers = (status = 'ALL', search = '', limit = 50, skip = 0) => adminApi.get('/admin/workers', { params: { status, search, limit, skip } })
export const approveClaim = (id) => adminApi.post(`/admin/claims/${id}/approve`)
export const rejectClaim = (id, reason) => adminApi.post(`/admin/claims/${id}/reject`, null, { params: { reason } })
export const getAdminDashboardStats = () => adminApi.get('/admin/dashboard-stats');
export const getZoneRiskMonitor = () => adminApi.get('/admin/zone-risk-monitor');
export const getFraudAnalytics = () => adminApi.get('/admin/fraud-analytics');
export const simulateTrigger = (city, type) => adminApi.post('/admin/simulate-trigger', { city, trigger_type: type }, { timeout: 60000 })
export const getAdminSupportTickets = (status = 'all') => adminApi.get('/support/admin/tickets', { params: { status } })
export const sendAdminSupportMessage = (ticketId, text) => adminApi.post(`/support/admin/tickets/${ticketId}/messages`, { text })
export const updateAdminSupportStatus = (ticketId, status) => adminApi.patch(`/support/admin/tickets/${ticketId}/status`, { status })

export default workerApi
