import { motion } from 'framer-motion'
import { Home, Shield, FileCheck, TrendingUp, User } from 'lucide-react'
import { useNavigate, useLocation } from 'react-router-dom'

const tabs = [
  { id: 'home',     label: 'Home',     icon: Home,       path: '/dashboard' },
  { id: 'coverage', label: 'Cover',    icon: Shield,     path: '/coverage' },
  { id: 'claims',   label: 'Claims',   icon: FileCheck,  path: '/claims' },
  { id: 'forecast', label: 'Forecast', icon: TrendingUp, path: '/forecast' },
  { id: 'profile',  label: 'Profile',  icon: User,       path: '/profile' },
]

export default function BottomNav() {
  const navigate = useNavigate()
  const location = useLocation()

  return (
    <nav
      className="lg:hidden fixed bottom-0 left-0 right-0 z-50"
      style={{
        background: 'var(--bg-primary)',
        borderTop: '1px solid var(--border)',
        paddingBottom: 'env(safe-area-inset-bottom, 8px)',
      }}
    >
      <div className="flex items-center justify-around h-16">
        {tabs.map((tab) => {
          const active = location.pathname === tab.path ||
            (tab.id === 'claims' && location.pathname.startsWith('/claim')) ||
            (tab.id === 'coverage' && location.pathname === '/premium')
          const Icon = tab.icon
          return (
            <motion.button
              key={tab.id}
              id={`nav-${tab.id}`}
              onClick={() => navigate(tab.path)}
              className="flex flex-col items-center justify-center flex-1 h-full gap-0.5 bg-transparent border-none cursor-pointer"
              whileTap={{ scale: 0.88 }}
            >
              <div className="relative">
                <Icon
                  size={22}
                  style={{
                    color: active ? 'var(--brand)' : 'var(--text-tertiary)',
                    strokeWidth: active ? 2.5 : 1.8,
                  }}
                />
                {active && (
                  <motion.div
                    layoutId="nav-dot"
                    className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full"
                    style={{ background: 'var(--brand)' }}
                  />
                )}
              </div>
              <span
                style={{
                  fontSize: 10,
                  fontWeight: active ? 600 : 400,
                  color: active ? 'var(--brand)' : 'var(--text-tertiary)',
                  fontFamily: 'Inter',
                }}
              >
                {tab.label}
              </span>
            </motion.button>
          )
        })}
      </div>
    </nav>
  )
}
