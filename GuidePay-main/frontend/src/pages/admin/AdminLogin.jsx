import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Eye, EyeOff, Shield } from 'lucide-react'
import { adminLogin } from '../../services/api'

export default function AdminLogin() {
  const navigate = useNavigate()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (!username.trim() || !password.trim()) {
      setError('Please enter username and password')
      return
    }
    setLoading(true)
    try {
      const data = await adminLogin(username, password)
      localStorage.setItem('gp-admin-token', data.access_token)
      localStorage.setItem('gp-admin-access-token', data.access_token)
      localStorage.setItem('gp-admin-auth', JSON.stringify({
        authenticated: true,
        username: username.trim(),
        loginAt: new Date().toISOString(),
      }))
      localStorage.setItem('gp-admin-user', data.username || username)
      navigate('/admin', { replace: true })
    } catch (err) {
      // Backend unavailable — allow demo credentials admin/admin
      if (username.trim() === 'admin' && password === 'admin') {
        localStorage.setItem('gp-admin-auth', JSON.stringify({
          authenticated: true,
          username: 'admin',
          loginAt: new Date().toISOString(),
        }))
        navigate('/admin', { replace: true })
        return
      }
      setError(err?.detail || 'Invalid credentials. Demo: admin / admin')
      setLoading(false)
    }
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: '#0A0A0A',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: 20,
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* Grid background */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `
          linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
          linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px)
        `,
        backgroundSize: '48px 48px',
        pointerEvents: 'none',
      }} />

      {/* Glow */}
      <div style={{
        position: 'absolute',
        top: '30%', left: '50%',
        transform: 'translate(-50%, -50%)',
        width: 500, height: 500,
        background: 'radial-gradient(circle, rgba(217,119,87,0.12) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: 'spring', stiffness: 300, damping: 28 }}
        style={{
          width: '100%', maxWidth: 400,
          background: '#111111',
          border: '1px solid #222222',
          borderRadius: 20,
          padding: 36,
          position: 'relative',
          zIndex: 1,
        }}
      >
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            width: 52, height: 52, borderRadius: 14,
            background: 'rgba(217,119,87,0.12)',
            border: '1px solid rgba(217,119,87,0.25)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 16px',
          }}>
            <Shield size={24} color="#D97757" />
          </div>
          <h1 style={{
            fontFamily: 'Bricolage Grotesque', fontWeight: 800,
            fontSize: 22, color: 'white', margin: 0,
          }}>
            Admin Panel
          </h1>
          <p style={{
            fontSize: 13, color: '#6B6B6B', fontFamily: 'Inter',
            marginTop: 6,
          }}>
            GuidePay SentinelX · Restricted access
          </p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {/* Username */}
          <div>
            <label style={{
              fontSize: 12, fontWeight: 600, fontFamily: 'Inter',
              color: '#9B9B9B', display: 'block', marginBottom: 6,
              textTransform: 'uppercase', letterSpacing: 0.8,
            }}>
              Username
            </label>
            <input
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              placeholder="admin"
              autoComplete="username"
              required
              style={{
                width: '100%', height: 46,
                background: '#1A1A1A',
                border: '1px solid #2A2A2A',
                borderRadius: 10, padding: '0 14px',
                fontSize: 14, fontFamily: 'Inter',
                color: 'white', outline: 'none',
                transition: 'border-color 0.15s',
              }}
              onFocus={e => { e.target.style.borderColor = '#D97757' }}
              onBlur={e => { e.target.style.borderColor = '#2A2A2A' }}
            />
          </div>

          {/* Password */}
          <div>
            <label style={{
              fontSize: 12, fontWeight: 600, fontFamily: 'Inter',
              color: '#9B9B9B', display: 'block', marginBottom: 6,
              textTransform: 'uppercase', letterSpacing: 0.8,
            }}>
              Password
            </label>
            <div style={{ position: 'relative' }}>
              <input
                type={showPass ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete="current-password"
                required
                style={{
                  width: '100%', height: 46,
                  background: '#1A1A1A',
                  border: '1px solid #2A2A2A',
                  borderRadius: 10, padding: '0 44px 0 14px',
                  fontSize: 14, fontFamily: 'Inter',
                  color: 'white', outline: 'none',
                  transition: 'border-color 0.15s',
                }}
                onFocus={e => { e.target.style.borderColor = '#D97757' }}
                onBlur={e => { e.target.style.borderColor = '#2A2A2A' }}
              />
              <button
                type="button"
                onClick={() => setShowPass(!showPass)}
                style={{
                  position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)',
                  background: 'none', border: 'none', cursor: 'pointer', padding: 4,
                  color: '#6B6B6B',
                }}
              >
                {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          {error && (
            <p style={{
              fontSize: 13, fontFamily: 'Inter', color: '#F04438',
              background: 'rgba(240,68,56,0.08)',
              border: '1px solid rgba(240,68,56,0.2)',
              borderRadius: 8, padding: '8px 12px', textAlign: 'center',
            }}>
              {error}
            </p>
          )}

          <motion.button
            type="submit"
            disabled={loading}
            whileTap={{ scale: 0.97 }}
            style={{
              width: '100%', height: 48, marginTop: 4,
              background: loading ? '#2A2A2A' : '#D97757',
              border: 'none', borderRadius: 12,
              fontSize: 15, fontWeight: 700, fontFamily: 'Inter',
              color: loading ? '#6B6B6B' : 'white',
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'background 0.15s',
            }}
          >
            {loading ? 'Signing in...' : 'Sign in →'}
          </motion.button>
        </form>

        <div style={{
          marginTop: 16,
          padding: '10px 14px',
          background: 'rgba(217,119,87,0.06)',
          border: '1px solid rgba(217,119,87,0.15)',
          borderRadius: 8,
          textAlign: 'center',
        }}>
          <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'rgba(255,255,255,0.4)', margin: 0 }}>
            Demo credentials:
            <span style={{ color: '#D97757', fontWeight: 700, marginLeft: 6 }}>admin / admin</span>
          </p>
        </div>
      </motion.div>
    </div>
  )
}
