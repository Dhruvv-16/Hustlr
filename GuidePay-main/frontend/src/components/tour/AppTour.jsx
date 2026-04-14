import { useState, useEffect, useCallback, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, ArrowRight, ArrowLeft } from 'lucide-react'
import { useNavigate, useLocation } from 'react-router-dom'

const TOUR_STEPS = [
  {
    id: 'welcome',
    target: null,
    page: '/dashboard',
    title: 'Welcome to GuidePay! 👋',
    body: 'Your income safety net — we detect floods, outages, and curfews in your zone and pay you instantly via UPI.',
    emoji: '🛡️',
  },
  {
    id: 'policy-card',
    target: '#policy-hero-card',
    page: '/dashboard',
    title: 'Your Coverage Card',
    body: 'Shows your coverage cap, renewal date, premium amount, and risk score. Green dot = you\'re protected.',
    emoji: '💳',
  },
  {
    id: 'alert-card',
    target: '#alert-banner',
    page: '/dashboard',
    title: 'Risk Alerts',
    body: 'AI monitors your zone 24/7. When high flood risk or outages are detected, this alert appears and your coverage extends automatically.',
    emoji: '⚠️',
  },
  {
    id: 'zone-status',
    target: '#zone-status-card',
    page: '/dashboard',
    title: 'Zone Monitor',
    body: 'Real-time flood alerts, platform health, and curfew status for your 5km zone. Checked every 15 minutes.',
    emoji: '📡',
  },
  {
    id: 'coverage-page',
    target: null,
    page: '/coverage',
    title: 'Coverage Plans',
    body: 'Compare plans side by side — Basic ₹49/wk, Standard ₹58/wk, Premium ₹69/wk. Each includes flood, outage, and curfew triggers.',
    emoji: '📋',
  },
  {
    id: 'claims-page',
    target: null,
    page: '/claims',
    title: 'Your Payouts',
    body: 'Trigger events are processed automatically. Track all past and current payouts here in real-time.',
    emoji: '💸',
  },
  {
    id: 'forecast-page',
    target: null,
    page: '/forecast',
    title: 'AI Forecast',
    body: '7-day flood probability forecast powered by AI. Plan your deliveries around weather events before they happen.',
    emoji: '🌤️',
  },
  {
    id: 'zone-intel-page',
    target: null,
    page: '/zone-intel',
    title: 'Zone Intel',
    body: 'Deep-dive analytics for your zone — historical trigger patterns, risk trends, and active event alerts.',
    emoji: '🗺️',
  },
  {
    id: 'earnings-page',
    target: null,
    page: '/earnings',
    title: 'Earnings Shield',
    body: 'See how much income you\'ve protected and recovered through payouts. Your financial safety net at a glance.',
    emoji: '💰',
  },
  {
    id: 'assistant-page',
    target: null,
    page: '/assistant',
    title: 'AI Assistant',
    body: 'Ask anything about your coverage, triggers, or claims. Get instant answers powered by AI.',
    emoji: '🤖',
  },
  {
    id: 'support-page',
    target: null,
    page: '/support',
    title: 'Support',
    body: 'Raise a ticket and chat directly with our support team. We respond within 24 hours.',
    emoji: '🎧',
  },
  {
    id: 'profile-page',
    target: null,
    page: '/profile',
    title: 'Your Profile',
    body: 'Manage your UPI ID, zone, personal details, and notification preferences.',
    emoji: '👤',
  },
  {
    id: 'done',
    target: null,
    page: null,
    title: 'You\'re all set! 🎉',
    body: 'Buy a plan → We monitor → Trigger detected → Payout to UPI in under 2 hours. Go deliver!',
    emoji: '🚀',
    last: true,
  },
]

