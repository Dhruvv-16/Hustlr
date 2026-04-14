import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import Badge from '../../components/ui/Badge'
import { getMyClaims } from '../../services/api'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const FILTERS = ['All', 'PAID', 'AUTO_APPROVED', 'MANUAL_REVIEW', 'REJECTED']
const FILTER_LABELS = { All: 'All', PAID: 'Paid', AUTO_APPROVED: 'Approved', MANUAL_REVIEW: 'Review', REJECTED: 'Rejected' }
const typeIcon = (type) => ({ FLOOD: '🌊', OUTAGE: '📱', CURFEW: '🚫' }[type] || '📋')
const statusVariant = (status) => ({ PAID: 'success', AUTO_APPROVED: 'success', MANUAL_REVIEW: 'warning', PENDING: 'warning', REJECTED: 'danger' }[status] || 'default')

export default function ClaimsList() {
  const navigate = useNavigate()
  const [filter, setFilter] = useState('All')
  const [allClaims, setAllClaims] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getMyClaims(undefined, 50, 0)
      .then((res) => setAllClaims(res?.claims || []))
      .catch(() => setAllClaims([]))
      .finally(() => setLoading(false))
  }, [])

  const claims = filter === 'All' ? allClaims : allClaims.filter((claim) => claim.status === filter)

  return (
    <motion.div className="min-h-screen pb-24" style={{ background: 'var(--bg-secondary)' }} variants={pageVariants} initial="initial" animate="animate" exit="exit">
      <div style={{ padding: '12px 16px 0', display: 'flex', gap: 8, overflowX: 'auto' }}>
        {FILTERS.map((entry) => (
          <motion.button key={entry} onClick={() => setFilter(entry)} whileTap={{ scale: 0.96 }} style={{ padding: '6px 14px', borderRadius: 999, flexShrink: 0, fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', border: filter === entry ? 'none' : '1px solid var(--border)', background: filter === entry ? '#D97757' : 'var(--bg-card)', color: filter === entry ? 'white' : 'var(--text-secondary)', cursor: 'pointer' }}>
            {FILTER_LABELS[entry]}
          </motion.button>
        ))}
      </div>

      <div style={{ padding: '12px 16px' }}>
        {loading ? (
          <div style={{ textAlign: 'center', paddingTop: 80 }}>
            <p style={{ fontSize: 14, color: 'var(--text-tertiary)', fontFamily: 'Inter, sans-serif' }}>Loading...</p>
          </div>
        ) : claims.length === 0 ? (
          <div style={{ textAlign: 'center', paddingTop: 80 }}>
            <span style={{ fontSize: 48, display: 'block', marginBottom: 16 }}>📋</span>
            <p style={{ fontSize: 16, fontWeight: 600, fontFamily: 'Bricolage Grotesque, sans-serif', color: 'var(--text-primary)', margin: '0 0 8px' }}>No claims yet</p>
            <p style={{ fontSize: 14, color: 'var(--text-tertiary)', fontFamily: 'Inter, sans-serif', margin: 0 }}>You will see payouts here when triggers fire.</p>
          </div>
        ) : (
          <div style={{ borderRadius: 16, overflow: 'hidden', background: 'var(--bg-card)', boxShadow: 'var(--shadow-card)' }}>
            {claims.map((claim, index) => {
              const claimId = claim.id || claim._id
              return (
              <motion.button key={claimId} onClick={() => navigate(`/claim/${claimId}`)} whileTap={{ scale: 0.98 }} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px', background: 'transparent', border: 'none', borderBottom: index < claims.length - 1 ? '1px solid var(--border-light)' : 'none', cursor: 'pointer', textAlign: 'left' }}>
                <div style={{ width: 40, height: 40, borderRadius: 12, background: 'var(--bg-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 }}>
                  {typeIcon(claim.trigger_type)}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ fontSize: 14, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: 'var(--text-primary)', margin: '0 0 3px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {(claim.trigger_event?.city || claim.zone || claim.trigger_type)} - {claim.trigger_type}
                  </p>
                  <p style={{ fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter, sans-serif', margin: 0 }}>
                    {new Date(claim.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </p>
                </div>
                <div style={{ textAlign: 'right', flexShrink: 0 }}>
                  {claim.amount > 0 && (
                    <p style={{ fontSize: 15, fontWeight: 700, fontFamily: 'Bricolage Grotesque, sans-serif', color: '#12B76A', margin: '0 0 4px' }}>
                      +Rs{claim.amount}
                    </p>
                  )}
                  <Badge variant={statusVariant(claim.status)}>{claim.status}</Badge>
                </div>
              </motion.button>
            )})}
          </div>
        )}
      </div>
    </motion.div>
  )
}
