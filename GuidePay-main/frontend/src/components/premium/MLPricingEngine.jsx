import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Brain, Info, Zap } from 'lucide-react'
import { getMyPremiumBreakdown, getZonePremiumCompare, USE_MOCK } from '../../services/api'
import { useWorkerStore } from '../../store/workerStore'

const FALLBACK_ZONES = [
  { zone: 'kondapur-hyderabad', city: 'Hyderabad', premium: 58, risk_level: 'HIGH' },
  { zone: 'kurla-mumbai', city: 'Mumbai', premium: 67, risk_level: 'HIGH' },
  { zone: 'tnagar-chennai', city: 'Chennai', premium: 54, risk_level: 'MEDIUM' },
  { zone: 'koramangala-bengaluru', city: 'Bengaluru', premium: 43, risk_level: 'LOW' },
  { zone: 'dwarka-delhi', city: 'Delhi', premium: 48, risk_level: 'LOW' },
]

const FACTOR_LABELS = {
  flood_history: 'Flood History',
  waterlogging: 'Waterlogging',
  elevation_risk: 'Elevation Risk',
  drainage_quality: 'Drainage Risk',
  monsoon_season: 'Monsoon Intensity',
  platform_outage: 'Outage Risk',
  curfew_risk: 'Curfew Risk',
}

const FACTOR_DESCRIPTIONS = {
  flood_history: 'Historical flood event frequency in this zone.',
  waterlogging: 'Observed waterlogging frequency over recent years.',
  elevation_risk: 'Lower-lying zones carry higher flood exposure.',
  drainage_quality: 'Poorer drainage pushes the premium higher.',
  monsoon_season: 'Current seasonal flood intensity.',
  platform_outage: 'Relative delivery platform outage exposure in this city.',
  curfew_risk: 'Relative operational disruption risk from restrictions.',
}

const zoneColor = (risk) => (risk === 'HIGH' ? '#F04438' : risk === 'MEDIUM' ? '#F79009' : '#12B76A')

