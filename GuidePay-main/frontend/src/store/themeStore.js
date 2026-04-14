import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useThemeStore = create(
  persist(
    (set, get) => ({
      isDark: false,
      toggle: () => set({ isDark: !get().isDark }),
      setDark: (val) => set({ isDark: val }),
    }),
    { name: 'gp-theme' }
  )
)
