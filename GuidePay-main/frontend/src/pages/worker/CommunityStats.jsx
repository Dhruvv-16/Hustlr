import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Users, Shield, Zap, Clock, MapPin, TrendingUp, CheckCircle2 } from 'lucide-react'
import { getCommunityStats } from '../../services/api'
import { formatINR } from '../../utils/formatters'
import ChatWidget from '../../components/chat/ChatWidget'
import BottomNav from '../../components/ui/BottomNav'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

function AnimatedCounter({ value, duration = 1.5, prefix = '', suffix = '' }) {
  const [display, setDisplay] = useState(0)
  useEffect(() => {
    const num = typeof value === 'number' ? value : parseFloat(value) || 0
    if (num === 0) { setDisplay(0); return }
    const start = Date.now()
    const end = start + duration * 1000
    const tick = () => {
      const now = Date.now()
      const progress = Math.min((now - start) / (end - start), 1)
      const eased = 1 - Math.pow(1 - progress, 3) // ease-out cubic
      setDisplay(Math.round(eased * num))
      if (progress < 1) requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }, [value])
  return <>{prefix}{display.toLocaleString('en-IN')}{suffix}</>
}

export default function CommunityStats() {
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await getCommunityStats()
        setData(res)
      } catch (e) {
        console.warn('[CommunityStats] API failed:', e.message)
      }
      setLoading(false)
    }
    fetch()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-secondary)' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{
            width: 28, height: 28,
            border: '3px solid var(--border)',
            borderTopColor: '#D97757',
            borderRadius: 999,
            animation: 'spin 0.8s linear infinite',
            margin: '0 auto 12px',
          }} />
          <p style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading community data...</p>
        </div>
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    )
  }

  const stats = data || {
    total_workers: 0,
    active_policies: 0,
    total_claims_processed: 0,
    paid_claims: 0,
    total_payouts_distributed: 0,
    avg_payout_minutes: 0,
    cities_covered: [],
    cities_count: 0,
    total_trigger_events: 0,
    auto_approval_rate: 0,
  }

  return (
    <motion.div
      className="min-h-screen pb-24"
      style={{ background: 'var(--bg-secondary)' }}
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #D97757, #B85C3A)',
        padding: '16px 16px 32px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
          <button
            onClick={() => navigate(-1)}
            style={{
              background: 'rgba(255,255,255,0.15)',
              border: '1px solid rgba(255,255,255,0.25)',
              borderRadius: 999,
              width: 36, height: 36,
              cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            <ArrowLeft size={18} color="white" />
          </button>
          <div>
            <h1 style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 20, fontWeight: 800,
              color: 'white', margin: 0,
            }}>
              Community
            </h1>
            <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)', fontFamily: 'Inter', margin: '2px 0 0' }}>
              GuidePay network stats
            </p>
          </div>
        </div>

        {/* Hero stat */}
        <div style={{ textAlign: 'center' }}>
          <p style={{ fontSize: 11, fontWeight: 700, color: 'rgba(255,255,255,0.6)', letterSpacing: '1.5px', textTransform: 'uppercase', fontFamily: 'Inter', margin: '0 0 4px' }}>
            TOTAL PAYOUTS DISTRIBUTED
          </p>
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
          >
            <span style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 44, fontWeight: 800,
              color: 'white',
              letterSpacing: -2,
            }}>
              {formatINR(stats.total_payouts_distributed)}
            </span>
          </motion.div>
          <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.8)', fontFamily: 'Inter', margin: '4px 0 0' }}>
            across {stats.paid_claims} claims paid
          </p>
        </div>
      </div>

      <div style={{ padding: 16, marginTop: -16, display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* Stats grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {[
            { icon: Users, label: 'Workers Protected', value: stats.total_workers, color: '#2E90FA', bg: '#EFF8FF' },
            { icon: Shield, label: 'Active Policies', value: stats.active_policies, color: '#12B76A', bg: '#ECFDF3' },
            { icon: Zap, label: 'Triggers Detected', value: stats.total_trigger_events, color: '#F79009', bg: '#FFFAEB' },
            { icon: Clock, label: 'Avg Payout Time', value: stats.avg_payout_minutes, suffix: ' min', color: '#D97757', bg: '#FDF1ED' },
          ].map((stat, i) => {
            const Icon = stat.icon
            return (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 + i * 0.08 }}
                style={{
                  background: 'var(--bg-card)',
                  borderRadius: 14,
                  padding: 14,
                  border: '1px solid var(--border-light)',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
                }}
              >
                <div style={{
                  width: 32, height: 32, borderRadius: 8,
                  background: stat.bg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  marginBottom: 8,
                }}>
                  <Icon size={16} color={stat.color} />
                </div>
                <p style={{
                  fontFamily: 'Bricolage Grotesque', fontSize: 24, fontWeight: 800,
                  color: 'var(--text-primary)', margin: '0 0 2px',
                }}>
                  <AnimatedCounter value={stat.value} suffix={stat.suffix || ''} />
                </p>
                <p style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px', margin: 0 }}>
                  {stat.label}
                </p>
              </motion.div>
            )
          })}
        </div>

        {/* Trust indicators */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 14,
          padding: 16,
          border: '1px solid var(--border-light)',
        }}>
          <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 12px' }}>
            Trust Indicators
          </p>
          {[
            { label: 'Auto-Approval Rate', value: `${stats.auto_approval_rate}%`, desc: 'Claims processed automatically' },
            { label: 'Claims Processed', value: String(stats.total_claims_processed), desc: 'Total claims handled' },
            { label: 'Cities Covered', value: String(stats.cities_count), desc: stats.cities_covered.join(', ') || 'No cities yet' },
          ].map((item, i) => (
            <div key={item.label} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '10px 0',
              borderTop: i > 0 ? '1px solid var(--border-light)' : 'none',
            }}>
              <div>
                <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-primary)', margin: 0 }}>
                  {item.label}
                </p>
                <p style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: '2px 0 0' }}>
                  {item.desc}
                </p>
              </div>
              <span style={{
                fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: 800,
                color: '#D97757',
              }}>
                {item.value}
              </span>
            </div>
          ))}
        </div>

        {/* How it works */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 14,
          padding: 16,
          border: '1px solid var(--border-light)',
        }}>
          <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 12px' }}>
            How GuidePay Protects Workers
          </p>
          {[
            { emoji: '📡', text: 'We monitor IMD, Downdetector, and government alerts 24/7' },
            { emoji: '⚡', text: 'AI automatically verifies worker activity and detects fraud' },
            { emoji: '💸', text: 'Payouts are sent to your UPI within minutes — no claim forms' },
            { emoji: '🛡️', text: 'Coverage starts from just ₹49/week for ₹600 protection' },
          ].map((item, i) => (
            <div key={i} style={{
              display: 'flex', gap: 10, alignItems: 'flex-start',
              marginBottom: i < 3 ? 10 : 0,
            }}>
              <span style={{ fontSize: 16, flexShrink: 0 }}>{item.emoji}</span>
              <p style={{ fontSize: 13, color: 'var(--text-secondary)', fontFamily: 'Inter', lineHeight: 1.5, margin: 0 }}>
                {item.text}
              </p>
            </div>
          ))}
        </div>

        {/* CTA */}
        <motion.button
          onClick={() => navigate('/coverage')}
          whileTap={{ scale: 0.97 }}
          style={{
            width: '100%', padding: 14,
            borderRadius: 12, border: 'none',
            background: 'linear-gradient(135deg, #D97757, #B85C3A)',
            color: 'white', fontSize: 15,
            fontWeight: 700, fontFamily: 'Bricolage Grotesque',
            cursor: 'pointer',
            boxShadow: '0 4px 16px rgba(217,119,87,0.35)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}
        >
          🛡️ Join the Community — Get Covered
        </motion.button>
      </div>

      <ChatWidget />
      <BottomNav />
    </motion.div>
  )
}
