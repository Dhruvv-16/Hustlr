import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useClaimStore = create(
  persist(
    (set) => ({
      claims: [],
      payouts: [],
      activeClaim: null,

      setClaims: (claims) => set({ claims }),
      setActiveClaim: (claim) => set({ activeClaim: claim }),
      addPayout: (payout) => set((state) => ({ payouts: [payout, ...state.payouts] })),
    }),
    { name: 'gp-claims' }
  )
)
