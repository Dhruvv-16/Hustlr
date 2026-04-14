import { useState } from 'react'
import { Outlet, useNavigate, useLocation, Link } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Home, Shield, FileCheck, TrendingUp, User,
  DollarSign, MapPin, Bot, Headphones, X, Menu, Zap, Sparkles,
} from 'lucide-react'
import BottomNav from '../ui/BottomNav'
import { NotificationBell } from '../ui/NotificationBell'
import { AppTour } from '../tour/AppTour'
import { useWorkerStore } from '../../store/workerStore'

const NAV_ITEMS = [
  { id: 'home',      label: 'Home',       icon: Home,             path: '/dashboard' },
  { id: 'coverage',  label: 'Coverage',   icon: Shield,           path: '/coverage' },
  { id: 'claims',    label: 'Claims',     icon: FileCheck,        path: '/claims' },
  { id: 'forecast',  label: 'Forecast',   icon: TrendingUp,       path: '/forecast' },
  { id: 'earnings',  label: 'Earnings',   icon: DollarSign,       path: '/earnings' },
  { id: 'earnings-intelligence', label: 'Earnings Intelligence', icon: Sparkles, path: '/earnings-intelligence' },
  { id: 'zone-intel',label: 'Zone Intel', icon: MapPin,           path: '/zone-intel' },
  { id: 'assistant', label: 'Assistant',  icon: Bot,          path: '/assistant' },
  { id: 'support',   label: 'Support',    icon: Headphones,   path: '/support' },
  { id: 'how-it-works', label: 'How It Works', icon: Zap,        path: '/how-it-works' },
  { id: 'profile',   label: 'Profile',    icon: User,             path: '/profile' },
]

const PAGE_TITLES = {
  '/dashboard': 'Dashboard',
  '/coverage': 'Coverage',
  '/claims': 'Claims',
  '/forecast': 'AI Forecast',
  '/profile': 'Profile',
  '/notifications': 'Notifications',
  '/zone': 'Select Zone',
  '/risk-score': 'Risk Score',
  '/premium': 'Your Premium',
  '/earnings': 'Earnings Shield',
  '/earnings-intelligence': 'Earnings Intelligence',
  '/zone-intel': 'Zone Intel',
  '/assistant': 'AI Assistant',
  '/support': 'Support',
  '/community': 'Community Stats',
  '/how-it-works': 'How It Works',
}

function Sidebar({ onClose }) {
  const navigate = useNavigate()
  const location = useLocation()

  return (
    <div
      className="flex flex-col h-full"
      style={{
        width: 240,
        background: 'var(--bg-card)',
        borderRight: '1px solid var(--border-light)',
        padding: '24px 12px',
      }}
    >
      <div className="flex items-center gap-2 px-3 mb-8">
        <span style={{ fontFamily: 'Barlow, sans-serif', fontSize: 24, fontWeight: 400, color: 'white', letterSpacing: '-0.02em', paddingTop: 8, paddingBottom: 8 }}>
          GuidePay
        </span>
        {onClose && (
          <button onClick={onClose} className="ml-auto lg:hidden">
            <X size={20} style={{ color: 'var(--text-tertiary)' }} />
          </button>
        )}
      </div>

      <nav className="flex flex-col gap-1">
        {NAV_ITEMS.map((item) => {
          const active =
            location.pathname === item.path ||
            (item.id === 'coverage' && (location.pathname === '/coverage' || location.pathname === '/premium')) ||
            (item.id === 'claims' && location.pathname.startsWith('/claim'))
          const Icon = item.icon
          return (
            <motion.button
              key={item.id}
              whileTap={{ scale: 0.97 }}
              onClick={() => { navigate(item.path); onClose?.() }}
              className="flex items-center gap-3 px-3 py-3 rounded-[10px] w-full text-left transition-colors"
              style={{
                background: active ? 'var(--brand-light)' : 'transparent',
                color: active ? 'var(--brand)' : 'var(--text-secondary)',
              }}
            >
              <Icon size={20} strokeWidth={active ? 2.5 : 1.8} />
              <span className="font-body font-semibold text-[14px]">{item.label}</span>
            </motion.button>
          )
        })}
      </nav>

      <div className="mt-auto pt-4 border-t" style={{ borderColor: 'var(--border-light)' }}>
        <button
          onClick={() => navigate('/admin')}
          className="flex items-center gap-2 px-3 py-2 w-full text-left"
          style={{ color: 'var(--text-tertiary)' }}
        >
          <span className="text-[12px] font-body">Admin panel →</span>
        </button>
        <p className="text-[11px] font-body text-center mt-3" style={{ color: 'var(--text-tertiary)' }}>
          GuidePay v1.0 · Phase 2
        </p>
      </div>
    </div>
  )
}

