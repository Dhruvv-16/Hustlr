import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { ShieldCheck, Info } from 'lucide-react'
import Button from '../../components/ui/Button'
import { useWorkerStore } from '../../store/workerStore'
import { getUserByUid, loginWithFirebase } from '../../services/api'
import { signInWithEmail, signInWithGoogle } from '../../services/firebase'

const container = {
  animate: { transition: { staggerChildren: 0.08 } },
}
const item = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
}

const GoogleLogo = () => (
  <svg width="18" height="18" viewBox="0 0 18 18">
    <path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.875 2.684-6.615z"/>
    <path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332C2.438 15.983 5.482 18 9 18z"/>
    <path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.282-1.117-.282-1.71s.102-1.17.282-1.71V4.958H.957C.347 6.173 0 7.548 0 9s.348 2.827.957 4.042l3.007-2.332z"/>
    <path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0 5.482 0 2.438 2.017.957 4.958L3.964 6.29C4.672 4.163 6.656 3.58 9 3.58z"/>
  </svg>
)

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [googleLoading, setGoogleLoading] = useState(false)
  const [error, setError] = useState('')

  const handleGoogleLogin = async () => {
    setGoogleLoading(true)
    setError('')
    try {
      const user = await signInWithGoogle()
      const existing = await getUserByUid(user.uid)
      if (!existing?.user) {
        sessionStorage.setItem('gp-pending-profile', JSON.stringify(user))
        navigate('/complete-profile')
        return
      }
      const data = await loginWithFirebase(user.idToken, user.name, user.phone)
      localStorage.setItem('gp-access-token', data.access_token)
      localStorage.setItem('gp-token', data.access_token)
      const { login } = useWorkerStore.getState()
      login(data.worker)
      navigate(data.requires_profile ? '/complete-profile' : '/dashboard')
    } catch (e) {
      setError(e?.message || 'Google sign-in failed. Please try again.')
    } finally {
      setGoogleLoading(false)
    }
  }

  const handleEmailLogin = async () => {
    if (!email || !password) {
      setError('Please enter both email and password')
      return
    }
    setError('')
    setLoading(true)
    try {
      const user = await signInWithEmail(email, password)
      const data = await loginWithFirebase(user.idToken, user.name || '', user.phone || '')

      localStorage.setItem('gp-access-token', data.access_token)
      localStorage.setItem('gp-token', data.access_token)
      const { login } = useWorkerStore.getState()
      login(data.worker)
      navigate(data.requires_profile ? '/complete-profile' : '/dashboard')
    } catch (e) {
      setError(e?.message || 'Invalid email or password. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col lg:flex-row" style={{ background: 'var(--bg-primary)' }}>
      {/* LEFT: GIF panel — mobile top banner (220px), desktop side panel (full height) */}
      <div
        className="w-full lg:w-1/2 lg:min-h-screen relative flex-shrink-0"
        style={{
          height: 220,
          overflow: 'hidden',
          background: '#0F0F0F',
        }}
      >
        <img
          src="https://res.cloudinary.com/dqwm8wgg8/image/upload/v1774181576/yvg6hwnrtbpnaagohbvb.gif"
          alt="Delivery worker"
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            opacity: 0.85,
            position: 'absolute',
            inset: 0,
          }}
        />
        {/* Gradient overlay — bottom on mobile, right on desktop */}
        <div
          className="block lg:hidden"
          style={{
            position: 'absolute',
            bottom: 0, left: 0, right: 0,
            height: 80,
            background: 'linear-gradient(to bottom, transparent, var(--bg-primary))',
          }}
        />
        <div
          className="hidden lg:block"
          style={{
            position: 'absolute',
            top: 0, right: 0, bottom: 0,
            width: 120,
            background: 'linear-gradient(to right, transparent, var(--bg-primary))',
          }}
        />
        {/* Logo overlay */}
        <div style={{
          position: 'absolute',
          top: 16, left: 16,
          display: 'flex',
          alignItems: 'center',
          gap: 8,
        }}>
          <div style={{
            background: 'rgba(255,255,255,0.15)',
            backdropFilter: 'blur(8px)',
            borderRadius: 10,
            padding: '6px 12px',
          }}>
            <span style={{ fontFamily: 'Barlow, sans-serif', fontSize: 24, fontWeight: 400, color: 'white', letterSpacing: '-0.02em', paddingTop: 8, paddingBottom: 8 }}>
              GuidePay
            </span>
          </div>
        </div>

        {/* Desktop tagline overlay */}
        <div
          className="hidden lg:flex"
          style={{
            position: 'absolute',
            bottom: 40, left: 40, right: 80,
            flexDirection: 'column',
            gap: 12,
          }}
        >
          <h2 style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 32, fontWeight: 800,
            color: 'white',
            lineHeight: 1.2,
            textShadow: '0 2px 12px rgba(0,0,0,0.4)',
          }}>
            Income protection for India's delivery workers.
          </h2>
          <p style={{
            fontSize: 15, fontFamily: 'Inter',
            color: 'rgba(255,255,255,0.8)',
            lineHeight: 1.6,
          }}>
            Auto-pays when floods, outages, or curfews stop you from working.
          </p>
        </div>
      </div>

      {/* RIGHT: Form panel */}
      <motion.div
        className="flex-1 flex flex-col lg:justify-center lg:max-w-xl lg:mx-auto lg:px-12"
        initial="initial"
        animate="animate"
        variants={container}
      >
        {/* Mobile-only heading */}
        <div className="px-6 pt-6 pb-4 lg:hidden">
          <motion.h1
            variants={item}
            className="font-display font-bold text-[28px] leading-tight"
            style={{ color: 'var(--text-primary)' }}
          >
            Income protection for delivery workers.
          </motion.h1>

          <motion.p
            variants={item}
            className="font-body text-[14px] leading-relaxed mt-2"
            style={{ color: 'var(--text-secondary)' }}
          >
            Auto-pays when floods, outages, or curfews stop you from working.
          </motion.p>

          <motion.div variants={item} className="flex flex-wrap gap-2 mt-4">
            {['🌊 Flood cover', '📱 Outage pay', '🚫 Curfew pay'].map((chip) => (
              <span
                key={chip}
                className="rounded-pill px-3 py-1.5 text-[12px] font-medium font-body"
                style={{
                  background: 'var(--bg-secondary)',
                  border: '1px solid var(--border)',
                  color: 'var(--text-secondary)',
                }}
              >
                {chip}
              </span>
            ))}
          </motion.div>
        </div>

        {/* Desktop heading */}
        <motion.div variants={item} className="hidden lg:block mb-6">
          <h1 style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 28, fontWeight: 800,
            color: 'var(--text-primary)',
            margin: '0 0 6px',
          }}>
            Welcome back
          </h1>
          <p style={{
            fontSize: 15, fontFamily: 'Inter',
            color: 'var(--text-secondary)',
          }}>
            Sign in to your GuidePay account
          </p>
        </motion.div>

        {/* Auth card */}
        <motion.div
          variants={item}
          className="mx-4 mb-4 rounded-card p-5 lg:mx-0"
          style={{
            background: 'var(--bg-primary)',
            boxShadow: 'var(--shadow-card)',
            border: '1px solid var(--border-light)',
          }}
        >
          {/* Google Sign-In */}
          <motion.button
            whileTap={{ scale: 0.97 }}
            onClick={handleGoogleLogin}
            disabled={googleLoading}
            className="w-full flex items-center justify-center gap-3 h-[52px] rounded-input font-semibold text-[15px] font-body transition-colors"
            style={{
              background: 'var(--bg-primary)',
              border: '1.5px solid var(--border)',
              color: 'var(--text-primary)',
              boxShadow: 'var(--shadow-sm)',
              opacity: googleLoading ? 0.7 : 1,
              cursor: 'pointer',
            }}
          >
            {googleLoading ? (
              <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full" style={{ animation: 'spin 0.8s linear infinite' }} />
            ) : (
              <GoogleLogo />
            )}
            Continue with Google
          </motion.button>

          {/* Divider */}
          <div className="flex items-center gap-3 my-4">
            <div className="flex-1 h-px" style={{ background: 'var(--border)' }} />
            <span className="text-[13px] font-body" style={{ color: 'var(--text-tertiary)' }}>or</span>
            <div className="flex-1 h-px" style={{ background: 'var(--border)' }} />
          </div>

          {/* Email input */}
          <label className="block text-[13px] font-medium font-body mb-1.5" style={{ color: 'var(--text-secondary)' }}>
            Email address
          </label>
          <div
            className="flex items-center rounded-input overflow-hidden h-[52px] transition-all mb-4"
            style={{ border: error ? '1.5px solid var(--danger)' : '1.5px solid var(--border)' }}
          >
            <input
              type="email"
              placeholder="ravi@example.com"
              value={email}
              onChange={(e) => { setEmail(e.target.value); setError('') }}
              onKeyDown={(e) => e.key === 'Enter' && handleEmailLogin()}
              className="flex-1 h-full px-4 text-[15px] font-body outline-none"
              style={{ background: 'transparent', color: 'var(--text-primary)' }}
            />
          </div>

          {/* Password input */}
          <label className="block text-[13px] font-medium font-body mb-1.5" style={{ color: 'var(--text-secondary)' }}>
            Password
          </label>
          <div
            className="flex items-center rounded-input overflow-hidden h-[52px] transition-all"
            style={{ border: error ? '1.5px solid var(--danger)' : '1.5px solid var(--border)' }}
          >
            <input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => { setPassword(e.target.value); setError('') }}
              onKeyDown={(e) => e.key === 'Enter' && handleEmailLogin()}
              className="flex-1 h-full px-4 text-[15px] font-body outline-none"
              style={{ background: 'transparent', color: 'var(--text-primary)' }}
            />
          </div>

          <AnimatePresence>
            {error && (
              <motion.p
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0 }}
                className="text-[12px] mt-1.5 font-body"
                style={{ color: 'var(--danger)' }}
              >
                {error}
              </motion.p>
            )}
          </AnimatePresence>

          <div className="mt-5">
            <Button onClick={handleEmailLogin} loading={loading} fullWidth>
              Sign In
            </Button>
          </div>
        </motion.div>

        {/* Sign up link */}
        <motion.p
          variants={item}
          className="px-6 pb-2 text-center text-[14px] font-body"
          style={{ color: 'var(--text-secondary)' }}
        >
          Don't have an account?{' '}
          <span
            onClick={() => navigate('/register')}
            style={{
              color: 'var(--brand)',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Sign up
          </span>
        </motion.p>

        <motion.p
          variants={item}
          className="px-6 pb-6 text-center text-[12px] font-body"
          style={{ color: 'var(--text-tertiary)' }}
        >
          By continuing, you agree to our{' '}
          <span
            onClick={() => navigate('/terms')}
            style={{ color: 'var(--brand)', cursor: 'pointer' }}
          >
            Terms
          </span>
          {' '}&amp;{' '}
          <span
            onClick={() => navigate('/privacy')}
            style={{ color: 'var(--brand)', cursor: 'pointer' }}
          >
            Privacy Policy
          </span>
        </motion.p>
      </motion.div>
    </div>
  )
}