export const MLPricingEngine = ({ compact = false, onPremiumCalculated = null }) => {
  const worker = useWorkerStore((s) => s.worker)
  const [zones, setZones] = useState(FALLBACK_ZONES)
  const [currentZone, setCurrentZone] = useState(worker?.zone || FALLBACK_ZONES[0].zone)
  const [breakdown, setBreakdown] = useState(null)
  const [loading, setLoading] = useState(false)
  const [showFactors, setShowFactors] = useState(false)
  const [activeTooltip, setActiveTooltip] = useState(null)

  useEffect(() => {
    setCurrentZone(worker?.zone || FALLBACK_ZONES[0].zone)
  }, [worker?.zone])

  useEffect(() => {
    const loadZones = async () => {
      if (USE_MOCK) return
      try {
        const data = await getZonePremiumCompare()
        if (data?.zones?.length) {
          setZones(data.zones)
        }
      } catch {}
    }
    loadZones()
  }, [])

  useEffect(() => {
    const loadBreakdown = async () => {
      if (!currentZone) return
      setLoading(true)
      try {
        if (USE_MOCK) {
          const fallback = zones.find((zone) => zone.zone === currentZone) || FALLBACK_ZONES[0]
          const premium = fallback.premium || 58
          const localBreakdown = {
            final_premium: premium,
            base_premium: 49,
            zone_adjustment: premium - 49,
            worker_adjustment: worker?.risk_score > 0.8 ? -7 : worker?.risk_score > 0.65 ? -3 : 0,
            coverage_cap: 600,
            model_used: 'mock_mode',
            factors: {
              flood_history: 0.5,
              waterlogging: 0.4,
              elevation_risk: 0.3,
              drainage_quality: 0.3,
              monsoon_season: 0.5,
            },
            city: fallback.city,
            zone: currentZone,
          }
          setBreakdown(localBreakdown)
          onPremiumCalculated?.(localBreakdown.final_premium, localBreakdown)
          return
        }

        const data = await getMyPremiumBreakdown(currentZone)
        setBreakdown(data)
        onPremiumCalculated?.(data.final_premium, data)
      } catch {
        setBreakdown(null)
      } finally {
        setLoading(false)
      }
    }
    loadBreakdown()
  }, [currentZone, onPremiumCalculated, worker?.risk_score, zones])

  const currentZoneMeta = zones.find((zone) => zone.zone === currentZone) || FALLBACK_ZONES[0]
  const finalPremium = breakdown?.final_premium ?? currentZoneMeta?.premium ?? 58
  const basePremium = breakdown?.base_premium ?? 49
  const zoneAdjustment = breakdown?.zone_adjustment ?? finalPremium - basePremium
  const workerAdjustment = breakdown?.worker_adjustment ?? 0
  const riskLabel = currentZoneMeta?.risk_level || (breakdown?.zone_risk_score > 0.6 ? 'HIGH' : breakdown?.zone_risk_score > 0.35 ? 'MEDIUM' : 'LOW')
  const factors = breakdown?.factors || {}

  const factorEntries = Object.entries(factors)

  if (compact) {
    return (
      <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 14, padding: '14px 16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
            <Brain size={15} color="#D97757" />
            <span style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)' }}>
              AI-Calculated Premium
            </span>
          </div>
          <span style={{ fontSize: 10, fontWeight: 700, fontFamily: 'Inter', color: loading ? '#D97757' : '#12B76A', background: loading ? 'rgba(217,119,87,0.1)' : 'rgba(18,183,106,0.1)', padding: '2px 7px', borderRadius: 999 }}>
            {loading ? 'Loading' : 'Live'}
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'baseline', gap: 2, marginBottom: 8 }}>
          <motion.span key={finalPremium} initial={{ scale: 1.15 }} animate={{ scale: 1 }} style={{ fontFamily: 'Bricolage Grotesque', fontSize: 32, fontWeight: 800, letterSpacing: -1 }}>
            Rs{finalPremium}
          </motion.span>
          <span style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-tertiary)' }}>/week</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)' }}>Base rate</span>
            <span style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-secondary)', fontWeight: 600 }}>Rs{basePremium}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)' }}>{breakdown?.city || currentZoneMeta.city} zone risk</span>
            <span style={{ fontSize: 11, fontFamily: 'Inter', color: zoneAdjustment > 0 ? '#F04438' : '#12B76A', fontWeight: 600 }}>
              {zoneAdjustment >= 0 ? '+' : '-'}Rs{Math.abs(zoneAdjustment)}
            </span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)' }}>Worker adjustment</span>
            <span style={{ fontSize: 11, fontFamily: 'Inter', color: workerAdjustment <= 0 ? '#12B76A' : '#F04438', fontWeight: 600 }}>
              {workerAdjustment >= 0 ? '+' : '-'}Rs{Math.abs(workerAdjustment)}
            </span>
          </div>
        </div>

        <button onClick={() => setShowFactors((value) => !value)} style={{ marginTop: 10, width: '100%', padding: '7px', background: 'var(--bg-secondary)', border: '1px solid var(--border)', borderRadius: 8, cursor: 'pointer', fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', fontWeight: 600 }}>
          {showFactors ? 'Hide' : 'Show'} ML factors
        </button>

        <AnimatePresence>
          {showFactors && (
            <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} style={{ overflow: 'hidden' }}>
              <div style={{ paddingTop: 10, display: 'flex', flexDirection: 'column', gap: 6 }}>
                {factorEntries.map(([key, value]) => (
                  <div key={key}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                      <span style={{ fontSize: 10, fontFamily: 'Inter', color: 'var(--text-tertiary)' }}>{FACTOR_LABELS[key] || key}</span>
                      <span style={{ fontSize: 10, fontFamily: 'Inter', color: value > 0.6 ? '#F04438' : value > 0.3 ? '#F79009' : '#12B76A', fontWeight: 700 }}>
                        {Math.round(value * 100)}%
                      </span>
                    </div>
                    <div style={{ height: 4, background: 'var(--bg-secondary)', borderRadius: 999, overflow: 'hidden' }}>
                      <motion.div initial={{ width: 0 }} animate={{ width: `${value * 100}%` }} transition={{ duration: 0.45 }} style={{ height: '100%', background: value > 0.6 ? '#F04438' : value > 0.3 ? '#F79009' : '#12B76A' }} />
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    )
  }

  return (
    <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 18, overflow: 'hidden' }}>
      <div style={{ background: 'linear-gradient(135deg, rgba(217,119,87,0.08), rgba(217,119,87,0.02))', borderBottom: '1px solid var(--border-light)', padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(217,119,87,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Brain size={18} color="#D97757" />
          </div>
          <div>
            <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>ML Premium Engine</p>
            <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: 0 }}>
              {breakdown?.model_used || 'live_backend'} · hyper-local pricing
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, background: loading ? 'rgba(217,119,87,0.08)' : 'rgba(18,183,106,0.08)', border: loading ? '1px solid rgba(217,119,87,0.2)' : '1px solid rgba(18,183,106,0.2)', borderRadius: 999, padding: '5px 12px' }}>
          <div style={{ width: 6, height: 6, borderRadius: 999, background: loading ? '#D97757' : '#12B76A' }} />
          <span style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: loading ? '#D97757' : '#12B76A' }}>
            {loading ? 'Calculating' : 'Price ready'}
          </span>
        </div>
      </div>

      <div style={{ padding: 20 }}>
        <div style={{ marginBottom: 20 }}>
          <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '1.5px', textTransform: 'uppercase', margin: '0 0 8px' }}>
            Calculate for zone
          </p>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(100px, 1fr))', gap: 6 }}>
            {zones.map((zone) => (
              <motion.button key={zone.zone} onClick={() => setCurrentZone(zone.zone)} whileTap={{ scale: 0.96 }} style={{ padding: '8px 10px', borderRadius: 8, border: currentZone === zone.zone ? '1.5px solid var(--brand)' : '1.5px solid var(--border)', background: currentZone === zone.zone ? 'var(--brand-light)' : 'var(--bg-secondary)', cursor: 'pointer', textAlign: 'center' }}>
                <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter', color: currentZone === zone.zone ? 'var(--brand)' : 'var(--text-secondary)', margin: '0 0 2px' }}>{zone.city}</p>
                <p style={{ fontSize: 10, fontFamily: 'Inter', color: zoneColor(zone.risk_level), margin: 0, fontWeight: 600 }}>{zone.risk_level}</p>
              </motion.button>
            ))}
          </div>
        </div>

        <div style={{ background: 'var(--bg-secondary)', borderRadius: 14, padding: '18px 20px', marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: '0 0 4px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px' }}>Your premium</p>
            <motion.p key={`${currentZone}-${finalPremium}`} initial={{ scale: 1.1 }} animate={{ scale: 1 }} style={{ fontFamily: 'Bricolage Grotesque', fontSize: 44, fontWeight: 800, margin: 0, letterSpacing: -2, lineHeight: 1 }}>
              Rs{loading ? '...' : finalPremium}
            </motion.p>
            <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: '4px 0 0' }}>per week · Rs{breakdown?.coverage_cap || 600} coverage</p>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ background: `${zoneColor(riskLabel)}18`, border: `1px solid ${zoneColor(riskLabel)}30`, borderRadius: 10, padding: '8px 14px', marginBottom: 8 }}>
              <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: zoneColor(riskLabel), margin: 0 }}>{riskLabel} RISK ZONE</p>
            </div>
            <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: 0 }}>{breakdown?.city || currentZoneMeta.city}</p>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
          {[
            { label: 'Base premium', value: `Rs${basePremium}` },
            { label: `${breakdown?.city || currentZoneMeta.city} zone risk`, value: `${zoneAdjustment >= 0 ? '+' : '-'}Rs${Math.abs(zoneAdjustment)}` },
            { label: 'Worker trust score', value: `${workerAdjustment >= 0 ? '+' : '-'}Rs${Math.abs(workerAdjustment)}` },
          ].map((row) => (
            <div key={row.label} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px', background: 'var(--bg-secondary)', borderRadius: 10 }}>
              <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-primary)', margin: 0 }}>{row.label}</p>
              <span style={{ fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: 800, color: 'var(--text-primary)' }}>{row.value}</span>
            </div>
          ))}
        </div>

        <button onClick={() => setShowFactors((value) => !value)} style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px', background: 'var(--bg-secondary)', border: '1px solid var(--border)', borderRadius: 10, cursor: 'pointer', marginBottom: showFactors ? 10 : 0 }}>
          <span style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: 6 }}>
            <Zap size={13} color="#D97757" />
            View ML factors
          </span>
          <span style={{ fontSize: 11, color: 'var(--text-tertiary)' }}>{showFactors ? 'Hide' : 'Show'}</span>
        </button>

        <AnimatePresence>
          {showFactors && (
            <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} style={{ overflow: 'hidden' }}>
              <div style={{ background: 'var(--bg-secondary)', borderRadius: 10, padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 10 }}>
                {factorEntries.map(([key, value]) => (
                  <div key={key}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)', fontWeight: 500 }}>{FACTOR_LABELS[key] || key}</span>
                        <div onMouseEnter={() => setActiveTooltip(key)} onMouseLeave={() => setActiveTooltip(null)} style={{ cursor: 'help', position: 'relative' }}>
                          <Info size={11} color="var(--text-tertiary)" />
                          {activeTooltip === key && (
                            <div style={{ position: 'absolute', bottom: 20, left: 0, width: 180, background: 'var(--text-primary)', color: 'var(--bg-card)', fontSize: 11, fontFamily: 'Inter', padding: '8px 10px', borderRadius: 8, zIndex: 100, lineHeight: 1.5 }}>
                              {FACTOR_DESCRIPTIONS[key] || 'Premium input factor.'}
                            </div>
                          )}
                        </div>
                      </div>
                      <span style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter', color: value > 0.6 ? '#F04438' : value > 0.3 ? '#F79009' : '#12B76A' }}>{Math.round(value * 100)}%</span>
                    </div>
                    <div style={{ height: 5, background: 'var(--border)', borderRadius: 999, overflow: 'hidden' }}>
                      <motion.div initial={{ width: 0 }} animate={{ width: `${value * 100}%` }} transition={{ duration: 0.4 }} style={{ height: '100%', background: value > 0.6 ? '#F04438' : value > 0.3 ? '#F79009' : '#12B76A' }} />
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}

export default MLPricingEngine
