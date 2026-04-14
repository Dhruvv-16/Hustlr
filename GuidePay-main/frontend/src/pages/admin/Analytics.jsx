import { useNavigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  BarChart, Bar, LineChart, Line, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer,
} from 'recharts'
import TopBar from '../../components/ui/TopBar'
import { getAdminAnalytics, getFraudAnalytics } from '../../services/api'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const ADMIN_TABS = [
  { id: 'overview',  label: 'Overview',  path: '/admin' },
  { id: 'claims',    label: 'Claims',    path: '/admin/claims' },
  { id: 'analytics', label: 'Analytics', path: '/admin/analytics' },
]

function AdminBottomNav({ active }) {
  const navigate = useNavigate()
  return (
    <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] z-50 bg-white border-t border-grey-200">
      <div className="flex h-14">
        {ADMIN_TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => navigate(tab.path)}
            className={`flex-1 flex items-center justify-center text-[13px] font-semibold font-body transition-colors ${active === tab.id ? 'text-brand border-t-2 border-brand' : 'text-grey-400'}`}
          >
            {tab.label}
          </button>
        ))}
      </div>
    </div>
  )
}

const tooltipStyle = {
  contentStyle: {
    background: '#fff',
    border: '1px solid #E4E4E7',
    borderRadius: 8,
    boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
    fontFamily: 'Inter',
    fontSize: 13,
  },
}

const axisStyle = {
  tick: { fill: '#9B9B9B', fontSize: 11, fontFamily: 'Inter' },
  stroke: '#E4E4E7',
}

function ChartCard({ title, children }) {
  return (
    <div className="mx-4 bg-white rounded-card shadow-card p-4">
      <p className="text-[14px] font-semibold font-body text-[#0F0F0F] mb-4">{title}</p>
      {children}
    </div>
  )
}

