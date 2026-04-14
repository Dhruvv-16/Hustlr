import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Download, LoaderCircle, X, Zap, ShieldCheck, MapPin, Bot, TrendingUp } from 'lucide-react'
import Card from '../../components/ui/Card'
import Badge from '../../components/ui/Badge'
import LiveDot from '../../components/ui/LiveDot'
import ChatWidget from '../../components/chat/ChatWidget'
import { ZoneMonitor } from '../../components/dashboard/ZoneMonitor'
import IncomeTierBadge from '../../components/ui/IncomeTierBadge'
import { useWorkerStore } from '../../store/workerStore'
import { formatINR } from '../../utils/formatters'
import { downloadProtectionCertificate, getMyClaims, getMyProfile, getMyZoneForecast, getWellnessScore } from '../../services/api'
import { useTranslation } from '../../i18n/useTranslation'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const stagger = {
  animate: { transition: { staggerChildren: 0.06 } },
}
const fadeUp = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 400, damping: 30 } },
}

export default function Dashboard() {
  const navigate = useNavigate()
  const worker = useWorkerStore((s) => s.worker)
  const activePolicy = useWorkerStore((s) => s.activePolicy)
  const onboarded = useWorkerStore((s) => s.onboarded)
  const setOnboarded = useWorkerStore((s) => s.setOnboarded)
  const setShowTour = useWorkerStore((s) => s.setShowTour)
  const setWorker = useWorkerStore((s) => s.setWorker)
  const setActivePolicy = useWorkerStore((s) => s.setActivePolicy)
  const { t } = useTranslation()
  const now = new Date()
  const activePolicyId = activePolicy?.policyId || useWorkerStore.getState().activePolicy?.policyId
  const weekStartDate = new Date(now)
  weekStartDate.setDate(now.getDate() - now.getDay() + 1)
  const weekEndDate = new Date(weekStartDate)
  weekEndDate.setDate(weekStartDate.getDate() + 6)

  // Real profile data from API
  const [profileData, setProfileData] = useState(null)
  const [zoneAlert, setZoneAlert] = useState(null)
  const [wellnessData, setWellnessData] = useState(null)
  const [downloadLoading, setDownloadLoading] = useState(false)
  const [toast, setToast] = useState(null)

  // Fetch real data on mount
  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = localStorage.getItem('gp-access-token') || localStorage.getItem('gp-token')
        if (!token) return

        const [profile, claimsRes] = await Promise.all([
          getMyProfile(),
          getMyClaims(null, 5, 0).catch(() => ({ claims: [] })),
        ])

        if (profile) {
          if (!profile.city || !profile.zone) {
            navigate('/complete-profile', { replace: true })
            return
          }
          setProfileData(profile)
          setWorker({
            ...worker,
            name: profile.name,
            phone: profile.phone,
            city: profile.city,
            zone: profile.zone,
            riskScore: profile.risk_score,
            riskTier: profile.risk_tier,
            premium: profile.premium_amount,
            coverageCap: 600,
          })
          if (profile.active_policy) {
            setActivePolicy({
              policyId: profile.active_policy._id || profile.active_policy.id,
              planId: profile.active_policy.plan_id,
              planName: profile.active_policy.plan_name,
              price: profile.active_policy.weekly_premium,
              coverage: profile.active_policy.coverage_cap || 600,
              weekStart: profile.active_policy.week_start,
              weekEnd: profile.active_policy.week_end,
              paymentId: profile.active_policy.payment_id,
              status: profile.active_policy.status,
            })
          }
        }

        if (claimsRes?.claims) {
          setClaims(claimsRes.claims)
          prevClaimCountRef.current = claimsRes.claims.length
        }
      } catch (e) {
        console.warn('[Dashboard] Profile fetch failed, using store data:', e.message)
      }
    }
    fetchData()
  }, [])

  // Fetch zone forecast for real alert data
  useEffect(() => {
    const fetchAlert = async () => {
      try {
        const token = localStorage.getItem('gp-access-token') || localStorage.getItem('gp-token')
        if (!token) return
        const data = await getMyZoneForecast()
        if (data?.prediction) {
          setZoneAlert({
            probability: Math.round(data.prediction.probability * 100),
            zone: data.zone || worker?.zone || 'Your zone',
            autoExtended: data.auto_cover_extended,
          })
        }
      } catch (e) {
        // Silent — alert banner just won't show live data
      }
    }
    fetchAlert()
  }, [])

  // Fetch wellness score
  useEffect(() => {
    const fetchWellness = async () => {
      try {
        const token = localStorage.getItem('gp-access-token') || localStorage.getItem('gp-token')
        if (!token) return
        const data = await getWellnessScore()
        if (data?.score !== undefined) setWellnessData(data)
      } catch (e) {
        // Silent fallback
      }
    }
    fetchWellness()
  }, [])

  useEffect(() => {
    if (!toast) return undefined
    const timer = setTimeout(() => setToast(null), 2600)
    return () => clearTimeout(timer)
  }, [toast])

  const w = {
    name: worker?.name || profileData?.name || 'Delivery Partner',
    riskScore: profileData?.risk_score ?? worker?.riskScore ?? 0.75,
    riskTier: profileData?.risk_tier ?? worker?.riskTier ?? 'MEDIUM',
    premium: profileData?.premium_amount ?? worker?.premium ?? 58,
    coverageCap: 600,
  }

  const apiStats = profileData?.stats || {}
  const totalClaims = apiStats.total_claims ?? 0
  const totalPayouts = apiStats.total_payouts ?? 0

  const [showAlert, setShowAlert] = useState(false)
  const [showWelcome, setShowWelcome] = useState(false)
  const [newClaimAlert, setNewClaimAlert] = useState(null)
  const prevClaimCountRef = useRef(0)
  const claims = useWorkerStore(s => s.claims)
  const setClaims = useWorkerStore(s => s.setClaims)
  const paidClaims = claims.filter((claim) => claim.status === 'PAID')

  // Show alert only when we have real zone data or after timeout
  useEffect(() => {
    if (zoneAlert && zoneAlert.probability > 30) {
      setShowAlert(true)
    } else {
      const timer = setTimeout(() => setShowAlert(false), 100)
      return () => clearTimeout(timer)
    }
  }, [zoneAlert])

  // Show welcome modal for first-time users
  useEffect(() => {
    if (!onboarded) {
      const t = setTimeout(() => setShowWelcome(true), 500)
      return () => clearTimeout(t)
    }
  }, [onboarded])

  useEffect(() => {
    if (showAlert && zoneAlert && Notification.permission === 'granted') {
      new Notification('GuidePay Alert', {
        body: `${zoneAlert.probability}% flood risk tomorrow in ${zoneAlert.zone}. Coverage auto-extended.`,
        icon: '/favicon.ico',
      })
    }
  }, [showAlert])

  useEffect(() => {
    if (!activePolicy) return

    const poll = async () => {
      try {
        const data = await getMyClaims(null, 5, 0)
        if (data?.claims?.length > prevClaimCountRef.current) {
          const newClaim = data.claims[0]
          setNewClaimAlert(newClaim)
          setClaims(data.claims)
          prevClaimCountRef.current = data.claims.length
        }
      } catch (e) {}
    }

    const interval = setInterval(poll, 20000)
    return () => clearInterval(interval)
  }, [activePolicy])

  const greeting = () => {
    const h = new Date().getHours()
    if (h < 12) return 'Good morning'
    if (h < 17) return 'Good afternoon'
    return 'Good evening'
  }

  const firstName = w.name?.split(' ')[0] || 'Partner'

  const policyEndDate = activePolicy?.weekEnd
    ? new Date(activePolicy.weekEnd).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
    : null
  const displayTotalProtected = totalPayouts > 0
    ? totalPayouts
    : paidClaims.reduce((sum, claim) => sum + (claim.amount || 0), 0)

  const riskTierLabel = w.riskTier === 'LOW' ? 'Low' : w.riskTier === 'HIGH' ? 'High' : 'Medium'
  const riskDiscount = w.riskTier === 'LOW' ? '₹7 discount' : w.riskTier === 'HIGH' ? 'Higher premium' : 'Standard rate'

  const stats = [
    {
      label: 'PROTECTED',
      value: displayTotalProtected > 0 ? formatINR(displayTotalProtected) : (activePolicy ? `₹${activePolicy.coverage || 600}` : '₹0'),
      sub: totalClaims > 0 ? `${totalClaims} payout${totalClaims > 1 ? 's' : ''} received` : 'Coverage active',
      valueColor: '#D97757',
    },
    {
      label: 'PREMIUMS PAID',
      value: activePolicy ? `₹${activePolicy.price || w.premium}` : '₹0',
      sub: activePolicy ? 'This week' : 'No active plan',
      valueColor: '#0F0F0F',
    },
    { label: 'RISK SCORE', value: `${w.riskScore}`, sub: `${riskTierLabel} · ${riskDiscount}`, valueColor: '#12B76A' },
    {
      label: 'NEXT RENEWAL',
      value: policyEndDate || 'No coverage',
      sub: activePolicy ? `₹${activePolicy.price || w.premium} due` : 'Buy a plan',
      valueColor: '#0F0F0F',
    },
  ]

  const handleDownloadCertificate = async () => {
    if (!activePolicyId) {
      setToast({ type: 'error', message: 'Could not download certificate. Try again.' })
      return
    }

    setDownloadLoading(true)
    try {
      await downloadProtectionCertificate(activePolicyId)
      setToast({ type: 'success', message: 'Certificate downloaded!' })
    } catch (error) {
      console.error('[Dashboard] certificate download failed', error)
      setToast({ type: 'error', message: 'Could not download certificate. Try again.' })
    } finally {
      setDownloadLoading(false)
    }
  }

  return (
    <motion.div
      className="min-h-screen pb-24"
      style={{ background: 'var(--bg-primary)' }}
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            style={{
              position: 'fixed',
              top: 74,
              left: 16,
              right: 16,
              zIndex: 80,
              margin: '0 auto',
              maxWidth: 420,
              padding: '12px 14px',
              borderRadius: 14,
              color: 'white',
              background: toast.type === 'success' ? '#12B76A' : '#F04438',
              fontSize: 13,
              fontWeight: 700,
              fontFamily: 'Inter',
              boxShadow: '0 14px 30px rgba(15,23,42,0.16)',
            }}
          >
            {toast.message}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="px-4 pt-12 pb-0" style={{ background: 'var(--bg-primary)' }}>
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[13px] font-body" style={{ color: 'var(--text-secondary)' }}>{greeting()} 👋</p>
            <h1 className="font-display font-bold text-[24px] mt-0.5" style={{ color: 'var(--text-primary)' }}>{firstName}</h1>
          </div>
          <div
            className="w-9 h-9 rounded-full bg-brand flex items-center justify-center cursor-pointer"
            onClick={() => navigate('/profile')}
          >
            <span className="font-display font-bold text-[13px] text-white">
              {firstName[0]}{w.name?.split(' ')[1]?.[0] || ''}
            </span>
          </div>
        </div>
      </div>

      <motion.div variants={stagger} animate="animate" className="px-4 mt-3 flex flex-col gap-3">
        {/* Buy coverage CTA */}
        {!activePolicy && (
          <motion.div variants={fadeUp}>
            <div
              className="rounded-card p-5"
              style={{
                background: 'linear-gradient(135deg, #D97757, #B85C3A)',
                boxShadow: '0 8px 32px rgba(217,119,87,0.35)',
              }}
            >
              <div className="flex items-center gap-2 mb-3">
                <span style={{ fontSize: 24 }}>🛡️</span>
                <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: 'rgba(255,255,255,0.8)', letterSpacing: '1.5px', textTransform: 'uppercase', margin: 0 }}>
                  No active coverage
                </p>
              </div>
              <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 26, fontWeight: 800, color: 'white', margin: '0 0 8px', letterSpacing: -0.5 }}>
                Get protected for ₹49/week
              </h2>
              <p style={{ fontSize: 14, color: 'rgba(255,255,255,0.8)', fontFamily: 'Inter, sans-serif', margin: '0 0 18px', lineHeight: 1.5 }}>
                Floods, outages, curfews — auto-paid to your UPI in under 2 hours.
              </p>
              <motion.button
                onClick={() => navigate('/coverage')}
                whileTap={{ scale: 0.97 }}
                style={{
                  width: '100%', padding: '13px', borderRadius: 10, border: 'none',
                  background: 'white', color: '#D97757',
                  fontSize: 15, fontWeight: 700, fontFamily: 'Inter, sans-serif',
                  cursor: 'pointer',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                }}
              >
                View coverage plans →
              </motion.button>
            </div>
          </motion.div>
        )}

        {/* ML Pricing Engine — compact preview */}
        {/* Policy card — only when active */}
        {activePolicy && (
          <motion.div variants={fadeUp}>
            <div
              id="policy-hero-card"
              className="rounded-card p-5"
              style={{
                background: 'linear-gradient(135deg, #1a1a1a 0%, #2d1810 50%, #3d1f0d 100%)',
                boxShadow: '0 12px 32px rgba(217,119,87,0.25), 0 4px 8px rgba(0,0,0,0.15)',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {/* Subtle glow orb */}
              <div style={{
                position: 'absolute', top: -40, right: -40,
                width: 160, height: 160,
                borderRadius: 999,
                background: 'radial-gradient(circle, rgba(217,119,87,0.18) 0%, transparent 70%)',
                pointerEvents: 'none',
              }} />

              <div className="flex items-center justify-between mb-2">
                <div style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  background: 'rgba(18,183,106,0.18)',
                  border: '1px solid rgba(18,183,106,0.3)',
                  borderRadius: 999, padding: '4px 10px',
                }}>
                  <LiveDot status="active" />
                  <span style={{ fontSize: 10, fontWeight: 700, fontFamily: 'Inter', color: '#12B76A', letterSpacing: '1px', textTransform: 'uppercase' }}>
                    {activePolicy.status || 'Active'}
                  </span>
                </div>
                <span style={{ fontSize: 12, fontFamily: 'Inter', color: 'rgba(255,255,255,0.5)' }}>
                  {activePolicy.weekStart
                    ? `${new Date(activePolicy.weekStart).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })} – ${new Date(activePolicy.weekEnd).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}`
                    : 'This week'}
                </span>
              </div>

              <div style={{ fontFamily: 'Bricolage Grotesque', fontWeight: 800, fontSize: 48, letterSpacing: -2, lineHeight: 1, color: 'white', marginTop: 8 }}>
                ₹{activePolicy.coverage || 600}
              </div>
              <p style={{ fontSize: 13, fontFamily: 'Inter', color: 'rgba(255,255,255,0.6)', marginTop: 4 }}>
                coverage this week · {activePolicy.planName || activePolicy.planId || 'Standard'} plan
              </p>

              <div style={{ height: 1, background: 'rgba(255,255,255,0.1)', margin: '14px 0' }} />

              <div className="flex items-center justify-between">
                <div>
                  <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.8px', margin: 0 }}>Next premium</p>
                  <p style={{ fontSize: 14, fontWeight: 600, fontFamily: 'Inter', color: 'white', marginTop: 3 }}>
                    {policyEndDate} · ₹{activePolicy.price || w.premium}
                  </p>
                </div>
                <div
                  style={{ textAlign: 'right', cursor: 'pointer' }}
                  onClick={() => navigate('/risk-score')}
                >
                  <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.8px', margin: 0 }}>Risk score</p>
                  <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: '#12B76A', marginTop: 3 }}>
                    {w.riskScore} · {w.riskTier === 'LOW' ? 'Low' : w.riskTier === 'HIGH' ? 'High' : 'Medium'}
                  </p>
                  <span style={{ fontSize: 11, color: '#D97757', fontFamily: 'Inter', fontWeight: 600 }}>
                    View breakdown →
                  </span>
                </div>
              </div>

              <button
                type="button"
                onClick={handleDownloadCertificate}
                disabled={downloadLoading || !activePolicyId}
                style={{
                  width: '100%',
                  marginTop: 14,
                  border: '1px solid rgba(255,255,255,0.14)',
                  borderRadius: 12,
                  padding: '12px 14px',
                  background: 'rgba(255,255,255,0.08)',
                  color: 'white',
                  fontSize: 13,
                  fontWeight: 700,
                  fontFamily: 'Inter',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                  cursor: downloadLoading || !activePolicyId ? 'not-allowed' : 'pointer',
                  opacity: downloadLoading || !activePolicyId ? 0.7 : 1,
                }}
              >
                {downloadLoading ? <LoaderCircle size={16} className="animate-spin" /> : <Download size={16} />}
                {downloadLoading ? 'Downloading...' : 'Download Certificate'}
              </button>
            </div>
          </motion.div>
        )}

        {/* Feature 1: Zone Monitor — below policy card, above everything else */}
        {activePolicy && (
          <motion.div variants={fadeUp}>
            <ZoneMonitor />
          </motion.div>
        )}

        {/* Feature 4: New claim notification banner */}
        <AnimatePresence>
          {newClaimAlert && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              style={{ overflow: 'hidden' }}
            >
              <div
                onClick={() => {
                  navigate(`/claim/${newClaimAlert.id
                    || newClaimAlert._id}`)
                  setNewClaimAlert(null)
                }}
                style={{
                  background: 'linear-gradient(135deg, #12B76A, #0A9456)',
                  borderRadius: 14,
                  padding: '14px 16px',
                  cursor: 'pointer',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <div>
                  <p style={{
                    fontSize: 13, fontWeight: 700,
                    fontFamily: 'Inter', color: 'white',
                    margin: '0 0 2px',
                  }}>
                    💰 ₹{newClaimAlert.amount} Payout Processed
                  </p>
                  <p style={{
                    fontSize: 12, fontFamily: 'Inter',
                    color: 'rgba(255,255,255,0.8)', margin: 0,
                  }}>
                    {newClaimAlert.trigger_type || 'Flood'} claim auto-approved · Tap to view
                  </p>
                </div>
                <span style={{
                  fontSize: 18, marginLeft: 8, color: 'white',
                }}>→</span>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Animated alert banner — driven by real zone forecast */}
        <AnimatePresence>
          {showAlert && zoneAlert && (
            <motion.div
              id="alert-banner"
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              style={{ background: 'linear-gradient(135deg, #F79009, #D97757)', overflow: 'hidden', borderRadius: 14 }}
            >
              <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ fontSize: 20 }}>⚠️</span>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: 13, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: 'white', margin: '0 0 2px' }}>
                    {zoneAlert.probability}% flood risk tomorrow
                  </p>
                  <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.8)', fontFamily: 'Inter, sans-serif', margin: 0 }}>
                    {zoneAlert.zone} · {zoneAlert.autoExtended ? 'Coverage auto-extended' : 'Buy coverage now'}
                  </p>
                </div>
                <button
                  onClick={() => setShowAlert(false)}
                  style={{ background: 'rgba(255,255,255,0.2)', border: 'none', borderRadius: 999, width: 28, height: 28, cursor: 'pointer', color: 'white', fontSize: 16, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                >
                  <X size={14} color="white" />
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Stats grid */}
        <motion.div variants={fadeUp} className="grid grid-cols-2 gap-2">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="rounded-card shadow-card p-3.5"
              style={{ background: 'var(--bg-card)', cursor: stat.label === 'RISK SCORE' ? 'pointer' : 'default' }}
              onClick={stat.label === 'RISK SCORE' ? () => navigate('/risk-score') : undefined}
            >
              <p className="text-[11px] font-medium font-body tracking-[0.5px] uppercase" style={{ color: 'var(--text-tertiary)' }}>
                {stat.label}
              </p>
              <p
                className="font-display font-bold text-[22px] mt-1 leading-tight"
                style={{ color: stat.valueColor === '#0F0F0F' ? 'var(--text-primary)' : stat.valueColor }}
              >
                {stat.value}
              </p>
              <p className="text-[12px] font-body mt-0.5" style={{ color: 'var(--text-secondary)' }}>{stat.sub}</p>
              {stat.label === 'RISK SCORE' && (
                <span style={{ fontSize: 11, color: '#D97757', fontFamily: 'Inter', fontWeight: 600 }}>
                  View breakdown →
                </span>
              )}
            </div>
          ))}
        </motion.div>

        {/* Wellness Score Card */}
        {wellnessData && (
          <motion.div variants={fadeUp}>
            <div
              className="rounded-card shadow-card p-4"
              style={{ background: 'var(--bg-card)', border: '1px solid var(--border-light)' }}
            >
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '1px', textTransform: 'uppercase', margin: 0 }}>
                  Wellness Score
                </p>
                <span style={{
                  fontSize: 12, fontWeight: 700, fontFamily: 'Inter',
                  padding: '3px 10px', borderRadius: 999,
                  background: wellnessData.grade === 'A' ? '#ECFDF3' : wellnessData.grade === 'B' ? '#FFFAEB' : '#FEF3F2',
                  color: wellnessData.grade === 'A' ? '#12B76A' : wellnessData.grade === 'B' ? '#F79009' : '#F04438',
                }}>
                  Grade {wellnessData.grade}
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                {/* Circular progress */}
                <div style={{ position: 'relative', width: 68, height: 68, flexShrink: 0 }}>
                  <svg width="68" height="68" viewBox="0 0 68 68">
                    <circle cx="34" cy="34" r="28" fill="none" stroke="var(--border-light)" strokeWidth="7" />
                    <circle
                      cx="34" cy="34" r="28" fill="none"
                      stroke={wellnessData.score >= 80 ? '#12B76A' : wellnessData.score >= 50 ? '#F79009' : '#F04438'}
                      strokeWidth="7"
                      strokeDasharray={`${(wellnessData.score / 100) * 175.9} 175.9`}
                      strokeLinecap="round"
                      transform="rotate(-90 34 34)"
                    />
                  </svg>
                  <div style={{
                    position: 'absolute', inset: 0,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <span style={{ fontSize: 15, fontWeight: 800, fontFamily: 'Bricolage Grotesque, sans-serif', color: 'var(--text-primary)' }}>
                      {wellnessData.score}
                    </span>
                  </div>
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 4px' }}>
                    {wellnessData.score >= 80 ? 'Excellent' : wellnessData.score >= 60 ? 'Good' : wellnessData.score >= 40 ? 'Fair' : 'Needs attention'}
                  </p>
                  <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)', margin: 0, lineHeight: 1.4 }}>
                    💡 {wellnessData.tip}
                  </p>
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {/* Income Tier Badge */}
        <motion.div variants={fadeUp}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <IncomeTierBadge dailyOrders={Number(worker?.avg_daily_orders || 8)} />
            <p style={{ fontSize: 12, color: 'var(--text-secondary)', fontFamily: 'Inter', margin: 0 }}>
              Your income tier determines payout amount
            </p>
          </div>
        </motion.div>

        {/* Quick Actions */}
        <motion.div variants={fadeUp}>
          <p className="text-[14px] font-semibold font-body mb-2" style={{ color: 'var(--text-primary)' }}>
            Quick actions
          </p>
          <div className="grid grid-cols-4 gap-2">
            {[
              { icon: ShieldCheck, label: 'Earnings', path: '/earnings', color: '#12B76A', bg: '#ECFDF3' },
              { icon: MapPin, label: t('zone_intel'), path: '/zone-intel', color: '#2E90FA', bg: '#EFF8FF' },
              { icon: Bot, label: t('assistant'), path: '/assistant', color: '#D97757', bg: '#FDF1ED' },
              { icon: TrendingUp, label: t('risk_score'), path: '/risk-score', color: '#7A5AF8', bg: '#F4F3FF' },
              { icon: Zap, label: 'How It Works', path: '/how-it-works', color: '#F79009', bg: '#FFFAEB' },
            ].map((action) => {
              const Icon = action.icon
              return (
                <motion.button
                  key={action.path}
                  whileTap={{ scale: 0.94 }}
                  onClick={() => navigate(action.path)}
                  style={{
                    display: 'flex', flexDirection: 'column', alignItems: 'center',
                    gap: 6, padding: '12px 4px',
                    borderRadius: 12,
                    border: '1px solid var(--border-light)',
                    background: 'var(--bg-card)',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: action.bg,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Icon size={18} color={action.color} />
                  </div>
                  <span style={{
                    fontSize: 10, fontWeight: 600, fontFamily: 'Inter',
                    color: 'var(--text-secondary)',
                    textAlign: 'center', lineHeight: 1.2,
                  }}>
                    {action.label}
                  </span>
                </motion.button>
              )
            })}
          </div>
        </motion.div>

        {/* Recent payouts */}
        <motion.div variants={fadeUp}>
          <div className="flex items-center justify-between mb-2">
            <p className="text-[14px] font-semibold font-body" style={{ color: 'var(--text-primary)' }}>{t('recent_claims')}</p>
            {paidClaims.length > 0 && (
              <button className="text-[13px] text-brand font-semibold font-body" onClick={() => navigate('/claims')}>{t('view_all')}</button>
            )}
          </div>
          <div className="rounded-card shadow-card overflow-hidden" style={{ background: 'var(--bg-card)' }}>
            {paidClaims.length === 0 ? (
              <div style={{ padding: '28px 16px', textAlign: 'center' }}>
                <span style={{ fontSize: 32, display: 'block', marginBottom: 10 }}>💸</span>
                <p style={{ fontSize: 14, fontWeight: 600, fontFamily: 'Bricolage Grotesque, sans-serif', color: 'var(--text-primary)', margin: '0 0 4px' }}>
                  No payouts yet
                </p>
                <p style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter, sans-serif', margin: 0 }}>
                  Payouts appear here when a trigger event fires
                </p>
              </div>
            ) : (
              paidClaims.slice(0, 2).map((payout, i) => (
                <motion.button
                  key={payout.id}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => navigate(`/claim/${payout.id || 'cl-001'}`)}
                  className="w-full flex items-center justify-between px-4 py-3.5 text-left"
                  style={{ borderBottom: i < Math.min(paidClaims.length, 2) - 1 ? '1px solid var(--border-light)' : 'none' }}
                >
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-[16px]">
                        {payout.type === 'FLOOD' ? '🌊' : '📱'}
                      </span>
                      <p className="text-[14px] font-medium font-body" style={{ color: 'var(--text-primary)' }}>
                        {payout.event}
                      </p>
                    </div>
                    <p className="text-[12px] font-body mt-0.5 pl-7" style={{ color: 'var(--text-secondary)' }}>
                      {new Date(payout.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-display font-bold text-[16px] text-success">
                      +{formatINR(payout.amount)}
                    </p>
                    <Badge variant="success">Paid</Badge>
                  </div>
                </motion.button>
              ))
            )}
          </div>
        </motion.div>
      </motion.div>

      {/* Tour button — floating above chat button */}
      <motion.button
        id="tour-btn"
        onClick={() => setShowTour(true)}
        whileHover={{ scale: 1.08 }}
        whileTap={{ scale: 0.92 }}
        style={{
          position: 'fixed',
          bottom: 148,
          right: 16,
          zIndex: 90,
          width: 44, height: 44,
          borderRadius: 999,
          background: '#0F0F0F',
          border: '2px solid rgba(255,255,255,0.1)',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
        }}
        title="Take app tour"
      >
        <span style={{ fontSize: 18 }}>🗺️</span>
      </motion.button>

      <ChatWidget />

      {/* Welcome modal for first-time users */}
      <AnimatePresence>
        {showWelcome && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => { setShowWelcome(false); setOnboarded(true) }}
              style={{
                position: 'fixed', inset: 0,
                background: 'rgba(0,0,0,0.5)',
                zIndex: 9000,
                backdropFilter: 'blur(4px)',
              }}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
              style={{
                position: 'fixed',
                zIndex: 9001,
                bottom: 24, left: 16, right: 16,
                maxWidth: 380,
                margin: '0 auto',
                background: 'white',
                borderRadius: 20,
                padding: 24,
                boxShadow: '0 20px 60px rgba(0,0,0,0.25)',
                textAlign: 'center',
              }}
            >
              <div style={{ fontSize: 48, marginBottom: 12 }}>🛡️</div>
              <h2 style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 22, fontWeight: 800,
                color: '#0F0F0F', margin: '0 0 8px',
              }}>
                Welcome to GuidePay!
              </h2>
              <p style={{
                fontSize: 14, fontFamily: 'Inter',
                color: '#6B6B6B', lineHeight: 1.6,
                margin: '0 0 6px',
              }}>
                Hey {firstName} 👋 You're all set up!
              </p>
              <p style={{
                fontSize: 13, fontFamily: 'Inter',
                color: '#9B9B9B', lineHeight: 1.5,
                margin: '0 0 20px',
              }}>
                Income protection for floods, outages, and curfews. Get covered for as low as ₹49/week.
              </p>

              <div style={{
                display: 'flex', flexDirection: 'column', gap: 8,
              }}>
                <motion.button
                  onClick={() => {
                    setShowWelcome(false)
                    setOnboarded(true)
                    navigate('/coverage')
                  }}
                  whileTap={{ scale: 0.97 }}
                  style={{
                    width: '100%', padding: '13px',
                    borderRadius: 12, border: 'none',
                    background: 'linear-gradient(135deg, #D97757, #B85C3A)',
                    color: 'white', fontSize: 15,
                    fontWeight: 700, fontFamily: 'Inter',
                    cursor: 'pointer',
                    boxShadow: '0 4px 16px rgba(217,119,87,0.35)',
                  }}
                >
                  View coverage plans →
                </motion.button>
                <motion.button
                  onClick={() => {
                    setShowWelcome(false)
                    setOnboarded(true)
                    setShowTour(true)
                  }}
                  whileTap={{ scale: 0.97 }}
                  style={{
                    width: '100%', padding: '12px',
                    borderRadius: 12,
                    border: '1px solid #E4E4E7',
                    background: 'white',
                    color: '#0F0F0F', fontSize: 14,
                    fontWeight: 600, fontFamily: 'Inter',
                    cursor: 'pointer',
                  }}
                >
                  Take a quick tour 🗺️
                </motion.button>
                <button
                  onClick={() => { setShowWelcome(false); setOnboarded(true) }}
                  style={{
                    background: 'none', border: 'none',
                    color: '#9B9B9B', fontSize: 13,
                    fontFamily: 'Inter', cursor: 'pointer',
                    padding: '6px',
                  }}
                >
                  Skip for now
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </motion.div>
  )
}
