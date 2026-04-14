import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  BarChart, Bar, LineChart, Line, PieChart, Pie,
  Cell, XAxis, YAxis, Tooltip, ResponsiveContainer,
  Legend
} from 'recharts'

const MOCK_DATA = {
  kpis: [
    { label: 'Active Policies', value: '847',
      change: '+12%', up: true, icon: '🛡️' },
    { label: 'Weekly Revenue', value: '₹47,770',
      change: '+8%', up: true, icon: '💰' },
    { label: 'Loss Ratio', value: '24.5%',
      change: '-3%', up: false, icon: '📊' },
    { label: 'Avg Payout Time', value: '47 min',
      change: '-12 min', up: false, icon: '⚡' },
    { label: 'Fraud Prevented', value: '₹18,400',
      change: 'This week', up: true, icon: '🔐' },
    { label: 'Auto-Approval Rate', value: '89%',
      change: '+2%', up: true, icon: '✓' },
  ],
  weekly_revenue: [
    { week: 'W1', premium: 38200, payouts: 8400 },
    { week: 'W2', premium: 41100, payouts: 11200 },
    { week: 'W3', premium: 43800, payouts: 9600 },
    { week: 'W4', premium: 47770, payouts: 11700 },
  ],
  trigger_breakdown: [
    { name: 'Flood', value: 67, color: '#2E90FA' },
    { name: 'Outage', value: 24, color: '#F79009' },
    { name: 'Curfew', value: 9, color: '#F04438' },
  ],
  zone_exposure: [
    { zone: 'Kondapur, Hyderabad', workers: 312,
      exposure: 187200, risk: 'HIGH' },
    { zone: 'Kurla, Mumbai', workers: 198,
      exposure: 118800, risk: 'HIGH' },
    { zone: 'T.Nagar, Chennai', workers: 143,
      exposure: 85800, risk: 'MEDIUM' },
    { zone: 'Koramangala, Bengaluru', workers: 127,
      exposure: 76200, risk: 'LOW' },
    { zone: 'Dwarka, Delhi', workers: 67,
      exposure: 40200, risk: 'LOW' },
  ],
  fraud_stats: {
    total_checked: 208,
    auto_approved: 185,
    manual_review: 16,
    rejected: 7,
    money_saved: 18400,
  },
  loss_ratio_trend: [
    { month: 'Nov', ratio: 31 },
    { month: 'Dec', ratio: 28 },
    { month: 'Jan', ratio: 26 },
    { month: 'Feb', ratio: 25 },
    { month: 'Mar', ratio: 24.5 },
  ],
}

const DEMO_PREDICTIONS = {
  portfolio_summary: {
    active_policies: 634,
    weekly_premium_income: 47770,
    expected_claims: 47,
    expected_payout: 28200,
    projected_loss_ratio: 0.591,
    monsoon_intensity: 0.72,
  },
  city_predictions: [
    { city: 'Hyderabad', flood_probability: 0.72, expected_claims: 18, expected_payout: 10800, risk_level: 'HIGH', active_policies: 312 },
    { city: 'Mumbai', flood_probability: 0.85, expected_claims: 16, expected_payout: 9600, risk_level: 'HIGH', active_policies: 198 },
    { city: 'Chennai', flood_probability: 0.58, expected_claims: 8, expected_payout: 4800, risk_level: 'MEDIUM', active_policies: 143 },
    { city: 'Delhi', flood_probability: 0.22, expected_claims: 3, expected_payout: 1800, risk_level: 'LOW', active_policies: 67 },
    { city: 'Bengaluru', flood_probability: 0.12, expected_claims: 2, expected_payout: 1200, risk_level: 'LOW', active_policies: 127 },
  ],
  recommendations: [
    { severity: 'MEDIUM', action: 'Pre-position reserves for Mumbai and Hyderabad', detail: 'High flood probability next week' },
    { severity: 'INFO', action: 'Peak monsoon season active', detail: 'Monsoon intensity 72% — elevated claims expected' },
  ],
}

