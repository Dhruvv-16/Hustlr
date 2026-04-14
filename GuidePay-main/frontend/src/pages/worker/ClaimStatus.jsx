import { useParams, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Check, ChevronDown, ChevronUp, CheckCircle2 } from 'lucide-react'
import { useState, useEffect } from 'react'
import TopBar from '../../components/ui/TopBar'
import Badge from '../../components/ui/Badge'
import BottomNav from '../../components/ui/BottomNav'
import ChatWidget from '../../components/chat/ChatWidget'
import { ClaimTimeline } from '../../components/claims/ClaimTimeline'
import { AdvancedFraudPanel } from '../../components/claims/AdvancedFraudPanel'
import { useClaimStore } from '../../store/claimStore'
import { useWorkerStore } from '../../store/workerStore'
import { getClaimDetail } from '../../services/api'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

export default function ClaimStatus() {
  const { id } = useParams()
  const navigate = useNavigate()
  const storeClaim = useClaimStore((s) => s.activeClaim)
  const workerClaims = useWorkerStore((s) => s.claims)
  const activePolicy = useWorkerStore((s) => s.activePolicy)
  const [apiClaim, setApiClaim] = useState(null)
  const [loading, setLoading] = useState(true)
  const hasActivePolicy = !!(activePolicy && activePolicy.status === 'ACTIVE')

  // Fetch real claim data from backend
  useEffect(() => {
    const fetchClaim = async () => {
      try {
        const token = localStorage.getItem('gp-access-token') || localStorage.getItem('gp-token')
        if (!token || !id) {
          setLoading(false)
          return
        }
        const data = await getClaimDetail(id)
        if (data) setApiClaim(data)
      } catch (e) {
        // Silent — will use store/fallback data
      }
      setLoading(false)
    }
    fetchClaim()
  }, [id])

  // Priority: API data > worker store > claim store > minimal fallback
  const foundClaim = apiClaim
    || workerClaims?.find(c => (c.id === id || c._id === id))
    || storeClaim

  const claim = foundClaim || {
    trigger_type: 'FLOOD',
    amount: 600,
    status: 'PAID',
    created_at: new Date(Date.now() - 300000).toISOString(),
    paid_at: new Date().toISOString(),
    zone: 'Kondapur, Hyderabad',
    fraud_score: 0.04,
    fraud_flags: [],
    fraud_checks: {
      duplicate: { result: 'PASS' },
      gps: { result: 'PASS', distance_km: 0.8 },
      activity: { result: 'PASS', age_minutes: 47 },
      frequency: { result: 'PASS' },
      correlation: { result: 'CONFIRMED', ratio: 0.84 },
      worker_risk: { result: 'PASS' },
      account_age: { result: 'PASS' },
    },
  }

  const statusBadge = claim.status === 'PROCESSING' || claim.status === 'MANUAL_REVIEW'
    ? <Badge variant="warning">Processing</Badge>
    : claim.status === 'REJECTED'
    ? <Badge variant="danger">Rejected</Badge>
    : <Badge variant="success">Paid</Badge>

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-primary)' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{
            width: 28, height: 28,
            border: '3px solid var(--border)',
            borderTopColor: '#D97757',
            borderRadius: 999,
            animation: 'spin 0.8s linear infinite',
            margin: '0 auto 12px',
          }} />
          <p style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading claim...</p>
        </div>
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    )
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
      <TopBar
        title={`← Claim #${(claim.id || claim._id || id || 'GP-0847').slice(-6).toUpperCase()}`}
        showBack
        rightAction={statusBadge}
      />

      <div className="px-4 mt-4 flex flex-col gap-4">
        {/* Amount card */}
        <div className="rounded-card shadow-card p-5" style={{ background: 'var(--bg-card)' }}>
          <p className="text-[11px] font-semibold font-body tracking-[1px] uppercase" style={{ color: 'var(--text-tertiary)' }}>
            {claim.trigger_type || 'FLOOD'} ALERT — {(claim.zone || 'KONDAPUR')?.split(',')[0]?.toUpperCase()}
          </p>
          <div className="font-display font-extrabold text-[56px] tracking-[-2px] leading-none mt-1" style={{ color: 'var(--text-primary)' }}>
            ₹{claim.amount}
          </div>
          <p className="text-[13px] font-body mt-1" style={{ color: 'var(--text-secondary)' }}>
            {claim.created_at
              ? new Date(claim.created_at).toLocaleString('en-IN', {
                  day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                })
              : 'Processing...'}
          </p>
        </div>

        {/* Feature 2: Claim Timeline */}
        <ClaimTimeline claim={claim} />

        <AdvancedFraudPanel claim={claim} />

        {hasActivePolicy && claim?.status === 'AUTO_APPROVED' && !claim?.paid_at && (
          <motion.button
            onClick={() => navigate(`/payout/${claim.id || claim._id}`)}
            style={{
              width: '100%', padding: '14px',
              borderRadius: 12, border: 'none',
              background: '#12B76A',
              color: 'white', fontSize: 15,
              fontWeight: 700, fontFamily: 'Inter',
              cursor: 'pointer', marginTop: 12,
            }}
          >
            💰 Receive ₹{claim.amount} via UPI →
          </motion.button>
        )}
      </div>

      <ChatWidget />
      <BottomNav />

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </motion.div>
  )
}
