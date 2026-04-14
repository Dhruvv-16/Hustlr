import { useState } from 'react'
import { Outlet, useNavigate, useLocation, Navigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  LayoutDashboard, FileCheck, BarChart2, FileText,
  Menu, X, RefreshCw, Bell, LogOut, Headphones, Activity, Users,
} from 'lucide-react'

const ADMIN_NAV = [
  { label: 'Overview',       icon: LayoutDashboard, path: '/admin' },
  { label: 'Actuarial',      icon: Activity,         path: '/admin/actuarial' },
  { label: 'Claims',         icon: FileCheck,        path: '/admin/claims' },
  { label: 'Analytics',      icon: BarChart2,        path: '/admin/analytics' },
  { label: 'Workers',        icon: Users,            path: '/admin/workers' },
  { label: 'Insurer View',   icon: FileText,         path: '/admin/insurer' },
  { label: 'Reports',        icon: FileText,         path: '/admin/reports' },
  { label: 'Support Inbox',  icon: Headphones,       path: '/admin/support', badge: 'live' },
]

const PAGE_TITLES = {
  '/admin': 'Overview',
  '/admin/actuarial': 'Actuarial Dashboard',
  '/admin/claims': 'Claims Queue',
  '/admin/analytics': 'Analytics',
  '/admin/reports': 'Reports',
  '/admin/insurer': 'Insurer View',
  '/admin/support': 'Support Inbox',
}

function checkAdminAuth() {
  const token = localStorage.getItem('gp-admin-token')
  if (token) {
    // Decode the JWT payload (base64) and check expiry without a library
    try {
      const payload = JSON.parse(atob(token.split('.')[1]))
      if (payload.exp && payload.exp * 1000 < Date.now()) {
        // Expired — wipe it so the login page is shown
        localStorage.removeItem('gp-admin-token')
        localStorage.removeItem('gp-admin-access-token')
        localStorage.removeItem('gp-admin-auth')
        return false
      }
      return true
    } catch {
      localStorage.removeItem('gp-admin-token')
      return false
    }
  }
  const authRaw = localStorage.getItem('gp-admin-auth')
  if (!authRaw) return false
  if (authRaw === 'true') return true
  try {
    const auth = JSON.parse(authRaw)
    return auth.authenticated === true
  } catch {
    return false
  }
}

