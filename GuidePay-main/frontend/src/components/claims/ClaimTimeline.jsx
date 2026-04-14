import { useMemo, useState } from 'react'
import { motion } from 'framer-motion'

import { getClaimAuditTrail } from '../../services/api'
import { 
  CLAIM_STATUS_PLAIN, 
  CLAIM_STATUS_SUBTITLE,
  AUDIT_EVENT_PLAIN,
  FRAUD_SCORE_PLAIN,
  ZONE_CORRELATION_PLAIN,
  getTimeEstimate
} from '../../utils/plainLanguage'
import { shareOnWhatsApp } from '../../utils/whatsappShare'
import { useWorkerStore } from '../../store/workerStore'

const STEP_META = {
  TRIGGER_DETECTED: {
    label: '🌊 Flood detected in your area',
    icon: '⚠️',
    color: '#2E90FA',
    description: (claim) => `${claim.trigger_type || 'FLOOD'} event confirmed for ${claim.trigger_event?.city || claim.zone || 'your area'}`,
  },
  ELIGIBILITY_CHECK: {
    label: '📍 Your location and policy confirmed',
    icon: '🪪',
    color: '#7A5AF8',
    description: () => 'Minimum active days and zone eligibility checked',
  },
  FRAUD_CHECK: {
    label: '🔍 9 safety signals checked',
    icon: '🛡️',
    color: '#F79009',
    description: (claim) => FRAUD_SCORE_PLAIN(claim.fraud_score || 0),
  },
  PAYOUT_CALCULATED: {
    label: '💸 Payout calculated',
    icon: '🧮',
    color: '#D97757',
    description: (claim) => `Amount locked at ₹${claim.amount || 0}`,
  },
  TRANSFER_INITIATED: {
    label: '🏦 Money transfer started',
    icon: '🏦',
    color: '#12B76A',
    description: () => 'Payment rail opened and transfer requested',
  },
  PAYMENT_SUCCESS: {
    label: '✅ Money sent to your UPI',
    icon: '✅',
    color: '#12B76A',
    description: (claim) => `₹${claim.amount || 0} credited to your UPI`,
  },
  PAYMENT_FAILED: {
    label: '❌ Could not process this time',
    icon: '❌',
    color: '#F04438',
    description: () => 'Transfer failed. Money is still safe and will be retried.',
  },
}

const DEFAULT_STEPS = [
  'TRIGGER_DETECTED',
  'ELIGIBILITY_CHECK',
  'FRAUD_CHECK',
  'PAYOUT_CALCULATED',
  'TRANSFER_INITIATED',
  'PAYMENT_SUCCESS',
]