export default function WorkerLayout() {
  const [drawerOpen, setDrawerOpen] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()
  const showTour = useWorkerStore((s) => s.showTour)
  const setShowTour = useWorkerStore((s) => s.setShowTour)
  const worker = useWorkerStore((s) => s.worker)

  // Build initials from worker name
  const initials = worker?.name
    ? worker.name.split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase()
    : 'GP'

  const pageTitle = PAGE_TITLES[location.pathname] || location.pathname.replace('/', '') || 'Dashboard'

  return (
    <div className="min-h-screen" style={{ background: 'var(--bg-primary)' }}>

      {/* Desktop sidebar — fixed position */}
      <aside
        className="hidden lg:flex flex-col"
        style={{
          position: 'fixed',
          top: 0, left: 0, bottom: 0,
          width: 240,
          zIndex: 20,
        }}
      >
        <Sidebar />
      </aside>

      {/* Mobile drawer */}
      {drawerOpen && (
        <>
          <div
            className="fixed inset-0 bg-black/30 z-40 lg:hidden"
            onClick={() => setDrawerOpen(false)}
          />
          <motion.div
            initial={{ x: -280 }}
            animate={{ x: 0 }}
            exit={{ x: -280 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="fixed left-0 top-0 bottom-0 z-50 flex flex-col lg:hidden shadow-lg"
            style={{ width: 240 }}
          >
            <Sidebar onClose={() => setDrawerOpen(false)} />
          </motion.div>
        </>
      )}

      {/* Main content — offset by sidebar width on desktop */}
      <main
        className="min-h-screen lg:ml-[240px]"
        style={{ overflowX: 'hidden' }}
      >
        {/* Mobile topbar */}
        <div
          className="lg:hidden sticky top-0 z-30 flex items-center justify-between px-4 h-14"
          style={{
            background: 'var(--bg-card)',
            borderBottom: '1px solid var(--border-light)',
          }}
        >
          <div className="flex items-center gap-3">
            <button
              onClick={() => setDrawerOpen(true)}
              className="w-10 h-10 flex items-center justify-center"
            >
              <Menu size={22} style={{ color: 'var(--text-primary)' }} />
            </button>
            <span className="font-display font-bold text-[17px]" style={{ color: 'var(--text-primary)' }}>
              {pageTitle}
            </span>
          </div>
          <NotificationBell />
        </div>

        {/* Desktop topbar */}
        <div
          className="hidden lg:flex sticky top-0 z-30 items-center justify-between px-6 h-[60px]"
          style={{
            background: 'var(--bg-card)',
            borderBottom: '1px solid var(--border-light)',
          }}
        >
          <p style={{
            fontSize: 15,
            fontWeight: 600,
            fontFamily: 'Bricolage Grotesque, sans-serif',
            color: 'var(--text-primary)',
            textTransform: 'capitalize',
          }}>
            {pageTitle}
          </p>
          <div className="flex items-center gap-3">
            <NotificationBell />
            <div
              style={{
                width: 36, height: 36,
                borderRadius: 999,
                background: 'var(--brand-light)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
              }}
              onClick={() => navigate('/profile')}
            >
              <span style={{
                fontFamily: 'Bricolage Grotesque, sans-serif',
                fontSize: 14,
                fontWeight: 700,
                color: 'var(--brand)',
              }}>{initials}</span>
            </div>
          </div>
        </div>

        {/* Page content via Outlet */}
        <div style={{ minHeight: 'calc(100vh - 60px)' }} className="max-w-3xl mx-auto lg:px-6 lg:py-4 pb-20">
          <Outlet />
        </div>
      </main>

      {/* Mobile bottom nav */}
      <BottomNav />

      {/* Global App Tour — rendered at layout level so it persists across page navigations */}
      <AnimatePresence>
        {showTour && (
          <AppTour onClose={() => setShowTour(false)} />
        )}
      </AnimatePresence>
    </div>
  )
}
