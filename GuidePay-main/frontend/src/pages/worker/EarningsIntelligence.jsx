import { useEffect, useMemo, useState } from 'react'
import { AlertTriangle, ArrowRight, BarChart3 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

import { getEarningsIntelligence } from '../../services/api'

const planPrices = {
  basic: 49,
  standard: 62,
  premium: 89,
}

const tierStyles = {
  bronze: { label: 'Bronze', bg: '#FFF7ED', color: '#C2410C' },
  silver: { label: 'Silver', bg: '#F3F4F6', color: '#4B5563' },
  gold: { label: 'Gold', bg: '#FEF3C7', color: '#B45309' },
}

export default function EarningsIntelligence() {
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const loadData = async () => {
      setLoading(true)
      try {
        const response = await getEarningsIntelligence()
        setData(response)
        setError('')
      } catch (err) {
        console.error('[EarningsIntelligence] load failed', err)
        setError('Could not load earnings intelligence right now.')
      } finally {
        setLoading(false)
      }
    }

    loadData()
  }, [])

  const tierStyle = useMemo(() => tierStyles[data?.income_tier] || tierStyles.silver, [data])
  const overlapHigh = (data?.risk_overlap_pct || 0) > 50
  const peakHours = data?.peak_earning_hours || []

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-secondary)', padding: '16px 16px 120px' }}>
      <div style={{ background: 'var(--bg-card)', borderRadius: 18, padding: 20, border: '1px solid var(--border-light)', marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
          <div>
            <h1 style={{ margin: 0, fontFamily: 'Bricolage Grotesque', fontSize: 24, fontWeight: 800, color: 'var(--text-primary)' }}>
              Earnings Intelligence
            </h1>
            <p style={{ margin: '6px 0 0', fontSize: 13, color: 'var(--text-secondary)', fontFamily: 'Inter' }}>
              Personalized risk analysis based on your delivery activity
            </p>
          </div>
          <span style={{ padding: '8px 12px', borderRadius: 999, background: tierStyle.bg, color: tierStyle.color, fontSize: 12, fontWeight: 700, fontFamily: 'Inter' }}>
            {tierStyle.label}
          </span>
        </div>
      </div>

      {error && (
        <div style={{ marginBottom: 16, padding: '12px 14px', background: '#FEF2F2', color: '#B42318', borderRadius: 14, border: '1px solid #FECACA', fontFamily: 'Inter', fontSize: 13 }}>
          {error}
        </div>
      )}

      <div style={{ background: 'var(--bg-card)', borderRadius: 18, padding: 18, border: '1px solid var(--border-light)', marginBottom: 16 }}>
        <p style={{ margin: '0 0 12px', fontSize: 16, fontWeight: 700, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)' }}>
          Your Peak Earning Hours
        </p>
        {loading ? (
          <p style={{ margin: 0, fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading peak-hour analysis...</p>
        ) : (
          peakHours.map((slot) => (
            <div key={slot.label} style={{ marginBottom: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginBottom: 6 }}>
                <div>
                  <p style={{ margin: 0, fontSize: 13, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)' }}>{slot.label}</p>
                  <p style={{ margin: '3px 0 0', fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>{slot.hour_range}</p>
                </div>
                <span style={{ fontSize: 13, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)' }}>{slot.avg_orders} orders</span>
              </div>
              <div style={{ height: 10, borderRadius: 999, background: 'var(--border-light)', overflow: 'hidden' }}>
                <div style={{ width: `${Math.min(100, (slot.avg_orders / Math.max(data?.avg_daily_orders || 1, 1)) * 100)}%`, height: '100%', borderRadius: 999, background: 'linear-gradient(90deg, #D97757, #F59E0B)' }} />
              </div>
            </div>
          ))
        )}
      </div>

      <div style={{ background: overlapHigh ? '#FEF2F2' : '#ECFDF3', borderRadius: 18, padding: 18, border: `1px solid ${overlapHigh ? '#FECACA' : '#A7F3D0'}`, marginBottom: 16 }}>
        <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
          {overlapHigh ? <AlertTriangle size={18} color="#DC2626" /> : <BarChart3 size={18} color="#059669" />}
          <div>
            <p style={{ margin: 0, fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: overlapHigh ? '#B91C1C' : '#047857' }}>
              {data?.risk_overlap_message || 'Low overlap between your peak hours and flood risk windows'}
            </p>
            <p style={{ margin: '6px 0 0', fontSize: 12, fontFamily: 'Inter', color: overlapHigh ? '#7F1D1D' : '#065F46' }}>
              {overlapHigh ? 'This means floods are most likely to hit when you earn the most' : 'Low overlap between your peak hours and flood risk windows'}
            </p>
          </div>
        </div>
      </div>

      <div style={{ background: 'var(--bg-card)', borderRadius: 18, padding: 18, border: '1px solid var(--border-light)', marginBottom: 16 }}>
        <p style={{ margin: '0 0 10px', fontSize: 16, fontWeight: 700, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)' }}>
          Is GuidePay Worth It For You?
        </p>
        <p style={{ margin: '0 0 16px', fontSize: 15, lineHeight: 1.5, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-primary)' }}>
          {data?.roi?.message || 'Loading ROI calculation...'}
        </p>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: 10, marginBottom: 14 }}>
          <div style={{ background: 'var(--bg-secondary)', borderRadius: 12, padding: 12 }}>
            <p style={{ margin: 0, fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Annual premium cost</p>
            <p style={{ margin: '6px 0 0', fontSize: 18, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)' }}>₹{data?.roi?.annual_premium_cost ?? 0}</p>
          </div>
          <div style={{ background: 'var(--bg-secondary)', borderRadius: 12, padding: 12 }}>
            <p style={{ margin: 0, fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Expected payout</p>
            <p style={{ margin: '6px 0 0', fontSize: 18, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)' }}>₹{data?.roi?.expected_annual_payout ?? 0}</p>
          </div>
          <div style={{ background: 'var(--bg-secondary)', borderRadius: 12, padding: 12 }}>
            <p style={{ margin: 0, fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Net benefit</p>
            <p style={{ margin: '6px 0 0', fontSize: 18, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: (data?.roi?.net_benefit ?? 0) >= 0 ? '#059669' : '#DC2626' }}>₹{data?.roi?.net_benefit ?? 0}</p>
          </div>
        </div>
        <p style={{ margin: 0, fontSize: 13, fontWeight: 700, fontFamily: 'Inter', color: '#D97757' }}>
          {data?.roi?.ratio ?? 0}x return on your premium
        </p>
      </div>

      <div style={{ background: 'var(--bg-card)', borderRadius: 18, padding: 18, border: '1px solid var(--border-light)' }}>
        <p style={{ margin: '0 0 10px', fontSize: 16, fontWeight: 700, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)' }}>
          Our Recommendation
        </p>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <span style={{ fontSize: 15, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', textTransform: 'capitalize' }}>
            {data?.recommended_plan || 'standard'}
          </span>
          <span style={{ fontSize: 14, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: '#D97757' }}>
            ₹{planPrices[data?.recommended_plan] || 62}/week
          </span>
        </div>
        <p style={{ margin: '0 0 14px', fontSize: 13, lineHeight: 1.5, color: 'var(--text-secondary)', fontFamily: 'Inter' }}>
          {data?.recommendation_reason || 'Loading recommendation...'}
        </p>
        <button
          type="button"
          onClick={() => navigate('/coverage')}
          style={{
            width: '100%',
            border: 'none',
            borderRadius: 12,
            padding: '14px 16px',
            background: 'linear-gradient(135deg, #D97757, #B85C3A)',
            color: 'white',
            fontSize: 15,
            fontWeight: 700,
            fontFamily: 'Inter',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            cursor: 'pointer',
          }}
        >
          Get This Plan <ArrowRight size={16} />
        </button>
      </div>
    </div>
  )
}