const formatStamp = (value) => {
  if (!value) return 'Pending'
  const date = new Date(value)
  return date.toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const mapAuditToStep = (entry) => {
  const step = entry.step || ''
  if (step === 'TRIGGER_CONFIRMED') return 'TRIGGER_DETECTED'
  if (step === 'ELIGIBILITY_CHECK') return 'ELIGIBILITY_CHECK'
  if (step === 'PAYOUT_CALCULATED') return 'PAYOUT_CALCULATED'
  if (step === 'TRANSFER_INITIATED') return 'TRANSFER_INITIATED'
  if (step === 'PAYMENT_SUCCESS') return 'PAYMENT_SUCCESS'
  if (step === 'PAYMENT_FAILED') return 'PAYMENT_FAILED'
  return step
}

export const ClaimTimeline = ({ claim }) => {
  const worker = useWorkerStore(s => s.worker)
  const language = useWorkerStore(s => s.language) || 'en'
  const [auditModal, setAuditModal] = useState({ open: false, loading: false, data: null, error: '' })
  const [showTechnicalDetails, setShowTechnicalDetails] = useState({});

  const toggleTechnicalDetails = (index) => {
    setShowTechnicalDetails(prev => ({ ...prev, [index]: !prev[index] }));
  };

  const timeline = useMemo(() => {
    if (!claim) return []

    const auditByStep = {}
    ;(claim.payout_audit_log || []).forEach((entry) => {
      auditByStep[mapAuditToStep(entry)] = entry
    })

    const fraudCompleted = claim.fraud_score != null
    const items = DEFAULT_STEPS.map((step, index) => {
      const meta = STEP_META[step]
      const audit = auditByStep[step]
      const complete = step === 'FRAUD_CHECK'
        ? fraudCompleted
        : Boolean(audit) || (step === 'PAYMENT_SUCCESS' && claim.status === 'PAID')
      const failed = step === 'PAYMENT_SUCCESS' && claim.payout_status === 'FAILED'
      const timestamp = audit?.created_at
        || (step === 'FRAUD_CHECK' ? claim.updated_at || claim.created_at : null)
        || (step === 'PAYMENT_SUCCESS' && claim.paid_at)
      return { step, meta, audit, complete, failed, timestamp, index }
    })

    if (claim.payout_status === 'FAILED' && !items.find((item) => item.step === 'PAYMENT_FAILED' && item.complete)) {
      items.push({
        step: 'PAYMENT_FAILED',
        meta: STEP_META.PAYMENT_FAILED,
        audit: auditByStep.PAYMENT_FAILED,
        complete: true,
        failed: true,
        timestamp: auditByStep.PAYMENT_FAILED?.created_at || claim.updated_at,
      })
    }

    return items
  }, [claim])

  if (!claim) return null

  const fraudChecks = Object.entries(claim.fraud_checks || {})

  const handleWhatsAppShare = () => {
    shareOnWhatsApp({
      workerName: worker?.name || 'I',
      amount: claim.amount,
      city: worker?.city || 'my city',
      zone: worker?.zone || 'my zone',
      language: language,
    });
  }

  const openAuditTrail = async () => {
    setAuditModal({ open: true, loading: true, data: null, error: '' })
    try {
      const data = await getClaimAuditTrail(claim.id || claim._id)
      setAuditModal({ open: true, loading: false, data, error: '' })
    } catch (error) {
      console.error('[ClaimTimeline] audit trail load failed', error)
      setAuditModal({ open: true, loading: false, data: null, error: 'Could not load audit trail.' })
    }
  }

  return (
    <>
      {claim.status === 'PAID' && (
        <div style={{
          background: 'linear-gradient(135deg, #0D1F0D, #1a3a1a)',
          border: '2px solid #4ADE80',
          borderRadius: '16px',
          padding: '20px',
          textAlign: 'center',
          marginBottom: '20px',
        }}>
          <div style={{ fontSize: '40px', marginBottom: '8px' }}>💸</div>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#4ADE80' }}>
            ₹{claim.amount}
          </div>
          <div style={{ fontSize: '14px', color: '#F4F4F6', marginTop: '4px' }}>
            Sent to your UPI
          </div>
          <div style={{ fontSize: '12px', color: '#8A8A8F', marginTop: '4px' }}>
            Transaction ID: {claim.upi_transaction_id || claim.upi_ref || claim._id}
          </div>
          
          <button onClick={handleWhatsAppShare} style={{
            marginTop: '16px',
            background: '#25D366',
            border: 'none',
            borderRadius: '8px',
            padding: '10px 20px',
            color: 'white',
            fontWeight: '700',
            fontSize: '14px',
            cursor: 'pointer',
            width: '100%',
          }}>
            📲 Share on WhatsApp
          </button>
        </div>
      )}

      <div style={{ background: 'var(--bg-card)', borderRadius: 16, padding: 20, border: '1px solid var(--border)' }}>
        
        {/* New Plain Language Status Header */}
        <div style={{ 
          background: 'rgba(18, 183, 106, 0.05)', 
          border: '1px solid rgba(18, 183, 106, 0.2)', 
          borderRadius: '12px', 
          padding: '16px', 
          marginBottom: '24px' 
        }}>
          <div style={{ fontSize: '16px', fontWeight: '700', color: claim.status === 'REJECTED' ? '#F04438' : '#12B76A', marginBottom: '4px' }}>
            {CLAIM_STATUS_PLAIN[claim.status] || claim.status}
          </div>
          <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>
            {CLAIM_STATUS_SUBTITLE[claim.status] || 'Processing your claim.'}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'var(--text-tertiary)', fontWeight: '600' }}>
            ⏱ {getTimeEstimate(claim.status) || 'Updating soon'}
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
          {timeline.map((item, index) => {
            const isLast = index === timeline.length - 1
            const color = item.failed ? '#F04438' : item.meta.color
            return (
              <div key={`${item.step}-${index}`} style={{ display: 'flex', gap: 12 }}>
                <div style={{ width: 34, display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
                  <motion.div
                    initial={{ scale: 0.85, opacity: 0.6 }}
                    animate={{ scale: item.complete ? 1 : 0.92, opacity: 1 }}
                    style={{
                      width: 34, height: 34, borderRadius: 999, display: 'flex', alignItems: 'center', justifyContent: 'center',
                      background: item.complete ? `${color}18` : 'var(--bg-secondary)',
                      border: `2px solid ${item.complete ? color : 'var(--border)'}`,
                      fontSize: 15,
                    }}
                  >
                    {item.meta.icon}
                  </motion.div>
                  {!isLast && (
                    <motion.div
                      initial={{ height: 0 }}
                      animate={{ height: 54 }}
                      style={{
                        width: 2, background: item.complete ? `${color}` : 'var(--border)',
                        opacity: item.complete ? 0.35 : 0.2, marginTop: 4,
                      }}
                    />
                  )}
                </div>

                <div style={{ flex: 1, paddingBottom: isLast ? 0 : 16 }}>
                  <div className="flex items-center justify-between gap-3">
                    <p style={{ fontSize: 13, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: 0 }}>
                      {item.meta.label}
                    </p>
                    <span style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)' }}>
                      {formatStamp(item.timestamp)}
                    </span>
                  </div>
                  <p style={{ fontSize: 12, fontFamily: 'Inter', color: item.complete ? color : 'var(--text-secondary)', margin: '4px 0 0', fontWeight: 600 }}>
                    {item.meta.description(claim)}
                  </p>
                  
                  {item.audit?.message && (
                    <div style={{ marginTop: 8 }}>
                      <button onClick={() => toggleTechnicalDetails(index)} style={{
                        background: 'none', border: 'none', padding: 0, color: 'var(--text-tertiary)',
                        fontSize: '11px', textDecoration: 'underline', cursor: 'pointer', marginBottom: '6px'
                      }}>
                        {showTechnicalDetails[index] ? 'Hide technical details' : 'Show technical details'}
                      </button>
                      
                      {showTechnicalDetails[index] && (
                        <div style={{ padding: '8px 12px', background: 'var(--bg-card-raised)', borderRadius: 8, border: '1px solid var(--border)' }}>
                          <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-secondary)', margin: 0, fontWeight: 500 }}>
                            {item.audit.message}
                          </p>
                          {item.audit.hash && (
                            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                              <span title="Blockchain-secured Immutable Hash" style={{ fontSize: 9, fontFamily: 'monospace', color: '#12B76A', background: 'rgba(18,183,106,0.1)', border: '1px solid rgba(18,183,106,0.2)', padding: '2px 4px', borderRadius: 4 }}>
                                SHA-256
                              </span>
                              <span style={{ fontSize: 9, fontFamily: 'monospace', color: 'var(--text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                {item.audit.hash}
                              </span>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>

        <button
          type="button"
          onClick={openAuditTrail}
          style={{
            width: '100%', marginTop: 16, border: '1px solid var(--border-light)', borderRadius: 12, padding: '12px 14px',
            background: 'var(--bg-secondary)', color: 'var(--text-primary)', fontSize: 13, fontWeight: 700,
            fontFamily: 'Inter', cursor: 'pointer',
          }}
        >
          View Audit Trail
        </button>

        {fraudChecks.length > 0 && (
          <div style={{ marginTop: 18, padding: '12px 14px', background: 'var(--bg-secondary)', borderRadius: 12, border: '1px solid var(--border-light)' }}>
            <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '1px', textTransform: 'uppercase', margin: '0 0 10px' }}>
              Fraud Signals
            </p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px 12px' }}>
              {fraudChecks.slice(0, 8).map(([key, value]) => {
                let plainLabel = key.replace(/_/g, ' ');
                if (key === 'zone_correlation') plainLabel = ZONE_CORRELATION_PLAIN(value.score || value.value || 0.5);
                return (
                  <div key={key} style={{ display: 'flex', alignItems: 'flex-start', gap: 6 }}>
                    <span style={{ color: value?.result === 'FAIL' ? '#F04438' : value?.result === 'WARNING' ? '#F79009' : '#12B76A', fontSize: 11, marginTop: '2px' }}>
                      {value?.result === 'FAIL' ? '●' : value?.result === 'WARNING' ? '◐' : '●'}
                    </span>
                    <span style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-secondary)' }}>
                      {plainLabel}
                    </span>
                  </div>
                )
              })}
            </div>
          </div>
        )}
      </div>

      {auditModal.open && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 120, background: 'rgba(15,23,42,0.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
          <div style={{ width: '100%', maxWidth: 540, maxHeight: '85vh', overflow: 'auto', borderRadius: 18, background: 'var(--bg-card)', border: '1px solid var(--border-light)', padding: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <p style={{ margin: 0, fontSize: 18, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: 'var(--text-primary)' }}>Audit Trail</p>
              <button type="button" onClick={() => setAuditModal({ open: false, loading: false, data: null, error: '' })} style={{ border: 'none', background: 'transparent', cursor: 'pointer', fontSize: 18, color: 'var(--text-secondary)' }}>×</button>
            </div>

            {auditModal.loading && <p style={{ margin: 0, fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading audit trail...</p>}
            {auditModal.error && <p style={{ margin: 0, fontSize: 13, color: '#F04438', fontFamily: 'Inter' }}>{auditModal.error}</p>}

            {auditModal.data?.audit_trail?.map((entry, index) => (
              <div key={`${entry.event}-${index}`} style={{ display: 'flex', gap: 12, marginBottom: 14 }}>
                <div style={{ width: 12, height: 12, borderRadius: 999, background: '#D97757', marginTop: 6, flexShrink: 0 }} />
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
                    <p style={{ margin: 0, fontSize: 13, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)' }}>
                      {AUDIT_EVENT_PLAIN[entry.event] || entry.event.replace(/_/g, ' ')}
                    </p>
                    <span style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>{formatStamp(entry.timestamp)}</span>
                  </div>
                  <p style={{ margin: '4px 0 0', fontSize: 12, color: 'var(--text-secondary)', fontFamily: 'Inter' }}>{entry.actor}</p>
                  
                  <button onClick={() => toggleTechnicalDetails(`modal-${index}`)} style={{
                    background: 'none', border: 'none', padding: 0, color: 'var(--text-tertiary)',
                    fontSize: '10px', textDecoration: 'underline', cursor: 'pointer', marginTop: '6px'
                  }}>
                    {showTechnicalDetails[`modal-${index}`] ? 'Hide details' : 'Show details'}
                  </button>

                  {showTechnicalDetails[`modal-${index}`] && (
                    <div style={{ marginTop: 6, background: 'var(--bg-secondary)', padding: '8px', borderRadius: '8px' }}>
                      <div style={{ fontSize: 10, color: 'var(--text-tertiary)', fontFamily: 'monospace' }}>Hash: {entry.hash?.slice(0, 16)}...</div>
                      {entry.event === 'fraud_scored' && (
                        <p style={{ margin: '4px 0 0', fontSize: 11, color: '#B45309', fontFamily: 'Inter', fontWeight: 700 }}>
                          Fraud score {entry.details?.score} · confidence {entry.details?.confidence}
                        </p>
                      )}
                    </div>
                  )}
                </div>
              </div>
            ))}

            {auditModal.data?.audit_trail?.length > 0 && (
              <div style={{ marginTop: 16, padding: '10px 12px', borderRadius: 12, background: '#ECFDF3', color: '#027A48', fontFamily: 'Inter', fontSize: 12, fontWeight: 700 }}>
                Chain Verified ✓
              </div>
            )}
          </div>
        </div>
      )}
    </>
  )
}
