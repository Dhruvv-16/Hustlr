import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { useWorkerStore } from '../store/workerStore'

// ── Count-up hook ─────────────────────────────────────────────────────
function useCountUp(target, duration = 1500) {
  const [count, setCount] = useState(0)
  const frameRef = useRef(null)
  useEffect(() => {
    const start = performance.now()
    const step = (now) => {
      const elapsed = now - start
      const progress = Math.min(elapsed / duration, 1)
      setCount(Math.floor(progress * target))
      if (progress < 1) frameRef.current = requestAnimationFrame(step)
    }
    frameRef.current = requestAnimationFrame(step)
    return () => cancelAnimationFrame(frameRef.current)
  }, [target, duration])
  return count
}

// ── Slide visuals ─────────────────────────────────────────────────────
const TriggerVisual = () => (
  <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 24 }}>
    {[
      { icon: '🌊', label: 'Flood',  color: '#2E90FA' },
      { icon: '📱', label: 'Outage', color: '#F79009' },
      { icon: '🚫', label: 'Curfew', color: '#7C3AED' },
    ].map((t, i) => (
      <motion.div
        key={i}
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ delay: i * 0.15, type: 'spring', stiffness: 200 }}
        style={{
          width: 80, height: 80, borderRadius: 20,
          background: `${t.color}15`,
          border: `1.5px solid ${t.color}30`,
          display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', gap: 6,
        }}
      >
        <span style={{ fontSize: 28 }}>{t.icon}</span>
        <p style={{ fontSize: 11, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: t.color, margin: 0 }}>{t.label}</p>
      </motion.div>
    ))}
  </div>
)

