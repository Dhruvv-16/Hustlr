import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ShieldCheck } from 'lucide-react'
import TopBar from '../../components/ui/TopBar'
import Button from '../../components/ui/Button'
import { useWorkerStore } from '../../store/workerStore'
import { getBreakdown } from '../../utils/premium'
import { useCountUp } from '../../hooks/useCountUp'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

export default function Premium() {
  const navigate = useNavigate()
  const worker = useWorkerStore((s) => s.worker)
  const setActivePolicy = useWorkerStore((s) => s.setActivePolicy)
  const zone = worker?.zone || 'kondapur-hyderabad'
  const score = worker?.riskScore || 0.82
  const bd = getBreakdown(zone, score)
  const animatedTotal = useCountUp(bd.total, 1000)

  const activatePolicy = () => {
    const now = new Date()
    const weekEnd = new Date(now)
    weekEnd.setDate(now.getDate() + 7)

    setActivePolicy({
      planId: 'standard',
      planName: 'Standard',
      price: bd.total,
      coverage: 600,
      weekStart: now.toISOString(),
      weekEnd: weekEnd.toISOString(),
      paymentId: 'GP_' + Date.now(),
      status: 'ACTIVE',
    })
    navigate('/payment-success')
  }

  const handleActivate = () => {
    // Razorpay integration
    if (window.Razorpay) {
      const options = {
        key: import.meta.env.VITE_RAZORPAY_KEY || 'rzp_test_demo',
        amount: bd.total * 100,
        currency: 'INR',
        name: 'GuidePay',
        description: 'Weekly Income Protection',
        handler: () => activatePolicy(),
        prefill: { contact: worker?.phone || '9876543210' },
        theme: { color: '#D97757' },
      }
      const rzp = new window.Razorpay(options)
      rzp.open()
    } else {
      // Mock mode — no Razorpay SDK loaded
      activatePolicy()
    }
  }

  return (
    <motion.div
      className="min-h-screen pb-36"
      style={{ background: 'var(--bg-primary)' }}
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      <TopBar title="Your weekly premium" showBack />

      {/* Hero */}
      <div className="px-6 py-8 text-center">
        <p className="text-[11px] font-semibold font-body tracking-[1.5px] uppercase mb-2" style={{ color: 'var(--text-tertiary)' }}>
          Weekly Premium
        </p>
        <div className="font-display font-extrabold text-[72px] tracking-[-3px] leading-none" style={{ color: 'var(--text-primary)' }}>
          ₹{animatedTotal}
        </div>
        <p className="text-[14px] font-body mt-2" style={{ color: 'var(--text-secondary)' }}>
          per week · auto-renews Sundays
        </p>
        <div className="inline-block mt-3 bg-success-light rounded-pill px-3 py-1">
          <span className="text-[10px] font-semibold font-body text-success tracking-[1px] uppercase">
            Low Risk Discount Applied
          </span>
        </div>
      </div>

      <div className="px-4">
        {/* Breakdown card */}
        <div className="rounded-card shadow-card overflow-hidden mb-3" style={{ background: 'var(--bg-card)' }}>
          <div className="px-4 py-3.5" style={{ borderBottom: '1px solid var(--border-light)' }}>
            <p className="text-[14px] font-semibold font-body" style={{ color: 'var(--text-primary)' }}>
              How it's calculated
            </p>
          </div>
          {[
            { label: 'Base premium',       value: `₹${bd.base}`,  color: 'var(--text-primary)' },
            { label: 'Flood zone',         value: `+₹${bd.zone}`, color: '#F04438' },
            { label: 'Zone adjustment',    value: '+₹2',          color: '#F79009' },
            { label: 'Risk score discount',value: `−₹${Math.abs(bd.worker)}`, color: '#12B76A' },
          ].map((row, i, arr) => (
            <div
              key={row.label}
              className="flex items-center justify-between px-4 py-3"
              style={{ borderBottom: i < arr.length - 1 ? '1px solid var(--border-light)' : 'none' }}
            >
              <span className="text-[14px] font-body" style={{ color: 'var(--text-primary)' }}>{row.label}</span>
              <span className="font-display text-[14px] font-semibold" style={{ color: row.color }}>
                {row.value}
              </span>
            </div>
          ))}
          <div className="flex items-center justify-between px-4 py-3.5" style={{ background: 'var(--bg-secondary)' }}>
            <span className="text-[14px] font-semibold font-body" style={{ color: 'var(--text-primary)' }}>Total / week</span>
            <span className="font-display text-[20px] font-bold" style={{ color: 'var(--text-primary)' }}>₹{bd.total}</span>
          </div>
        </div>

        {/* Coverage card */}
        <div className="rounded-card shadow-card p-4 mb-3" style={{ background: 'var(--bg-card)' }}>
          <div className="flex items-center justify-between mb-3">
            <span className="text-[13px] font-body" style={{ color: 'var(--text-secondary)' }}>Covered up to</span>
            <span className="font-display text-[18px] font-bold text-brand">₹600 / week</span>
          </div>
          <div className="h-px mb-3" style={{ background: 'var(--border-light)' }} />
          {[
            { icon: '🌊', label: 'Flood alerts',      payout: '₹600', pct: '100%', color: '#12B76A' },
            { icon: '📱', label: 'Platform outages',  payout: '₹450', pct: '75%',  color: 'var(--text-secondary)' },
            { icon: '🚫', label: 'Curfews',           payout: '₹600', pct: '100%', color: '#12B76A' },
          ].map((row) => (
            <div key={row.label} className="flex items-center justify-between py-2.5">
              <div className="flex items-center gap-2.5">
                <ShieldCheck size={16} className="text-brand" />
                <span className="text-[14px] font-body" style={{ color: 'var(--text-primary)' }}>{row.label}</span>
              </div>
              <div className="text-right">
                <span className="text-[13px] font-semibold font-body" style={{ color: row.color }}>
                  {row.pct} ({row.payout})
                </span>
              </div>
            </div>
          ))}
          <p className="text-[12px] font-body mt-3" style={{ color: 'var(--text-tertiary)' }}>
            Health, vehicle repairs and accidents not covered
          </p>
        </div>
      </div>

      {/* Sticky bottom — desktop aware */}
      <div
        className="fixed bottom-0 left-0 right-0 lg:left-[240px]"
        style={{
          padding: '12px 16px',
          paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
          background: 'var(--bg-card)',
          borderTop: '1px solid var(--border-light)',
          zIndex: 40,
        }}
      >
        <div style={{ maxWidth: 560, width: '100%', margin: '0 auto' }}>
          <Button onClick={handleActivate} fullWidth>
            Activate for ₹{bd.total}/week →
          </Button>
          <Button
            variant="ghost"
            onClick={() => navigate('/zone')}
            fullWidth
            className="mt-2"
          >
            ← Change my zone
          </Button>
        </div>
      </div>
    </motion.div>
  )
}
