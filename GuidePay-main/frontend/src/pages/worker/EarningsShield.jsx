import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, TrendingUp, Shield, DollarSign, BarChart3 } from 'lucide-react'
import { getMyEarnings, getEarningsShieldSummary } from '../../services/api'
import { formatINR } from '../../utils/formatters'
import ChatWidget from '../../components/chat/ChatWidget'
import BottomNav from '../../components/ui/BottomNav'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

export default function EarningsShield() {
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [shieldSummary, setShieldSummary] = useState(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [res, summaryRes] = await Promise.allSettled([
          getMyEarnings(),
          getEarningsShieldSummary(),
        ])
        if (res.status === 'fulfilled') setData(res.value)
        if (summaryRes.status === 'fulfilled') setShieldSummary(summaryRes.value)
      } catch {
        setData(null)
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [])

  const summary = data?.summary || {
    total_payouts: 0,
    total_premiums: 0,
    total_claims: 0,
    net_protection: 0,
    roi_percent: 0,
  }

  const monthlyPayouts = data?.monthly_payouts || []
  const monthlyPremiums = data?.monthly_premiums || []
  const allMonths = new Set([...monthlyPayouts.map((m) => m._id), ...monthlyPremiums.map((m) => m._id)])
  const chartData = Array.from(allMonths).sort().map((month) => {
    const payout = monthlyPayouts.find((item) => item._id === month)
    const premium = monthlyPremiums.find((item) => item._id === month)
    const [year, monthNum] = month.split('-')
    return {
      month: `${MONTH_NAMES[parseInt(monthNum, 10) - 1]} '${year.slice(2)}`,
      payouts: payout?.total_payout || 0,
      premiums: premium?.total_premium || 0,
      claims: payout?.claim_count || 0,
    }
  })

  const maxVal = Math.max(...chartData.map((row) => Math.max(row.payouts, row.premiums)), 100)

  return (
    <motion.div className="min-h-screen pb-24" style={{ background: 'var(--bg-secondary)' }} variants={pageVariants} initial="initial" animate="animate" exit="exit">
      <div style={{ background: 'linear-gradient(135deg, #1a1a2e, #16213e)', padding: '16px 16px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
          <button onClick={() => navigate(-1)} style={{ background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.2)', borderRadius: 999, width: 36, height: 36, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <ArrowLeft size={18} color="white" />
          </button>
          <div>
            <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: 800, color: 'white', margin: 0 }}>Earnings Shield</h1>
            <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', fontFamily: 'Inter', margin: '2px 0 0' }}>Your income protection overview</p>
          </div>
        </div>

        <div style={{ textAlign: 'center', padding: '8px 0' }}>
          <p style={{ fontSize: 11, fontWeight: 700, color: 'rgba(255,255,255,0.5)', letterSpacing: '1.5px', textTransform: 'uppercase', fontFamily: 'Inter', margin: '0 0 4px' }}>NET PROTECTION VALUE</p>
          <span style={{ fontFamily: 'Bricolage Grotesque', fontSize: 48, fontWeight: 800, color: summary.net_protection >= 0 ? '#12B76A' : '#F04438', letterSpacing: -2 }}>
            {summary.net_protection >= 0 ? '+' : ''}{formatINR(summary.net_protection)}
          </span>
          <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)', fontFamily: 'Inter', margin: '4px 0 0' }}>
            {summary.roi_percent > 0 ? `${summary.roi_percent}% return on premiums` : 'Live earnings data'}
          </p>
        </div>
      </div>

      <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>

        {/* Monthly Shield Summary Headline */}
        {shieldSummary && (
          <div style={{ background: 'linear-gradient(135deg, #12B76A, #0A9456)', borderRadius: 16, padding: '18px 20px' }}>
            <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter', color: 'rgba(255,255,255,0.7)', textTransform: 'uppercase', letterSpacing: '1px', margin: '0 0 6px' }}>
              This Month
            </p>
            <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: 800, color: 'white', margin: '0 0 14px', lineHeight: 1.3 }}>
              {shieldSummary.message}
            </p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
              {[
                { label: 'Triggers', value: shieldSummary.triggers_faced },
                { label: 'Payouts', value: `₹${shieldSummary.actual_payouts || 0}` },
                { label: 'Protection Ratio', value: `${shieldSummary.protection_ratio || 0}%` },
              ].map((s) => (
                <div key={s.label} style={{ background: 'rgba(255,255,255,0.15)', borderRadius: 10, padding: '10px 12px' }}>
                  <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.7)', fontFamily: 'Inter', margin: '0 0 4px', textTransform: 'uppercase' }}>{s.label}</p>
                  <p style={{ fontSize: 18, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: 'white', margin: 0 }}>{s.value}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {[
            { icon: DollarSign, label: 'Total Payouts', value: formatINR(summary.total_payouts), color: '#12B76A', bg: '#ECFDF3' },
            { icon: Shield, label: 'Premiums Paid', value: formatINR(summary.total_premiums), color: '#D97757', bg: '#FDF1ED' },
            { icon: BarChart3, label: 'Claims Filed', value: String(summary.total_claims), color: '#2E90FA', bg: '#EFF8FF' },
            { icon: TrendingUp, label: 'ROI', value: `${summary.roi_percent}%`, color: summary.roi_percent > 100 ? '#12B76A' : '#F79009', bg: summary.roi_percent > 100 ? '#ECFDF3' : '#FFFAEB' },
          ].map((stat) => {
            const Icon = stat.icon
            return (
              <div key={stat.label} style={{ background: 'var(--bg-card)', borderRadius: 14, padding: 14, border: '1px solid var(--border-light)' }}>
                <div style={{ width: 32, height: 32, borderRadius: 8, background: stat.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 8 }}>
                  <Icon size={16} color={stat.color} />
                </div>
                <p style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter', fontWeight: 600, textTransform: 'uppercase', margin: 0 }}>{stat.label}</p>
                <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', margin: '2px 0 0' }}>{loading ? '...' : stat.value}</p>
              </div>
            )
          })}
        </div>

        <div style={{ background: 'var(--bg-card)', borderRadius: 14, padding: 16, border: '1px solid var(--border-light)' }}>
          <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 14px' }}>Monthly Breakdown</p>
          {chartData.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <span style={{ fontSize: 32 }}>📊</span>
              <p style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: '8px 0 0' }}>No earnings data yet.</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {chartData.map((row, index) => (
                <div key={row.month}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                    <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', fontFamily: 'Inter' }}>{row.month}</span>
                    <span style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>{row.claims} claim{row.claims !== 1 ? 's' : ''}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
                    <span style={{ fontSize: 10, color: '#12B76A', fontFamily: 'Inter', width: 50, fontWeight: 600 }}>Payout</span>
                    <div style={{ flex: 1, height: 8, background: 'var(--bg-tertiary)', borderRadius: 4, overflow: 'hidden' }}>
                      <motion.div initial={{ width: 0 }} animate={{ width: `${(row.payouts / maxVal) * 100}%` }} transition={{ delay: 0.2 + index * 0.08 }} style={{ height: '100%', background: '#12B76A', borderRadius: 4 }} />
                    </div>
                    <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-primary)', fontFamily: 'Inter', width: 50, textAlign: 'right' }}>{formatINR(row.payouts)}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ fontSize: 10, color: '#D97757', fontFamily: 'Inter', width: 50, fontWeight: 600 }}>Premium</span>
                    <div style={{ flex: 1, height: 8, background: 'var(--bg-tertiary)', borderRadius: 4, overflow: 'hidden' }}>
                      <motion.div initial={{ width: 0 }} animate={{ width: `${(row.premiums / maxVal) * 100}%` }} transition={{ delay: 0.3 + index * 0.08 }} style={{ height: '100%', background: '#D97757', borderRadius: 4 }} />
                    </div>
                    <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-primary)', fontFamily: 'Inter', width: 50, textAlign: 'right' }}>{formatINR(row.premiums)}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <ChatWidget />
      <BottomNav />
    </motion.div>
  )
}