const VerificationVisual = () => (
  <motion.div
    initial={{ opacity: 0, y: 16 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ delay: 0.3 }}
    style={{
      marginTop: 24, background: '#ECFDF3', borderRadius: 14,
      padding: 16, display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
    }}
  >
    <div style={{ width: 40, height: 40, borderRadius: 999, background: '#12B76A', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
      <span style={{ color: 'white', fontSize: 18 }}>✓</span>
    </div>
    <div>
      <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#065F46', margin: '0 0 2px' }}>Activity verified</p>
      <p style={{ fontSize: 12, color: '#065F46', fontFamily: 'Inter, sans-serif', margin: 0, opacity: 0.7 }}>Last order 38 min before trigger</p>
    </div>
  </motion.div>
)

const PayoutVisual = () => {
  const count = useCountUp(600, 1500)
  return (
    <motion.div
      initial={{ scale: 0.8, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      style={{
        textAlign: 'center', marginTop: 24, padding: 20,
        background: 'rgba(247,144,9,0.08)', borderRadius: 16,
        border: '1px solid rgba(247,144,9,0.2)',
      }}
    >
      <p style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 56, fontWeight: 800, color: '#F79009', margin: 0, letterSpacing: -2 }}>
        ₹{count}
      </p>
      <p style={{ fontSize: 13, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', margin: '4px 0 0' }}>Auto-credited to your UPI</p>
    </motion.div>
  )
}

const ScoreVisual = () => (
  <motion.div
    initial={{ opacity: 0, y: 16 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ delay: 0.3 }}
    style={{ marginTop: 24, background: '#F5F3FF', borderRadius: 14, padding: 16 }}
  >
    {[
      { label: 'Deliveries this week', value: 24, max: 30, color: '#7C3AED' },
      { label: 'Claim accuracy',       value: 100, max: 100, color: '#12B76A' },
      { label: 'Active hours',         value: 8,   max: 10, color: '#F79009' },
    ].map((bar, i) => (
      <div key={i} style={{ marginBottom: i < 2 ? 12 : 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
          <span style={{ fontSize: 12, fontFamily: 'Inter, sans-serif', color: '#6B6B6B' }}>{bar.label}</span>
          <span style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: bar.color }}>{bar.value}/{bar.max}</span>
        </div>
        <div style={{ height: 6, borderRadius: 999, background: 'rgba(0,0,0,0.08)' }}>
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${(bar.value / bar.max) * 100}%` }}
            transition={{ delay: 0.4 + i * 0.1, duration: 0.8 }}
            style={{ height: '100%', borderRadius: 999, background: bar.color }}
          />
        </div>
      </div>
    ))}
  </motion.div>
)

const PagesVisual = () => {
  const tabs = [
    { icon: '🏠', label: 'Home',     color: '#D97757' },
    { icon: '🛡️', label: 'Coverage', color: '#2E90FA' },
    { icon: '📋', label: 'Claims',   color: '#12B76A' },
    { icon: '📊', label: 'Forecast', color: '#7C3AED' },
    { icon: '👤', label: 'Profile',  color: '#F79009' },
  ]
  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.3 }}
      style={{ marginTop: 24 }}
    >
      <div style={{ background: '#F4F4F5', borderRadius: 16, padding: '16px 8px', display: 'flex', justifyContent: 'space-around' }}>
        {tabs.map((tab, i) => (
          <motion.div
            key={i}
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.1 + i * 0.08, type: 'spring', stiffness: 250 }}
            style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}
          >
            <div style={{
              width: 48, height: 48, borderRadius: 14,
              background: `${tab.color}18`,
              border: `1.5px solid ${tab.color}30`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22,
            }}>
              {tab.icon}
            </div>
            <p style={{ fontSize: 10, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: tab.color, margin: 0 }}>{tab.label}</p>
          </motion.div>
        ))}
      </div>
      <p style={{ fontSize: 12, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', textAlign: 'center', marginTop: 12 }}>
        Swipe between tabs to navigate your dashboard
      </p>
    </motion.div>
  )
}

// ── Tour slides ───────────────────────────────────────────────────────
const TOUR_STEPS = [
  {
    id: 'welcome',
    emoji: '👋',
    bg: '#FDF1ED',
    accent: '#D97757',
    title: 'Welcome to GuidePay',
    headline: 'You are now protected.',
    body: 'Your first week of income protection starts today. We will auto-pay you when floods, platform outages, or curfews stop you from working.',
    action: 'Show me how',
  },
  {
    id: 'triggers',
    emoji: '🌊',
    bg: '#EFF8FF',
    accent: '#2E90FA',
    title: 'Your 3 Triggers',
    headline: 'We watch so you don\'t have to.',
    body: 'GuidePay monitors IMD flood alerts, Zepto/Swiggy/Blinkit status pages, and government orders — every 15 minutes, all day, every day.',
    visual: 'triggers',
    action: 'Got it',
  },
  {
    id: 'verification',
    emoji: '✅',
    bg: '#F0FDF4',
    accent: '#12B76A',
    title: 'Activity Verification',
    headline: 'We check you were working.',
    body: 'Before paying, we check your last completed delivery. If you were active within 6 hours of the event — you get paid automatically.',
    visual: 'verification',
    action: 'Makes sense',
  },
  {
    id: 'payout',
    emoji: '⚡',
    bg: '#FFFAEB',
    accent: '#F79009',
    title: 'Instant UPI Payout',
    headline: '₹600 in under 2 hours.',
    body: 'Once verified, money goes directly to your UPI. No bank forms, no waiting, no calling anyone. You will get a notification the moment it\'s sent.',
    visual: 'payout',
    action: 'Perfect',
  },
  {
    id: 'risk-score',
    emoji: '📊',
    bg: '#F5F3FF',
    accent: '#7C3AED',
    title: 'Your Risk Score',
    headline: 'Deliver more, pay less.',
    body: 'Your weekly premium adjusts based on your delivery activity and claim history. Consistent workers get up to 15% off — automatically every renewal.',
    visual: 'score',
    action: 'Understood',
  },
  {
    id: 'dashboard',
    emoji: '🏠',
    bg: '#FDF1ED',
    accent: '#D97757',
    title: 'Your Dashboard',
    headline: 'Everything in one place.',
    body: 'Your dashboard shows active coverage, zone status, AI flood forecasts, and recent payouts. Use the tabs below to navigate all features.',
    visual: 'pages',
    action: 'Take me there',
    last: true,
  },
]

export default function Onboarding() {
  const [step, setStep] = useState(0)
  const navigate = useNavigate()
  const setOnboarded = useWorkerStore(s => s.setOnboarded)
  const current = TOUR_STEPS[step]

  const finish = () => {
    setOnboarded(true)
    if ('Notification' in window) Notification.requestPermission()
    navigate('/dashboard')
  }

  const next = () => {
    if (current.last) finish()
    else setStep(s => s + 1)
  }

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 9998,
      background: 'white',
      display: 'flex', flexDirection: 'column',
      overflowY: 'auto',
    }}>

      {/* Progress bar */}
      <div style={{ height: 3, background: '#F4F4F5', flexShrink: 0 }}>
        <motion.div
          animate={{ width: `${((step + 1) / TOUR_STEPS.length) * 100}%` }}
          transition={{ duration: 0.3 }}
          style={{ height: '100%', background: current.accent }}
        />
      </div>

      {/* Skip */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', padding: '14px 20px', flexShrink: 0 }}>
        <button
          onClick={finish}
          style={{ background: 'none', border: 'none', fontSize: 14, fontFamily: 'Inter, sans-serif', fontWeight: 500, color: '#9B9B9B', cursor: 'pointer' }}
        >
          Skip →
        </button>
      </div>

      {/* Slide content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 28px', textAlign: 'center' }}>
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
            transition={{ duration: 0.22 }}
            style={{ width: '100%', maxWidth: 360 }}
          >
            {/* Emoji circle */}
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 200, damping: 15, delay: 0.1 }}
              style={{
                width: 100, height: 100, borderRadius: 28,
                background: current.bg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 48, margin: '0 auto 28px',
              }}
            >
              {current.emoji}
            </motion.div>

            {/* Tag */}
            <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: current.accent, letterSpacing: '2px', textTransform: 'uppercase', margin: '0 0 10px' }}>
              {current.title}
            </p>

            {/* Headline */}
            <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 28, fontWeight: 800, color: '#0F0F0F', margin: '0 0 14px', lineHeight: 1.2 }}>
              {current.headline}
            </h2>

            {/* Body */}
            <p style={{ fontSize: 16, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', lineHeight: 1.7, margin: 0 }}>
              {current.body}
            </p>

            {/* Visuals */}
            {current.visual === 'triggers'     && <TriggerVisual />}
            {current.visual === 'verification' && <VerificationVisual />}
            {current.visual === 'payout'       && <PayoutVisual />}
            {current.visual === 'score'        && <ScoreVisual />}
            {current.visual === 'pages'        && <PagesVisual />}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom controls */}
      <div style={{ padding: '20px 24px 44px', display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'center', flexShrink: 0 }}>
        {/* Dots */}
        <div style={{ display: 'flex', gap: 6 }}>
          {TOUR_STEPS.map((_, i) => (
            <motion.div
              key={i}
              animate={{
                width: i === step ? 20 : 6,
                background: i === step ? current.accent : '#E4E4E7',
                opacity: i <= step ? 1 : 0.4,
              }}
              style={{ height: 6, borderRadius: 999 }}
              transition={{ duration: 0.2 }}
            />
          ))}
        </div>

        {/* CTA */}
        <motion.button
          onClick={next}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.97 }}
          style={{
            width: '100%', maxWidth: 360, padding: '15px', borderRadius: 12, border: 'none',
            background: `linear-gradient(135deg, ${current.accent}, ${current.accent}cc)`,
            color: 'white', fontSize: 16, fontWeight: 700,
            fontFamily: 'Inter, sans-serif', cursor: 'pointer',
            boxShadow: `0 4px 20px ${current.accent}40`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}
        >
          {current.action}
          {current.last && <ArrowRight size={18} />}
        </motion.button>
      </div>
    </div>
  )
}