function AdminSidebar({ onClose }) {
  const navigate = useNavigate()
  const location = useLocation()

  return (
    <div style={{
      width: 220,
      background: '#111111',
      borderRight: '1px solid #222222',
      padding: '20px 10px',
      display: 'flex',
      flexDirection: 'column',
      height: '100%',
    }}>
      {/* Logo */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 10px', marginBottom: 28 }}>
        <span style={{ fontFamily: 'Barlow, sans-serif', fontSize: 24, fontWeight: 400, color: 'white', letterSpacing: '-0.02em' }}>
          GuidePay
        </span>
        <p style={{ fontSize: 10, color: '#6B6B6B', fontFamily: 'Inter', margin: 0, marginLeft: 2 }}>
          Admin
        </p>
        {onClose && (
          <button
            onClick={onClose}
            style={{ marginLeft: 'auto', background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}
          >
            <X size={18} color="#6B6B6B" />
          </button>
        )}
      </div>

      {/* Nav */}
      <nav style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {ADMIN_NAV.map(item => {
          const active = location.pathname === item.path
          const Icon = item.icon
          return (
            <motion.button
              key={item.label}
              whileTap={{ scale: 0.97 }}
              onClick={() => { navigate(item.path); onClose?.() }}
              style={{
                display: 'flex', alignItems: 'center', gap: 10,
                padding: '10px 12px', borderRadius: 9,
                border: 'none', cursor: 'pointer', width: '100%', textAlign: 'left',
                background: active ? 'rgba(217,119,87,0.12)' : 'transparent',
                color: active ? '#D97757' : '#9B9B9B',
                transition: 'background 0.15s, color 0.15s',
              }}
            >
              <Icon size={17} strokeWidth={active ? 2.5 : 1.8} />
              <span style={{ fontFamily: 'Inter', fontWeight: 600, fontSize: 13 }}>
                {item.label}
              </span>
              {item.badge && (
                <span style={{
                  marginLeft: 'auto',
                  fontSize: 9, fontWeight: 700, fontFamily: 'Inter',
                  background: '#12B76A', color: 'white',
                  padding: '2px 5px', borderRadius: 999,
                  textTransform: 'uppercase', letterSpacing: 0.5,
                }}>
                  {item.badge}
                </span>
              )}
              {active && !item.badge && (
                <div style={{
                  marginLeft: 'auto', width: 6, height: 6,
                  borderRadius: 999, background: '#D97757',
                }} />
              )}
            </motion.button>
          )
        })}
      </nav>

      {/* Footer */}
      <div style={{ marginTop: 'auto', paddingTop: 16, borderTop: '1px solid #222' }}>
        <button
          onClick={() => navigate('/dashboard')}
          style={{
            background: 'none', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '8px 12px', width: '100%',
          }}
        >
          <span style={{ fontSize: 12, fontFamily: 'Inter', color: '#6B6B6B' }}>← Worker app</span>
        </button>
        <p style={{ fontSize: 10, color: '#3D3D3D', fontFamily: 'Inter', textAlign: 'center', marginTop: 6 }}>
          GuidePay v1.0 · Phase 2
        </p>
      </div>
    </div>
  )
}

export default function AdminLayout() {
  const [drawerOpen, setDrawerOpen] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()

  // Synchronous auth guard — runs during render, no flash of admin content
  if (!checkAdminAuth()) {
    return <Navigate to="/admin/login" replace />
  }

  const pageTitle = PAGE_TITLES[location.pathname] || 'Admin'
  const breadcrumb = `Admin / ${pageTitle}`

  const handleRefresh = () => {
    window.dispatchEvent(new CustomEvent('admin-refresh'))
    window.location.reload()
  }

  const handleLogout = () => {
    localStorage.removeItem('gp-admin-token')
    localStorage.removeItem('gp-admin-access-token')
    localStorage.removeItem('gp-admin-auth')
    localStorage.removeItem('gp-admin-user')
    navigate('/admin/login', { replace: true })
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#0A0A0A' }}>
      {/* Desktop sidebar */}
      <aside
        className="hidden lg:flex"
        style={{
          position: 'fixed',
          top: 0, left: 0, bottom: 0,
          width: 220, zIndex: 20,
          flexDirection: 'column',
        }}
      >
        <AdminSidebar />
      </aside>

      {/* Mobile drawer */}
      <AnimatePresence>
        {drawerOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setDrawerOpen(false)}
              style={{
                position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)',
                zIndex: 40,
              }}
            />
            <motion.div
              initial={{ x: -240 }}
              animate={{ x: 0 }}
              exit={{ x: -240 }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
              style={{
                position: 'fixed', left: 0, top: 0, bottom: 0,
                width: 220, zIndex: 50,
              }}
            >
              <AdminSidebar onClose={() => setDrawerOpen(false)} />
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Main content */}
      <main
        className="lg:ml-[220px]"
        style={{ flex: 1, minHeight: '100vh', display: 'flex', flexDirection: 'column' }}
      >
        {/* Topbar */}
        <div style={{
          position: 'sticky', top: 0, zIndex: 30,
          height: 56,
          background: '#111111',
          borderBottom: '1px solid #222222',
          display: 'flex', alignItems: 'center',
          padding: '0 20px',
          gap: 12,
        }}>
          {/* Mobile hamburger */}
          <button
            className="lg:hidden"
            onClick={() => setDrawerOpen(true)}
            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}
          >
            <Menu size={20} color="#9B9B9B" />
          </button>

          {/* Breadcrumb */}
          <p style={{ fontSize: 13, fontFamily: 'Inter', color: '#6B6B6B', flex: 1 }}>
            {breadcrumb}
          </p>

          {/* Actions */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <button
              onClick={handleRefresh}
              title="Refresh data"
              style={{
                width: 34, height: 34, borderRadius: 8,
                background: '#1A1A1A', border: '1px solid #2A2A2A',
                cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}
            >
              <RefreshCw size={15} color="#9B9B9B" />
            </button>
            <button
              style={{
                width: 34, height: 34, borderRadius: 8,
                background: '#1A1A1A', border: '1px solid #2A2A2A',
                cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                position: 'relative',
              }}
            >
              <Bell size={15} color="#9B9B9B" />
            </button>
            <button
              onClick={handleLogout}
              title="Logout"
              style={{
                width: 34, height: 34, borderRadius: 8,
                background: '#1A1A1A', border: '1px solid #2A2A2A',
                cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}
            >
              <LogOut size={15} color="#9B9B9B" />
            </button>
          </div>
        </div>

        {/* Page content */}
        <div style={{ flex: 1, overflowX: 'hidden' }}>
          <Outlet />
        </div>
      </main>
    </div>
  )
}