export default function Analytics() {
  const [premiumPayoutData, setPremiumPayoutData] = useState([])
  const [lossRatioData, setLossRatioData] = useState([])
  const [fraudData, setFraudData] = useState(null)
  
  const [loading, setLoading] = useState(true)
  const [period, setPeriod] = useState(30)

  useEffect(() => {
    loadAnalytics()
  }, [period])

  const loadAnalytics = async () => {
    setLoading(true)
    try {
      const p1 = getAdminAnalytics(period).catch(() => null)
      const p2 = getFraudAnalytics().catch(() => null)
      
      const [json, fraudJson] = await Promise.all([p1, p2])
      
      if (fraudJson) {
        setFraudData(fraudJson)
      }

      if (json && (json.daily_revenue?.length > 0 || json.daily_payouts?.length > 0)) {
        const revByWeek = [0, 0, 0, 0]
        const payByWeek = [0, 0, 0, 0]
        json.daily_revenue?.forEach((d, i) => { revByWeek[Math.min(3, Math.floor(i / 7))] += d.amount })
        json.daily_payouts?.forEach((d, i) => { payByWeek[Math.min(3, Math.floor(i / 7))] += d.amount })
        setPremiumPayoutData([
          { week: 'W1', premium: revByWeek[0], payout: payByWeek[0] },
          { week: 'W2', premium: revByWeek[1], payout: payByWeek[1] },
          { week: 'W3', premium: revByWeek[2], payout: payByWeek[2] },
          { week: 'W4', premium: revByWeek[3], payout: payByWeek[3] },
        ])
        
        const lossData = [0, 1, 2, 3].map(i => {
          const rev = revByWeek[i]
          const pay = payByWeek[i]
          return {
            week: `W${i + 1}`,
            ratio: rev > 0 ? Math.round((pay / rev) * 100) : 0,
            target: 65,
          }
        })
        setLossRatioData(lossData)
      } else {
        // Fallback demo charts if no actual chart records exist
        setPremiumPayoutData([
          { week: 'W1', premium: 54000, payout: 19000 },
          { week: 'W2', premium: 51000, payout: 22000 },
          { week: 'W3', premium: 58000, payout: 15000 },
          { week: 'W4', premium: 54000, payout: 33000 },
        ])
        setLossRatioData([
          { week: 'W1', ratio: 35, target: 65 },
          { week: 'W2', ratio: 43, target: 65 },
          { week: 'W3', ratio: 26, target: 65 },
          { week: 'W4', ratio: 61, target: 65 },
        ])
      }
    } catch (e) {
      console.error('[Analytics] load fail', e)
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div className="min-h-screen bg-grey-50 pb-24" variants={pageVariants} initial="initial" animate="animate" exit="exit">
      <TopBar title="Actuarial Analytics" bgClass="bg-grey-50" />

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 60 }}>
          <div style={{ width: 28, height: 28, border: '3px solid #E4E4E7', borderTopColor: '#D97757', borderRadius: 999, animation: 'spin 0.8s linear infinite' }} />
        </div>
      ) : (
        <div className="mt-3 flex flex-col gap-3">
          
          {/* Fraud Analytics Component */}
          {fraudData && (
            <>
              {/* Summary Row */}
              <div className="px-4">
                <div className="bg-white rounded-card shadow-card p-4">
                  <p className="text-[14px] font-semibold font-body text-[#0F0F0F] mb-3">Pipeline Integrity</p>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-grey-50 rounded-[8px] p-3 text-center">
                      <p className="text-[11px] font-bold text-grey-500 uppercase tracking-wider mb-1">Total Analyzed</p>
                      <p className="font-display font-bold text-[20px] text-[#0F0F0F]">{fraudData.summary.total_claims_analyzed}</p>
                    </div>
                    <div className="bg-danger-light border border-danger/20 rounded-[8px] p-3 text-center">
                      <p className="text-[11px] font-bold text-danger uppercase tracking-wider mb-1">Flagged</p>
                      <p className="font-display font-bold text-[20px] text-danger">{fraudData.summary.flagged_for_review}</p>
                    </div>
                    <div className="bg-success-light border border-success/20 rounded-[8px] p-3 text-center">
                      <p className="text-[11px] font-bold text-success uppercase tracking-wider mb-1">Auto-Approved</p>
                      <p className="font-display font-bold text-[20px] text-success">{fraudData.summary.auto_approved}</p>
                    </div>
                    <div className="bg-grey-50 rounded-[8px] p-3 text-center">
                      <p className="text-[11px] font-bold text-grey-500 uppercase tracking-wider mb-1">Detection Rate</p>
                      <p className="font-display font-bold text-[20px] text-[#0F0F0F]">{fraudData.summary.fraud_detection_rate}%</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Signals Breakdown */}
              <ChartCard title="Telemetry Red Flags">
                <div className="grid grid-cols-2 gap-3">
                  <div className="border border-grey-100 rounded-[8px] p-3 flex items-start justify-between">
                    <div>
                      <p className="text-[20px]">🛰️</p>
                      <p className="text-[11px] font-bold text-grey-500 uppercase mt-1 leading-tight">GPS Spoofing<br/>Attempts</p>
                    </div>
                    <span className="font-display font-bold text-[18px] text-[#0F0F0F]">{fraudData.signal_breakdown.gps_spoofing_attempts}</span>
                  </div>
                  <div className="border border-grey-100 rounded-[8px] p-3 flex items-start justify-between">
                    <div>
                      <p className="text-[20px]">🌧️</p>
                      <p className="text-[11px] font-bold text-grey-500 uppercase mt-1 leading-tight">Weather<br/>Mismatches</p>
                    </div>
                    <span className="font-display font-bold text-[18px] text-[#0F0F0F]">{fraudData.signal_breakdown.weather_validation_failures}</span>
                  </div>
                  <div className="border border-grey-100 rounded-[8px] p-3 flex items-start justify-between">
                    <div>
                      <p className="text-[20px]">👤</p>
                      <p className="text-[11px] font-bold text-grey-500 uppercase mt-1 leading-tight">New Account<br/>Flags</p>
                    </div>
                    <span className="font-display font-bold text-[18px] text-[#0F0F0F]">{fraudData.signal_breakdown.new_account_flags}</span>
                  </div>
                  <div className="border border-grey-100 rounded-[8px] p-3 flex items-start justify-between">
                    <div>
                      <p className="text-[20px]">🔄</p>
                      <p className="text-[11px] font-bold text-grey-500 uppercase mt-1 leading-tight">High Freq.<br/>Claimers</p>
                    </div>
                    <span className="font-display font-bold text-[18px] text-[#0F0F0F]">{fraudData.signal_breakdown.high_frequency_claimers}</span>
                  </div>
                </div>
              </ChartCard>

              {/* Top Flagged claims */}
              <div className="mx-4 bg-white rounded-card shadow-card overflow-hidden">
                <div className="px-4 py-3.5 border-b border-grey-100">
                  <span className="text-[14px] font-semibold font-body text-[#0F0F0F]">Top Flagged Submissions</span>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left" style={{ minWidth: 400 }}>
                    <thead>
                      <tr className="bg-grey-50 text-[11px] font-semibold text-[#6B6B6B] uppercase tracking-wide">
                        <th className="px-4 py-3 font-body">Claim ID</th>
                        <th className="px-4 py-3 font-body">Location</th>
                        <th className="px-4 py-3 font-body">Trigger</th>
                        <th className="px-4 py-3 font-body text-right">Fraud Score</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-grey-50 text-[13px] font-body text-[#0F0F0F]">
                      {(fraudData.top_flagged_claims || []).map((claim) => (
                        <tr key={claim.claim_id}>
                          <td className="px-4 py-3 font-mono text-[11px] text-grey-500">{claim.claim_id.slice(0, 8)}</td>
                          <td className="px-4 py-3 font-semibold">{claim.city}</td>
                          <td className="px-4 py-3 bg-grey-50 rounded italic">{claim.trigger_type}</td>
                          <td className="px-4 py-3 text-right">
                            <span className={`px-2 py-1 rounded-[4px] font-bold text-[12px] ${claim.fraud_score > 0.85 ? 'text-white bg-danger' : 'text-[#0F0F0F] bg-warning'}`}>
                              {Math.round(claim.fraud_score * 100)} / 100
                            </span>
                          </td>
                        </tr>
                      ))}
                      {!fraudData.top_flagged_claims?.length && (
                        <tr>
                          <td colSpan="4" className="px-4 py-6 text-center text-[13px] text-[#9B9B9B]">No high-risk claims flagged recently.</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}

          {/* Chart 1: Premium vs Payouts */}
          <ChartCard title="Premium vs Payouts">
            <ResponsiveContainer width="100%" height={180}>
              <BarChart data={premiumPayoutData} barGap={4}>
                <CartesianGrid stroke="#F0F0F2" strokeDasharray="none" vertical={false} />
                <XAxis dataKey="week" {...axisStyle} axisLine={false} tickLine={false} />
                <YAxis {...axisStyle} axisLine={false} tickLine={false} tickFormatter={(v) => `₹${(v/1000).toFixed(0)}K`} />
                <Tooltip {...tooltipStyle} formatter={(v) => [`₹${v.toLocaleString('en-IN')}`, '']} />
                <Bar dataKey="premium" fill="#12B76A" radius={[4, 4, 0, 0]} name="Premium" />
                <Bar dataKey="payout"  fill="#F79009" radius={[4, 4, 0, 0]} name="Payouts" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          {/* Chart 2: Loss ratio trend */}
          <ChartCard title="Loss Ratio Trend">
            <ResponsiveContainer width="100%" height={160}>
              <LineChart data={lossRatioData}>
                <CartesianGrid stroke="#F0F0F2" strokeDasharray="none" vertical={false} />
                <XAxis dataKey="week" {...axisStyle} axisLine={false} tickLine={false} />
                <YAxis {...axisStyle} axisLine={false} tickLine={false} tickFormatter={(v) => `${v}%`} />
                <Tooltip {...tooltipStyle} formatter={(v) => [`${v}%`, '']} />
                <Line
                  type="monotone"
                  dataKey="ratio"
                  stroke="#2E90FA"
                  strokeWidth={2}
                  dot={{ fill: '#2E90FA', r: 4 }}
                  name="Loss Ratio"
                />
                <Line
                  type="monotone"
                  dataKey="target"
                  stroke="#C4C4C4"
                  strokeWidth={1.5}
                  strokeDasharray="4 4"
                  dot={false}
                  name="Target"
                />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

        </div>
      )}
      <AdminBottomNav active="analytics" />
    </motion.div>
  )
}
