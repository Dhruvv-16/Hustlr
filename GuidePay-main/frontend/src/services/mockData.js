export const MOCK_WORKER = {
  id: 'w-001',
  name: 'Ravi Kumar',
  phone: '+919876543210',
  zone: 'kondapur-hyderabad',
  city: 'Hyderabad',
  platforms: ['zepto', 'swiggy'],
  riskScore: 0.82,
  riskTier: 'LOW',
  premium: 58,
  coverageCap: 600,
  joinedAt: '2026-03-04',
  policyStatus: 'ACTIVE',
  weekStart: '2026-03-21',
  weekEnd: '2026-03-27',
}

export const MOCK_FORECAST = [
  {
    city: 'Hyderabad', zone: 'Kondapur',
    probability: 78, risk: 'HIGH',
    rainfall: 42, elevation: 487, events: 9, monsoon: 0.84,
  },
  {
    city: 'Mumbai', zone: 'Kurla',
    probability: 54, risk: 'MEDIUM',
    rainfall: 28, elevation: 11, events: 6, monsoon: 0.61,
  },
  {
    city: 'Bengaluru', zone: 'Koramangala',
    probability: 12, risk: 'LOW',
    rainfall: 8, elevation: 920, events: 2, monsoon: 0.18,
  },
]

export const MOCK_CLAIM = {
  id: 'cl-001',
  refId: 'GP-RZP-20260321-0847',
  type: 'FLOOD',
  amount: 600,
  status: 'PROCESSING',
  triggeredAt: '2026-03-21T14:19:00',
  zone: 'Kondapur, Hyderabad',
  fraudScore: 0.04,
  correlation: 84,
  workerCount: 28,
  totalWorkers: 33,
  lastOrderMinutes: 38,
  steps: [
    { id: 1, label: 'Trigger verified',      detail: 'IMD Red Alert confirmed · 2:19 PM',      status: 'done' },
    { id: 2, label: 'You were working',       detail: 'Last order 38 min before trigger',        status: 'done' },
    { id: 3, label: '28 workers confirmed',   detail: '84% of your zone affected',               status: 'done' },
    { id: 4, label: 'Fraud check passed',     detail: 'Score 0.04 · All checks clear',           status: 'done' },
    { id: 5, label: 'Payout processing',      detail: 'UPI transfer · Est. 90 minutes',          status: 'active' },
  ],
}

export const MOCK_PAYOUTS = [
  { id: 'p-001', type: 'FLOOD',  event: 'IMD Red Alert', amount: 600, status: 'PAID', date: '2026-03-08' },
  { id: 'p-002', type: 'OUTAGE', event: 'Zepto Outage',  amount: 450, status: 'PAID', date: '2026-02-22' },
]

export const MOCK_ADMIN = {
  stats: {
    activePolicies: 1247,
    weeklyRevenue: 54321,
    activePayouts: 33000,
    lossRatio: 61,
  },
  claimsQueue: [
    { id: 'cl-101', name: 'Ravi Kumar', type: 'Flood',  amount: 600, fraudScore: 0.04, status: 'AUTO_APPROVED' },
    { id: 'cl-102', name: 'Suresh M.',  type: 'Flood',  amount: 600, fraudScore: 0.11, status: 'AUTO_APPROVED' },
    { id: 'cl-103', name: 'Rajesh D.',  type: 'Outage', amount: 450, fraudScore: 0.91, status: 'MANUAL_REVIEW',
      flag: 'GPS 34km from zone · Zero activity 6h' },
  ],
  events: [
    { city: 'Hyderabad', type: 'Flood',  total: 33, claimed: 28, correlation: 84, status: 'CONFIRMED', exposure: 19200 },
    { city: 'Bengaluru', type: 'Outage', total: 14, claimed: 1,  correlation: 7,  status: 'ANOMALY',   exposure: 450 },
  ],
}