export function AppTour({ onClose }) {
  const [step, setStep] = useState(0)
  const [targetRect, setTargetRect] = useState(null)
  const [navigating, setNavigating] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()
  const current = TOUR_STEPS[step]
  const waitingForPage = useRef(null)

  useEffect(() => {
    if (waitingForPage.current && location.pathname === waitingForPage.current.page) {
      const nextStep = waitingForPage.current.step
      waitingForPage.current = null
      setTimeout(() => {
        setStep(nextStep)
        setNavigating(false)
      }, 500)
    }
  }, [location.pathname])

  const goToStep = (nextStepIdx) => {
    const nextStep = TOUR_STEPS[nextStepIdx]
    if (!nextStep) return
    if (nextStep.page && nextStep.page !== location.pathname) {
      setNavigating(true)
      waitingForPage.current = { page: nextStep.page, step: nextStepIdx }
      navigate(nextStep.page)
    } else {
      setStep(nextStepIdx)
    }
  }

  const next = () => {
    if (current.last) {
      navigate('/dashboard')
      onClose()
      return
    }
    goToStep(step + 1)
  }

  const prev = () => {
    if (step <= 0) return
    goToStep(step - 1)
  }

  const handleClose = () => {
    if (location.pathname !== '/dashboard') navigate('/dashboard')
    onClose()
  }

  const updateTargetRect = useCallback(() => {
    if (current.target) {
      const el = document.querySelector(current.target)
      if (el) {
        const rect = el.getBoundingClientRect()
        setTargetRect({ top: rect.top, left: rect.left, width: rect.width, height: rect.height })
      } else {
        setTargetRect(null)
      }
    } else {
      setTargetRect(null)
    }
  }, [current.target])

  useEffect(() => {
    if (current.target) {
      const el = document.querySelector(current.target)
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' })
      const timer = setTimeout(updateTargetRect, 400)
      return () => clearTimeout(timer)
    } else {
      setTargetRect(null)
    }
  }, [step, current.target, updateTargetRect])

  return (
    <>
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={handleClose}
        style={{
          position: 'fixed', inset: 0,
          background: 'rgba(0,0,0,0.6)',
          zIndex: 8000,
        }}
      />

      {/* Spotlight */}
      <AnimatePresence>
        {current.target && targetRect && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{
              position: 'fixed',
              top: targetRect.top - 8,
              left: targetRect.left - 8,
              width: targetRect.width + 16,
              height: targetRect.height + 16,
              borderRadius: 16,
              border: '2.5px solid #D97757',
              background: 'rgba(255,255,255,0.08)',
              boxShadow: '0 0 0 5px rgba(217,119,87,0.2), 0 0 20px rgba(217,119,87,0.15)',
              zIndex: 8001,
              pointerEvents: 'none',
              transition: 'all 0.35s cubic-bezier(0.4,0,0.2,1)',
            }}
          />
        )}
      </AnimatePresence>

      {/* Tooltip — always bottom-center, shifted right on desktop for sidebar */}
      <motion.div
        key={step}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: navigating ? 0.6 : 1, y: 0 }}
        exit={{ opacity: 0, y: 20 }}
        transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        style={{
          position: 'fixed',
          bottom: 'calc(24px + env(safe-area-inset-bottom))',
          left: 16,
          right: 16,
          zIndex: 8002,
          // On desktop: shift right to account for 240px sidebar
          maxWidth: 420,
          marginLeft: 'auto',
          marginRight: 'auto',
          background: 'white',
          borderRadius: 18,
          padding: '18px 20px 20px',
          boxShadow: '0 -4px 40px rgba(0,0,0,0.2), 0 0 0 1px rgba(0,0,0,0.05)',
        }}
        className="lg:left-[calc(50%+120px)] lg:right-auto lg:translate-x-[-50%]"
      >
        {/* Progress bar */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 14 }}>
          {TOUR_STEPS.map((_, i) => (
            <div
              key={i}
              style={{
                flex: 1, height: 3, borderRadius: 999,
                background: i <= step ? '#D97757' : '#F0F0F2',
                transition: 'background 0.3s',
              }}
            />
          ))}
        </div>

        {/* Header row */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 22 }}>{current.emoji}</span>
            <span style={{
              fontSize: 11, fontWeight: 700, fontFamily: 'Inter',
              color: '#D97757', letterSpacing: '0.5px', textTransform: 'uppercase',
            }}>
              {step + 1} / {TOUR_STEPS.length}
            </span>
          </div>
          <button
            onClick={handleClose}
            style={{
              background: '#F4F4F5', border: 'none', borderRadius: 999,
              width: 28, height: 28, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}
          >
            <X size={14} color="#6B6B6B" />
          </button>
        </div>

        <h3 style={{
          fontFamily: 'Bricolage Grotesque, sans-serif',
          fontSize: 18, fontWeight: 800, color: '#0F0F0F',
          margin: '0 0 6px', lineHeight: 1.3,
        }}>
          {current.title}
        </h3>

        <p style={{
          fontSize: 13, color: '#6B6B6B', fontFamily: 'Inter, sans-serif',
          lineHeight: 1.55, margin: '0 0 16px',
        }}>
          {current.body}
        </p>

        <div style={{ display: 'flex', gap: 8 }}>
          {step > 0 && (
            <button
              onClick={prev}
              disabled={navigating}
              style={{
                padding: '10px 14px', borderRadius: 10,
                border: '1.5px solid #E4E4E7', background: 'white',
                fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: '#0F0F0F',
                cursor: navigating ? 'not-allowed' : 'pointer',
                display: 'flex', alignItems: 'center', gap: 4,
                opacity: navigating ? 0.4 : 1, flexShrink: 0,
              }}
            >
              <ArrowLeft size={14} />
              Back
            </button>
          )}

          <button
            onClick={next}
            disabled={navigating}
            style={{
              flex: 1, padding: '11px 16px', borderRadius: 10, border: 'none',
              background: current.last ? 'linear-gradient(135deg, #12B76A, #0E9B58)' : '#D97757',
              fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'white',
              cursor: navigating ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              boxShadow: current.last ? '0 4px 16px rgba(18,183,106,0.35)' : '0 4px 16px rgba(217,119,87,0.35)',
              opacity: navigating ? 0.6 : 1,
            }}
          >
            {navigating ? (
              <>
                <div style={{
                  width: 14, height: 14,
                  border: '2px solid rgba(255,255,255,0.3)',
                  borderTopColor: 'white',
                  borderRadius: 999,
                  animation: 'spin 0.8s linear infinite',
                }} />
                Loading...
              </>
            ) : current.last ? (
              'Start delivering! 🚀'
            ) : (
              <>Next <ArrowRight size={15} /></>
            )}
          </button>
        </div>

        {!current.last && (
          <button
            onClick={handleClose}
            style={{
              display: 'block', width: '100%', textAlign: 'center',
              background: 'none', border: 'none', color: '#9B9B9B',
              fontSize: 12, fontFamily: 'Inter', cursor: 'pointer',
              marginTop: 10, padding: 4,
            }}
          >
            Skip tour
          </button>
        )}
      </motion.div>
    </>
  )
}

export default AppTour