const InsurerDashboard = () => {
  const [data, setData] = useState(MOCK_DATA)
  const [period, setPeriod] = useState('month')
  const [predictions, setPredictions] = useState(null)
  const [predLoading, setPredLoading] = useState(true)
  const [actuarial, setActuarial] = useState(null)
  const [dashboardStats, setDashboardStats] = useState(null)
  const [statsLoading, setStatsLoading] = useState(true)

  useEffect(() => {
    loadPredictions()
    loadActuarialMetrics()
    loadDashboardStats()
  }, [])

  const loadDashboardStats = async () => {
    setStatsLoading(true)
    try {
      const { getAdminDashboardStats } = await import('../../services/api')
      const res = await getAdminDashboardStats()
      setDashboardStats(res)
    } catch (e) {
      console.error(e)
    } finally {
      setStatsLoading(false)
    }
  }

  const loadActuarialMetrics = async () => {
    try {
      const { getActuarialMetrics } = await import('../../services/api')
      const res = await getActuarialMetrics()
      setActuarial(res)
    } catch (e) {
      // Fallback demo values
      setActuarial({
        combined_ratio_percent: 54.5,
        loss_ratio_percent: 24.5,
        expense_ratio_percent: 30.0,
        policyholder_surplus: 23450,
        claims_frequency: 0.056,
        average_severity: 562,
        projected_annual_gwp: 573240,
        active_policies: 847,
        irdai_compliant: true,
      })
    }
  }

  const loadPredictions = async () => {
    setPredLoading(true)
    try {
      const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true'
      if (!USE_MOCK) {
        const token = localStorage.getItem('gp-token')
        const res = await fetch(
          `${import.meta.env.VITE_API_URL}/api/v1/admin/predictive-analytics`,
          { headers: { Authorization: `Bearer ${token}` } }
        )
        if (res.ok) {
          const data = await res.json()
          setPredictions(data)
        } else {
          setPredictions(DEMO_PREDICTIONS)
        }
      } else {
        setPredictions(DEMO_PREDICTIONS)
      }
    } catch (e) {
      setPredictions(DEMO_PREDICTIONS)
    } finally {
      setPredLoading(false)
    }
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--bg-secondary)',
      paddingBottom: 40,
    }}>
      {/* Header */}
      <div style={{
        background: 'var(--bg-card)',
        borderBottom: '1px solid var(--border)',
        padding: '20px 24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <div>
          <h1 style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 22, fontWeight: 800,
            color: 'var(--text-primary)', margin: 0,
          }}>
            Insurer Dashboard
          </h1>
          <p style={{
            fontSize: 13, fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
            margin: '2px 0 0',
          }}>
            GuidePay Portfolio — Week 14, 2026
          </p>
        </div>
        <div style={{
          background: 'rgba(18,183,106,0.1)',
          border: '1px solid rgba(18,183,106,0.25)',
          borderRadius: 8,
          padding: '6px 12px',
          display: 'flex',
          alignItems: 'center',
          gap: 6,
        }}>
          <div style={{
            width: 6, height: 6,
            borderRadius: 999,
            background: '#12B76A',
          }}/>
          <span style={{
            fontSize: 12, fontWeight: 700,
            fontFamily: 'Inter', color: '#12B76A',
          }}>
            Portfolio Healthy
          </span>
        </div>
      </div>

      <div style={{ padding: 20 }}>

        {/* KPI Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns:
            'repeat(auto-fill, minmax(160px, 1fr))',
          gap: 12,
          marginBottom: 20,
        }}>
          {[
            { label: 'Active Policies', value: statsLoading ? '...' : dashboardStats?.overview?.active_policies || 0, change: '+12%', up: true, icon: '🛡️' },
            { label: 'Weekly Revenue', value: statsLoading ? '...' : `₹${dashboardStats?.financials?.monthly_premium_collected?.toLocaleString() || 0}`, change: '+8%', up: true, icon: '💰' },
            { label: 'Loss Ratio', value: statsLoading ? '...' : (
                <>
                  {dashboardStats?.financials?.loss_ratio || 0}%
                  {dashboardStats?.data_mode === 'demo' && (
                     <span style={{marginLeft: 6, fontSize: 8, background: '#F2F4F7', color: '#344054', padding: '2px 4px', borderRadius: 4, border: '1px solid #D0D5DD', position: 'relative', top: -2}}>DEMO DATA</span>
                  )}
                </>
              ), change: '-3%', up: false, icon: '📊' },
            { label: 'Avg Payout Time', value: statsLoading ? '...' : `${dashboardStats?.financials?.avg_payout_time_minutes || 47} min`, change: '-12 min', up: false, icon: '⚡' },
            { label: 'Auto-Approval Rate', value: statsLoading ? '...' : `${dashboardStats?.financials?.auto_approval_rate || 89}%`, change: '+2%', up: true, icon: '✓' },
          ].map((kpi, idx) => (
            <div key={idx} style={{
              background: 'var(--bg-card)',
              borderRadius: 14,
              padding: '14px 16px',
              border: '1px solid var(--border)',
            }}>
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                marginBottom: 6,
              }}>
                <span style={{ fontSize: 18 }}>
                  {kpi.icon}
                </span>
                <span style={{
                  fontSize: 10, fontWeight: 700,
                  fontFamily: 'Inter',
                  color: kpi.up ? '#12B76A' : '#F04438',
                  background: kpi.up
                    ? 'rgba(18,183,106,0.1)'
                    : 'rgba(240,68,56,0.1)',
                  padding: '2px 6px',
                  borderRadius: 999,
                }}>
                  {kpi.change}
                </span>
              </div>
              <p style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 22, fontWeight: 800,
                color: 'var(--text-primary)',
                margin: '0 0 2px',
              }}>
                {kpi.value}
              </p>
              <p style={{
                fontSize: 11, fontFamily: 'Inter',
                color: 'var(--text-tertiary)', margin: 0,
              }}>
                {kpi.label}
              </p>
            </div>
          ))}
        </div>

        {/* Actuarial Health Section */}
        {actuarial && (
          <div style={{
            background: 'var(--bg-card)',
            border: '1.5px solid #2E90FA',
            borderRadius: 14, padding: 20,
            marginBottom: 20,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
              <div>
                <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: '#2E90FA', letterSpacing: '1px', textTransform: 'uppercase', margin: '0 0 4px' }}>
                  Actuarial Health
                </p>
                <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                  IRDAI-Compliant Metrics
                </p>
              </div>
              <span style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', padding: '4px 10px', borderRadius: 999, background: '#ECFDF3', color: '#12B76A', border: '1px solid rgba(18,183,106,0.3)' }}>
                🏛️ IRDAI Compliant
              </span>
            </div>

            {/* Combined Ratio Gauge */}
            <div style={{ marginBottom: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <span style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)' }}>Combined Ratio (target &lt;100%)</span>
                <span style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: actuarial.combined_ratio_percent < 100 ? '#12B76A' : '#F04438' }}>
                  {actuarial.combined_ratio_percent}%
                </span>
              </div>
              <div style={{ height: 8, background: 'var(--border-light)', borderRadius: 99, overflow: 'hidden' }}>
                <div style={{
                  height: '100%',
                  width: `${Math.min(actuarial.combined_ratio_percent, 100)}%`,
                  background: actuarial.combined_ratio_percent < 80 ? '#12B76A' : actuarial.combined_ratio_percent < 100 ? '#F79009' : '#F04438',
                  borderRadius: 99,
                  transition: 'width 1s ease',
                }} />
              </div>
            </div>

            {/* Ratios side by side */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginBottom: 16 }}>
              {[
                { label: 'Loss Ratio', value: `${actuarial.loss_ratio_percent}%`, color: '#2E90FA' },
                { label: 'Expense Ratio', value: `${actuarial.expense_ratio_percent}%`, color: '#F79009' },
                { label: 'Policy Surplus', value: `₹${(actuarial.policyholder_surplus || 0).toLocaleString('en-IN')}`, color: '#12B76A' },
              ].map(m => (
                <div key={m.label} style={{ background: 'var(--bg-secondary)', borderRadius: 10, padding: '12px 14px' }}>
                  <p style={{ fontSize: 10, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: '0 0 4px', textTransform: 'uppercase', letterSpacing: '0.6px' }}>{m.label}</p>
                  <p style={{ fontSize: 18, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: m.color, margin: 0 }}>{m.value}</p>
                </div>
              ))}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
              {[
                { label: 'Claims Frequency', value: actuarial.claims_frequency?.toFixed(3) || '0.056' },
                { label: 'Avg Severity', value: `₹${actuarial.average_severity || 562}` },
                { label: 'Projected Annual GWP', value: `₹${((actuarial.projected_annual_gwp || 573240) / 100000).toFixed(1)}L` },
              ].map(m => (
                <div key={m.label} style={{ background: 'var(--bg-secondary)', borderRadius: 10, padding: '12px 14px' }}>
                  <p style={{ fontSize: 10, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: '0 0 4px', textTransform: 'uppercase', letterSpacing: '0.6px' }}>{m.label}</p>
                  <p style={{ fontSize: 16, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)', margin: 0 }}>{m.value}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Predictive Analytics Section */}
        <div style={{
          background: '#1A1A1A',
          border: '1px solid rgba(255,255,255,0.07)',
          borderRadius: 14, padding: 20,
          marginBottom: 16,
        }}>
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center', marginBottom: 16,
          }}>
            <div>
              <p style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 16, fontWeight: 700,
                color: 'white', margin: '0 0 3px',
              }}>
                🔮 Next Week Prediction
              </p>
              <p style={{
                fontSize: 12, fontFamily: 'Inter',
                color: 'rgba(255,255,255,0.4)', margin: 0,
              }}>
                ML forecast · Updated every 6 hours
              </p>
            </div>
            <span style={{
              fontSize: 10, fontWeight: 700,
              fontFamily: 'Inter', color: '#D97757',
              background: 'rgba(217,119,87,0.12)',
              padding: '4px 10px', borderRadius: 999,
              border: '1px solid rgba(217,119,87,0.25)',
            }}>
              PREDICTIVE v3
            </span>
          </div>

          {predictions && (
            <>
              {/* Portfolio summary */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(3, 1fr)',
                gap: 10, marginBottom: 16,
              }}>
                {[
                  { label: 'Expected Claims', value: predictions.portfolio_summary.expected_claims, color: '#F79009' },
                  { label: 'Expected Payout', value: `₹${(predictions.portfolio_summary.expected_payout/1000).toFixed(1)}K`, color: '#F04438' },
                  { label: 'Projected Loss Ratio', value: `${Math.round(predictions.portfolio_summary.projected_loss_ratio * 100)}%`, color: predictions.portfolio_summary.projected_loss_ratio > 0.65 ? '#F04438' : '#12B76A' },
                ].map(stat => (
                  <div key={stat.label} style={{
                    background: '#111', borderRadius: 10, padding: '12px 14px',
                  }}>
                    <p style={{
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 20, fontWeight: 800,
                      color: stat.color, margin: '0 0 3px',
                    }}>
                      {stat.value}
                    </p>
                    <p style={{
                      fontSize: 10, fontFamily: 'Inter',
                      color: 'rgba(255,255,255,0.35)', margin: 0,
                    }}>
                      {stat.label}
                    </p>
                  </div>
                ))}
              </div>

              {/* City predictions table */}
              <div style={{
                background: '#111', borderRadius: 10,
                overflow: 'hidden', marginBottom: 14,
              }}>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 0.8fr 0.8fr 0.8fr 0.8fr',
                  padding: '8px 14px',
                  fontSize: 9, fontWeight: 700,
                  fontFamily: 'Inter',
                  color: 'rgba(255,255,255,0.3)',
                  textTransform: 'uppercase',
                  letterSpacing: '1.5px',
                  borderBottom: '1px solid rgba(255,255,255,0.06)',
                }}>
                  {['City', 'Flood Risk', 'Expected Claims', 'Expected Payout', 'Risk Level'].map(h => (
                    <span key={h}>{h}</span>
                  ))}
                </div>
                {predictions.city_predictions.map((city, i) => (
                  <div key={city.city} style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 0.8fr 0.8fr 0.8fr 0.8fr',
                    padding: '10px 14px', alignItems: 'center',
                    borderBottom: i < predictions.city_predictions.length - 1
                      ? '1px solid rgba(255,255,255,0.04)' : 'none',
                  }}>
                    <span style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'white' }}>
                      {city.city}
                    </span>
                    <span style={{
                      fontSize: 13, fontWeight: 700, fontFamily: 'Inter',
                      color: city.flood_probability > 0.65 ? '#F04438'
                        : city.flood_probability > 0.35 ? '#F79009' : '#12B76A',
                    }}>
                      {Math.round(city.flood_probability * 100)}%
                    </span>
                    <span style={{ fontSize: 13, fontFamily: 'Inter', color: 'rgba(255,255,255,0.6)' }}>
                      ~{city.expected_claims}
                    </span>
                    <span style={{ fontSize: 13, fontFamily: 'Inter', color: 'rgba(255,255,255,0.6)' }}>
                      ₹{(city.expected_payout/1000).toFixed(1)}K
                    </span>
                    <span style={{
                      fontSize: 10, fontWeight: 700, fontFamily: 'Inter',
                      color: city.risk_level === 'HIGH' ? '#F04438'
                        : city.risk_level === 'MEDIUM' ? '#F79009' : '#12B76A',
                      background: city.risk_level === 'HIGH' ? 'rgba(240,68,56,0.1)'
                        : city.risk_level === 'MEDIUM' ? 'rgba(247,144,9,0.1)'
                        : 'rgba(18,183,106,0.1)',
                      padding: '2px 8px', borderRadius: 999,
                    }}>
                      {city.risk_level}
                    </span>
                  </div>
                ))}
              </div>

              {/* Recommendations */}
              {predictions.recommendations.map((rec, i) => (
                <div key={i} style={{
                  display: 'flex', gap: 10,
                  padding: '10px 12px',
                  background: rec.severity === 'HIGH' ? 'rgba(240,68,56,0.08)'
                    : rec.severity === 'MEDIUM' ? 'rgba(247,144,9,0.08)'
                    : 'rgba(46,144,250,0.08)',
                  border: `1px solid ${rec.severity === 'HIGH' ? 'rgba(240,68,56,0.2)'
                    : rec.severity === 'MEDIUM' ? 'rgba(247,144,9,0.2)'
                    : 'rgba(46,144,250,0.2)'}`,
                  borderRadius: 8,
                  marginBottom: i < predictions.recommendations.length - 1 ? 8 : 0,
                }}>
                  <span style={{ fontSize: 16 }}>
                    {rec.severity === 'HIGH' ? '🚨' : rec.severity === 'MEDIUM' ? '⚠️' : 'ℹ️'}
                  </span>
                  <div>
                    <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter', color: 'white', margin: '0 0 2px' }}>
                      {rec.action}
                    </p>
                    <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'rgba(255,255,255,0.4)', margin: 0 }}>
                      {rec.detail}
                    </p>
                  </div>
                </div>
              ))}
            </>
          )}

          {predLoading && !predictions && (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <p style={{ color: 'rgba(255,255,255,0.3)', fontFamily: 'Inter', fontSize: 13 }}>
                Loading predictions...
              </p>
            </div>
          )}
        </div>

        {/* Revenue vs Payouts chart */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 16,
          padding: 20,
          marginBottom: 16,
          border: '1px solid var(--border)',
        }}>
          <p style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 15, fontWeight: 700,
            color: 'var(--text-primary)',
            margin: '0 0 16px',
          }}>
            Premium vs Payouts
          </p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={data.weekly_revenue}>
              <XAxis dataKey="week" tick={{
                fontSize: 11, fontFamily: 'Inter',
                fill: 'var(--text-tertiary)',
              }}/>
              <Tooltip
                contentStyle={{
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 8,
                  fontFamily: 'Inter',
                  fontSize: 12,
                }}
                formatter={(v) => `₹${v.toLocaleString()}`}
              />
              <Bar dataKey="premium" fill="#D97757"
                radius={[4,4,0,0]} name="Premium"/>
              <Bar dataKey="payouts" fill="#2E90FA"
                radius={[4,4,0,0]} name="Payouts"/>
            </BarChart>
          </ResponsiveContainer>
          <div style={{
            display: 'flex',
            gap: 16,
            justifyContent: 'center',
            marginTop: 8,
          }}>
            {[
              { color: '#D97757', label: 'Premium collected' },
              { color: '#2E90FA', label: 'Payouts made' },
            ].map(l => (
              <div key={l.label} style={{
                display: 'flex',
                alignItems: 'center', gap: 5,
              }}>
                <div style={{
                  width: 8, height: 8,
                  borderRadius: 2,
                  background: l.color,
                }}/>
                <span style={{
                  fontSize: 11, fontFamily: 'Inter',
                  color: 'var(--text-tertiary)',
                }}>
                  {l.label}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Trigger breakdown + Fraud stats */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 12,
          marginBottom: 16,
        }}>
          {/* Trigger pie */}
          <div style={{
            background: 'var(--bg-card)',
            borderRadius: 16,
            padding: 16,
            border: '1px solid var(--border)',
          }}>
            <p style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 13, fontWeight: 700,
              color: 'var(--text-primary)',
              margin: '0 0 12px',
            }}>
              Claims by Trigger
            </p>
            <ResponsiveContainer width="100%" height={120}>
              <PieChart>
                <Pie
                  data={data.trigger_breakdown}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={50}
                  innerRadius={30}
                >
                  {data.trigger_breakdown.map((e, i) => (
                    <Cell key={i} fill={e.color}/>
                  ))}
                </Pie>
                <Tooltip
                  formatter={(v) => `${v}%`}
                  contentStyle={{
                    fontSize: 11,
                    fontFamily: 'Inter',
                    background: 'var(--bg-card)',
                    border: '1px solid var(--border)',
                    borderRadius: 8,
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            {data.trigger_breakdown.map(t => (
              <div key={t.name} style={{
                display: 'flex',
                justifyContent: 'space-between',
              }}>
                <div style={{
                  display: 'flex',
                  alignItems: 'center', gap: 5,
                }}>
                  <div style={{
                    width: 6, height: 6,
                    borderRadius: 999, background: t.color,
                  }}/>
                  <span style={{
                    fontSize: 11, fontFamily: 'Inter',
                    color: 'var(--text-secondary)',
                  }}>
                    {t.name}
                  </span>
                </div>
                <span style={{
                  fontSize: 11, fontWeight: 700,
                  fontFamily: 'Inter',
                  color: 'var(--text-primary)',
                }}>
                  {t.value}%
                </span>
              </div>
            ))}
          </div>

          {/* Fraud stats */}
          <div style={{
            background: 'var(--bg-card)',
            borderRadius: 16,
            padding: 16,
            border: '1px solid var(--border)',
          }}>
            <p style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 13, fontWeight: 700,
              color: 'var(--text-primary)',
              margin: '0 0 12px',
            }}>
              Fraud Prevention
            </p>
            {[
              { label: 'Auto-approved',
                value: data.fraud_stats.auto_approved,
                color: '#12B76A' },
              { label: 'Manual review',
                value: data.fraud_stats.manual_review,
                color: '#F79009' },
              { label: 'Rejected',
                value: data.fraud_stats.rejected,
                color: '#F04438' },
            ].map(stat => (
              <div key={stat.label} style={{
                display: 'flex',
                justifyContent: 'space-between',
                marginBottom: 8,
              }}>
                <span style={{
                  fontSize: 12, fontFamily: 'Inter',
                  color: 'var(--text-secondary)',
                }}>
                  {stat.label}
                </span>
                <span style={{
                  fontSize: 12, fontWeight: 700,
                  fontFamily: 'Inter', color: stat.color,
                }}>
                  {stat.value}
                </span>
              </div>
            ))}
            <div style={{
              marginTop: 10,
              padding: '8px 10px',
              background: 'rgba(18,183,106,0.08)',
              borderRadius: 8,
            }}>
              <p style={{
                fontSize: 11, fontWeight: 700,
                fontFamily: 'Inter', color: '#12B76A',
                margin: 0,
              }}>
                💰 ₹{data.fraud_stats.money_saved.toLocaleString()} saved
              </p>
              <p style={{
                fontSize: 10, fontFamily: 'Inter',
                color: 'var(--text-tertiary)', margin: 0,
              }}>
                Fraud prevention this week
              </p>
            </div>
          </div>
        </div>

        {/* Zone exposure table */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 16,
          border: '1px solid var(--border)',
          overflow: 'hidden',
          marginBottom: 16,
        }}>
          <div style={{ padding: '16px 20px 12px' }}>
            <p style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 15, fontWeight: 700,
              color: 'var(--text-primary)', margin: 0,
            }}>
              Zone Exposure
            </p>
          </div>
          <div style={{ overflowX: 'auto' }}>
            <table style={{
              width: '100%',
              borderCollapse: 'collapse',
              fontSize: 12,
              fontFamily: 'Inter',
            }}>
              <thead>
                <tr style={{
                  background: 'var(--bg-secondary)',
                }}>
                  {['Zone', 'Workers', 'Exposure',
                    'Risk'].map(h => (
                    <th key={h} style={{
                      padding: '8px 16px',
                      textAlign: 'left',
                      fontSize: 10,
                      fontWeight: 700,
                      color: 'var(--text-tertiary)',
                      letterSpacing: '1px',
                      textTransform: 'uppercase',
                    }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.zone_exposure.map((row, i) => (
                  <tr key={i} style={{
                    borderTop: '1px solid var(--border-light)',
                  }}>
                    <td style={{ padding: '12px 16px',
                      color: 'var(--text-primary)',
                      fontWeight: 600 }}>
                      {row.zone}
                    </td>
                    <td style={{ padding: '12px 16px',
                      color: 'var(--text-secondary)' }}>
                      {row.workers}
                    </td>
                    <td style={{ padding: '12px 16px',
                      color: 'var(--text-secondary)' }}>
                      ₹{row.exposure.toLocaleString()}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{
                        fontSize: 10, fontWeight: 700,
                        padding: '3px 8px',
                        borderRadius: 999,
                        background: row.risk === 'HIGH'
                          ? 'rgba(240,68,56,0.1)'
                          : row.risk === 'MEDIUM'
                          ? 'rgba(247,144,9,0.1)'
                          : 'rgba(18,183,106,0.1)',
                        color: row.risk === 'HIGH'
                          ? '#F04438'
                          : row.risk === 'MEDIUM'
                          ? '#F79009' : '#12B76A',
                      }}>
                        {row.risk}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Loss Ratio Trend */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 16,
          padding: 20,
          marginBottom: 16,
          border: '1px solid var(--border)',
        }}>
          <p style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 15, fontWeight: 700,
            color: 'var(--text-primary)',
            margin: '0 0 16px',
          }}>
            Loss Ratio Trend
          </p>
          <ResponsiveContainer width="100%" height={140}>
            <LineChart data={data.loss_ratio_trend}>
              <XAxis dataKey="month" tick={{
                fontSize: 11, fontFamily: 'Inter',
                fill: 'var(--text-tertiary)',
              }}/>
              <YAxis tick={{
                fontSize: 11, fontFamily: 'Inter',
                fill: 'var(--text-tertiary)',
              }} domain={[0, 40]}/>
              <Tooltip
                contentStyle={{
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 8,
                  fontFamily: 'Inter',
                  fontSize: 12,
                }}
                formatter={(v) => `${v}%`}
              />
              <Line
                type="monotone"
                dataKey="ratio"
                stroke="#12B76A"
                strokeWidth={2}
                dot={{ fill: '#12B76A', r: 4 }}
                name="Loss Ratio"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

      </div>
    </div>
  )
}

export default InsurerDashboard
