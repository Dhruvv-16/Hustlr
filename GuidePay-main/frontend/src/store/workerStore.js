import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useWorkerStore = create(
  persist(
    (set, get) => ({
      // Auth
      worker: null,
      isAuthenticated: false,
      phone: '',

      // Policy — CRITICAL for payment fix
      activePolicy: null,

      // Profile
      profileBg: 'plain',
      onboarded: false,
      showTour: false,

      // Data
      riskScore: null,
      claims: [],
      notifications: [],
      detectedCity: null,
      language: 'en',

      // Setters
      setWorker: (worker) => set({ worker }),
      setAuthenticated: (val) => set({ isAuthenticated: val }),
      setPhone: (phone) => set({ phone }),
      setLanguage: (lang) => set({ language: lang }),

      // THIS IS THE CRITICAL ONE:
      setActivePolicy: (policy) => {
        console.log('Setting active policy:', policy)
        set({ activePolicy: policy })
      },

      clearPolicy: () => set({ activePolicy: null }),
      setProfileBg: (bg) => set({ profileBg: bg }),
      setOnboarded: (val = true) => set({ onboarded: val }),
      setShowTour: (val) => set({ showTour: val }),
      setRiskScore: (score) => set({ riskScore: score }),
      setClaims: (claims) => set({ claims }),
      setNotifications: (notifications) => set((state) => ({
        notifications: typeof notifications === 'function'
          ? notifications(state.notifications)
          : notifications,
      })),
      setDetectedCity: (city) => set({ detectedCity: city }),
      addNotification: (notif) => set(state => ({
        notifications: [notif, ...state.notifications].slice(0, 20)
      })),

      login: (workerData) => set({
        worker: workerData,
        isAuthenticated: true,
      }),

      updateWorker: (data) => set((state) => ({
        worker: { ...state.worker, ...data },
      })),

      logout: () => set({
        worker: null,
        isAuthenticated: false,
        phone: '',
        activePolicy: null,
        onboarded: false,
        riskScore: null,
        claims: [],
        notifications: [],
        detectedCity: null,
        profileBg: 'plain',
        language: 'en',
      }),
    }),
    {
      name: 'guidepay-store',
      // Persist everything including activePolicy
    }
  )
)

export default useWorkerStore
