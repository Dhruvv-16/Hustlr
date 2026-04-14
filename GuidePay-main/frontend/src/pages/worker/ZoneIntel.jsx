import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, AlertTriangle, Shield, CloudRain, Wifi, MapPin, Info, CheckCircle2 } from 'lucide-react'
import { useWorkerStore } from '../../store/workerStore'
import { getZoneIntel } from '../../services/api'
import ChatWidget from '../../components/chat/ChatWidget'
import BottomNav from '../../components/ui/BottomNav'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const riskColor = (val) => val > 0.6 ? '#F04438' : val >= 0.3 ? '#F79009' : '#12B76A'
const riskLabel = (val) => val > 0.6 ? 'HIGH' : val >= 0.3 ? 'MEDIUM' : 'LOW'

const ZONE_DISPLAY = {
  'kondapur-hyderabad': 'Kondapur, Hyderabad',
  'kurla-mumbai': 'Kurla, Mumbai',
  'tnagar-chennai': 'T.Nagar, Chennai',
  'koramangala-bengaluru': 'Koramangala, Bengaluru',
  'dwarka-delhi': 'Dwarka, Delhi',
}

export default function ZoneIntel() {
  const navigate = useNavigate()
  const worker = useWorkerStore(s => s.worker)
  const zone = worker?.zone || 'kondapur-hyderabad'
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await getZoneIntel(zone)
        if (!res?.error) setData(res)
      } catch (e) {
        console.warn('[ZoneIntel] API failed:', e.message)
      }
      setLoading(false)
    }
    fetch()
  }, [zone])

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
          <p style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading zone intel...</p>
        </div>
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    )
  }

  const safetyScore = data?.safety_score ?? 50
  const floodRisk = data?.flood_risk ?? 0.5
  const outageRisk = data?.outage_risk ?? 0.3
  const curfewRisk = data?.curfew_risk ?? 0.2
  const prediction = data?.prediction || {}
  const recommendations = data?.recommendations || []
  const activeTriggers = data?.active_triggers || []
  const workersInZone = data?.workers_in_zone ?? 0
  const displayName = ZONE_DISPLAY[zone] || data?.city || zone

  const safetyColor = safetyScore >= 70 ? '#12B76A' : safetyScore >= 40 ? '#F79009' : '#F04438'

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
        background: `linear-gradient(135deg, ${safetyColor}15, ${safetyColor}05)`,
        padding: '16px 16px 24px',
        borderBottom: `3px solid ${safetyColor}`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
          <button
            onClick={() => navigate(-1)}
            style={{
              background: 'var(--bg-card)',
              border: '1px solid var(--border-light)',
              borderRadius: 999,
              width: 36, height: 36,
              cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            <ArrowLeft size={18} color="var(--text-primary)" />
          </button>
          <div>
            <h1 style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 20, fontWeight: 800,
              color: 'var(--text-primary)', margin: 0,
            }}>
              Zone Intel
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
              <MapPin size={12} color="var(--text-secondary)" />
              <span style={{ fontSize: 12, color: 'var(--text-secondary)', fontFamily: 'Inter' }}>
                {displayName}
              </span>
            </div>
          </div>
        </div>

        {/* Safety Score Ring */}
        <div style={{ textAlign: 'center' }}>
          <div style={{ position: 'relative', width: 120, height: 120, margin: '0 auto' }}>
            <svg width="120" height="120" viewBox="0 0 120 120">
              <circle cx="60" cy="60" r="52" fill="none" stroke="var(--border-light)" strokeWidth="8" />
              <motion.circle
                cx="60" cy="60" r="52"
                fill="none"
                stroke={safetyColor}
                strokeWidth="8"
                strokeLinecap="round"
                strokeDasharray={`${2 * Math.PI * 52}`}
                initial={{ strokeDashoffset: 2 * Math.PI * 52 }}
                animate={{ strokeDashoffset: 2 * Math.PI * 52 * (1 - safetyScore / 100) }}
                transition={{ delay: 0.3, duration: 1, ease: 'easeOut' }}
                transform="rotate(-90 60 60)"
              />
            </svg>
            <div style={{
              position: 'absolute', inset: 0,
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
            }}>
              <span style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 32, fontWeight: 800,
                color: safetyColor,
              }}>
                {Math.round(safetyScore)}
              </span>
              <span style={{ fontSize: 10, color: 'var(--text-tertiary)', fontFamily: 'Inter', fontWeight: 600 }}>
                SAFETY
              </span>
            </div>
          </div>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', fontFamily: 'Inter', marginTop: 8 }}>
            {workersInZone} workers in this zone
          </p>
        </div>
      </div>

      <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* Risk breakdown */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 14,
          padding: 16,
          border: '1px solid var(--border-light)',
        }}>
          <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 12px' }}>
            Risk Breakdown
          </p>
          {[
            { icon: CloudRain, label: 'Flood Risk', value: floodRisk, color: riskColor(floodRisk) },
            { icon: Wifi, label: 'Outage Risk', value: outageRisk, color: riskColor(outageRisk) },
            { icon: Shield, label: 'Curfew Risk', value: curfewRisk, color: riskColor(curfewRisk) },
          ].map(risk => {
            const Icon = risk.icon
            return (
              <div key={risk.label} style={{ marginBottom: 10 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <Icon size={14} color={risk.color} />
                    <span style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-primary)' }}>
                      {risk.label}
                    </span>
                  </div>
                  <span style={{
                    fontSize: 10, fontWeight: 700, fontFamily: 'Inter',
                    color: risk.color, background: `${risk.color}15`,
                    padding: '2px 8px', borderRadius: 999,
                  }}>
                    {riskLabel(risk.value)}
                  </span>
                </div>
                <div style={{ height: 6, background: 'var(--bg-tertiary)', borderRadius: 999, overflow: 'hidden' }}>
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${risk.value * 100}%` }}
                    transition={{ delay: 0.4, type: 'spring', stiffness: 80 }}
                    style={{ height: '100%', background: risk.color, borderRadius: 999 }}
                  />
                </div>
              </div>
            )
          })}
        </div>

        {/* AI Prediction */}
        {prediction.probability != null && (
          <div style={{
            background: 'var(--bg-card)',
            borderRadius: 14,
            padding: 16,
            border: '1px solid var(--border-light)',
          }}>
            <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 10px' }}>
              🧠 AI Prediction — Next 24h
            </p>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 13, color: 'var(--text-secondary)', fontFamily: 'Inter' }}>Flood probability</span>
              <span style={{
                fontFamily: 'Bricolage Grotesque', fontSize: 24, fontWeight: 800,
                color: riskColor(prediction.probability),
              }}>
                {Math.round(prediction.probability * 100)}%
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
              <span style={{ fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>
                Rainfall: {prediction.rainfall_mm || 0}mm
              </span>
              <span style={{ fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>
                Monsoon: {prediction.inputs?.monsoon_intensity || 0}
              </span>
            </div>
          </div>
        )}

        {/* Active triggers */}
        {activeTriggers.length > 0 && (
          <div style={{
            background: '#FEF3F2',
            borderRadius: 14,
            padding: 16,
            border: '1px solid #FECDCA',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <AlertTriangle size={16} color="#F04438" />
              <span style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: '#F04438' }}>
                Active Alerts ({activeTriggers.length})
              </span>
            </div>
            {activeTriggers.map((t, i) => (
              <div key={t.id || i} style={{
                padding: '8px 0',
                borderTop: i > 0 ? '1px solid #FECDCA' : 'none',
              }}>
                <p style={{ fontSize: 13, fontWeight: 600, color: '#B42318', fontFamily: 'Inter', margin: 0 }}>
                  {t.trigger_type} — {t.severity}
                </p>
                <p style={{ fontSize: 12, color: '#D92D20', fontFamily: 'Inter', margin: '2px 0 0' }}>
                  {t.affected_workers || 0} workers affected
                </p>
              </div>
            ))}
          </div>
        )}

        {/* Recommendations */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 14,
          padding: 16,
          border: '1px solid var(--border-light)',
        }}>
          <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 12px' }}>
            Safety Recommendations
          </p>
          {recommendations.map((rec, i) => {
            const iconMap = {
              warning: AlertTriangle,
              urgent: AlertTriangle,
              info: Info,
              success: CheckCircle2,
            }
            const colorMap = {
              warning: '#F79009',
              urgent: '#F04438',
              info: '#2E90FA',
              success: '#12B76A',
            }
            const Icon = iconMap[rec.type] || Info
            const color = colorMap[rec.type] || '#6B6B6B'
            return (
              <div key={i} style={{
                display: 'flex', gap: 10, alignItems: 'flex-start',
                padding: '10px 0',
                borderTop: i > 0 ? '1px solid var(--border-light)' : 'none',
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 8,
                  background: `${color}15`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, marginTop: 2,
                }}>
                  <Icon size={14} color={color} />
                </div>
                <div>
                  <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 2px' }}>
                    {rec.title}
                  </p>
                  <p style={{ fontSize: 12, color: 'var(--text-secondary)', fontFamily: 'Inter', lineHeight: 1.5, margin: 0 }}>
                    {rec.description}
                  </p>
                </div>
              </div>
            )
          })}
        </div>

        {/* Zone stats */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr',
          gap: 8,
        }}>
          {[
            { label: 'Claims (30d)', value: String(data?.recent_claims_30d ?? 0) },
            { label: 'Total Triggers', value: String(data?.historical_trigger_events ?? 0) },
          ].map(stat => (
            <div key={stat.label} style={{
              background: 'var(--bg-card)',
              borderRadius: 12, padding: 14,
              border: '1px solid var(--border-light)',
              textAlign: 'center',
            }}>
              <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 24, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                {stat.value}
              </p>
              <p style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px', margin: '2px 0 0' }}>
                {stat.label}
              </p>
            </div>
          ))}
        </div>
      </div>

      <ChatWidget />
      <BottomNav />
    </motion.div>
  )
}
