import { useEffect, useState, lazy, Suspense } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useThemeStore } from './store/themeStore'
import { useWorkerStore } from './store/workerStore'
import LoadingScreen from './components/ui/LoadingScreen'
import WorkerLayout from './components/layout/WorkerLayout'
import AdminLayout from './components/layout/AdminLayout'
import { AnimatedBackground } from './components/ui/AnimatedBackground'

// Eager-loaded routes (landing + auth)
import Landing from './pages/Landing'
import Login from './pages/worker/Login'
import Register from './pages/worker/Register'
import CompleteProfile from './pages/worker/CompleteProfile'

// Lazy-loaded routes
const Onboarding = lazy(() => import('./pages/Onboarding'))
const PaymentSuccess = lazy(() => import('./pages/worker/PaymentSuccess'))
const OTP = lazy(() => import('./pages/worker/OTP'))
const ZoneSelect = lazy(() => import('./pages/worker/ZoneSelect'))
const RiskScore = lazy(() => import('./pages/worker/RiskScore'))
const AIForecast = lazy(() => import('./pages/worker/AIForecast'))
const Premium = lazy(() => import('./pages/worker/Premium'))
const Coverage = lazy(() => import('./pages/worker/Coverage'))
const Dashboard = lazy(() => import('./pages/worker/Dashboard'))
const ClaimStatus = lazy(() => import('./pages/worker/ClaimStatus'))
const PayoutSuccess = lazy(() => import('./pages/worker/PayoutSuccess'))
const PayoutReceipt = lazy(() => import('./pages/worker/PayoutReceipt'))
const Profile = lazy(() => import('./pages/worker/Profile'))
const ClaimsList = lazy(() => import('./pages/worker/ClaimsList'))
const NotificationsPage = lazy(() => import('./pages/worker/NotificationsPage'))
const EarningsShield = lazy(() => import('./pages/worker/EarningsShield'))
const EarningsIntelligence = lazy(() => import('./pages/worker/EarningsIntelligence'))
const ZoneIntel = lazy(() => import('./pages/worker/ZoneIntel'))
const CommunityStats = lazy(() => import('./pages/worker/CommunityStats'))
const CoverageAssistant = lazy(() => import('./pages/worker/CoverageAssistant'))
const Terms = lazy(() => import('./pages/Terms'))
const Privacy = lazy(() => import('./pages/Privacy'))
const Maintenance = lazy(() => import('./pages/Maintenance'))
const NotFound = lazy(() => import('./pages/NotFound'))
const AdminDashboard = lazy(() => import('./pages/admin/AdminDashboard'))
const ActuarialDashboard = lazy(() => import('./pages/admin/ActuarialDashboard'))
const ClaimsQueue = lazy(() => import('./pages/admin/ClaimsQueue'))
const Analytics = lazy(() => import('./pages/admin/Analytics'))
const InsurerDashboard = lazy(() => import('./pages/admin/InsurerDashboard'))
const Reports = lazy(() => import('./pages/admin/Reports'))
const AdminLogin = lazy(() => import('./pages/admin/AdminLogin'))
const AdminSupport = lazy(() => import('./pages/admin/AdminSupport'))
const WorkerManagement = lazy(() => import('./pages/admin/WorkerManagement'))
const Support = lazy(() => import('./pages/worker/Support'))
const HowItWorks = lazy(() => import('./pages/worker/HowItWorks'))

const CITIES = [
  { name: 'Hyderabad', lat: 17.385, lng: 78.4867, zone: 'kondapur-hyderabad' },
  { name: 'Mumbai',    lat: 19.076, lng: 72.8777, zone: 'kurla-mumbai' },
  { name: 'Chennai',   lat: 13.083, lng: 80.2707, zone: 'tnagar-chennai' },
  { name: 'Bengaluru', lat: 12.972, lng: 77.5946, zone: 'koramangala-bengaluru' },
]

function getNearestCity(lat, lng) {
  let nearest = CITIES[0]
  let minDist = Infinity
  CITIES.forEach((c) => {
    const d = Math.hypot(c.lat - lat, c.lng - lng)
    if (d < minDist) { minDist = d; nearest = c }
  })
  return nearest
}

function ProtectedRoute({ children }) {
  const isAuthenticated = useWorkerStore((s) => s.isAuthenticated)
  const logout = useWorkerStore((s) => s.logout)
  const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')
  if (!isAuthenticated || !token) {
    if (isAuthenticated && !token) logout()
    return <Navigate to="/login" replace />
  }
  return children
}

function PublicRoute({ children }) {
  const isAuthenticated = useWorkerStore((s) => s.isAuthenticated)
  const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')
  if (isAuthenticated && token) return <Navigate to="/dashboard" replace />
  return children
}

function SuspenseFallback() {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '60vh',
    }}>
      <div style={{
        width: 28, height: 28,
        border: '3px solid var(--border)',
        borderTopColor: 'var(--brand)',
        borderRadius: 999,
        animation: 'spin 0.8s linear infinite',
      }} />
    </div>
  )
}

function AppRoutes() {
  return (
    <Suspense fallback={<SuspenseFallback />}>
      <Routes>
        {/* Public routes */}
        <Route path="/" element={<Landing />} />
        <Route path="/login" element={<PublicRoute><Login /></PublicRoute>} />
        <Route path="/register" element={<PublicRoute><Register /></PublicRoute>} />
        <Route path="/complete-profile" element={<CompleteProfile />} />
        <Route path="/otp" element={<PublicRoute><OTP /></PublicRoute>} />
        <Route path="/payment-success" element={<PaymentSuccess />} />
        <Route path="/onboarding" element={<Onboarding />} />

        {/* Legal — accessible always */}
        <Route path="/terms" element={<Terms />} />
        <Route path="/privacy" element={<Privacy />} />

        {/* Protected worker routes — nested under WorkerLayout */}
        <Route
          element={
            <ProtectedRoute>
              <WorkerLayout />
            </ProtectedRoute>
          }
        >
          <Route path="/zone"           element={<ZoneSelect />} />
          <Route path="/risk-score"     element={<RiskScore />} />
          <Route path="/forecast"       element={<AIForecast />} />
          <Route path="/premium"        element={<Premium />} />
          <Route path="/coverage"       element={<Coverage />} />
          <Route path="/dashboard"      element={<Dashboard />} />
          <Route path="/claim/:id"      element={<ClaimStatus />} />
          <Route path="/payout-success" element={<PayoutSuccess />} />
          <Route path="/payout/:claimId" element={<PayoutReceipt />} />
          <Route path="/profile"        element={<Profile />} />
          <Route path="/claims"         element={<ClaimsList />} />
          <Route path="/notifications"  element={<NotificationsPage />} />
          <Route path="/earnings"       element={<EarningsShield />} />
          <Route path="/earnings-intelligence" element={<EarningsIntelligence />} />
          <Route path="/zone-intel"     element={<ZoneIntel />} />
          <Route path="/community"      element={<CommunityStats />} />
          <Route path="/assistant"      element={<CoverageAssistant />} />
          <Route path="/support"        element={<Support />} />
          <Route path="/how-it-works"   element={<HowItWorks />} />
        </Route>

        {/* Admin login — standalone, no layout */}
        <Route path="/admin/login" element={<AdminLogin />} />

        {/* Admin routes — nested under AdminLayout */}
        <Route element={<AdminLayout />}>
          <Route path="/admin"              element={<AdminDashboard />} />
          <Route path="/admin/actuarial"    element={<ActuarialDashboard />} />
          <Route path="/admin/claims"       element={<ClaimsQueue />} />
          <Route path="/admin/analytics"    element={<Analytics />} />
          <Route path="/admin/reports"      element={<Reports />} />
          <Route path="/admin/workers"      element={<WorkerManagement />} />
          <Route path="/admin/insurer"      element={<InsurerDashboard />} />
          <Route path="/admin/support"      element={<AdminSupport />} />
        </Route>

        {/* 404 catch-all */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Suspense>
  )
}

export default function App() {
  const [appReady, setAppReady] = useState(false)
  const { isDark } = useThemeStore()
  const setDetectedCity = useWorkerStore((s) => s.setDetectedCity)

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light')
  }, [isDark])

  useEffect(() => {
    if (!navigator.geolocation) return
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude: lat, longitude: lng } = pos.coords
        const city = getNearestCity(lat, lng)
        setDetectedCity({ lat, lng, city: city.name, zone: city.zone })
      },
      () => {},
      { timeout: 5000 }
    )
  }, [])

  if (!appReady) {
    return <LoadingScreen onComplete={() => setAppReady(true)} />
  }

  return (
    <BrowserRouter>
      <AnimatedBackground />
      <AppRoutes />
    </BrowserRouter>
  )
}
