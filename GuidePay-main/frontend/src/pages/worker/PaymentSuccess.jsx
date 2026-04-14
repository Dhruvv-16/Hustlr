import { useState, useRef } from 'react'
import { motion } from 'framer-motion'
import { useLocation, useNavigate } from 'react-router-dom'
import { useWorkerStore } from '../../store/workerStore'
import { CheckCircle, Download, Share2,
  Shield, Calendar, Hash } from 'lucide-react'

const PaymentSuccess = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const activePolicy = useWorkerStore(s => s.activePolicy)
  const worker = useWorkerStore(s => s.worker)
  const receiptRef = useRef(null)

  const policy = location.state?.policy || activePolicy
  const receipt = location.state?.receipt

  if (!policy) {
    navigate('/coverage')
    return null
  }

  const receiptId = receipt?.receipt_id
    || `GP-${Date.now().toString().slice(-8)}`

  const formatDate = (iso) => {
    if (!iso) return '—'
    return new Date(iso).toLocaleDateString('en-IN', {
      day: 'numeric', month: 'short', year: 'numeric',
    })
  }

  const handleDownloadReceipt = () => {
    const receiptHTML = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>GuidePay Receipt ${receiptId}</title>
        <style>
          body { font-family: Arial, sans-serif;
                 max-width: 400px; margin: 40px auto;
                 padding: 20px; }
          .header { text-align: center;
                    border-bottom: 2px solid #D97757;
                    padding-bottom: 20px;
                    margin-bottom: 20px; }
          .logo { font-size: 24px; font-weight: 800;
                  color: #D97757; }
          .row { display: flex;
                 justify-content: space-between;
                 padding: 8px 0;
                 border-bottom: 1px solid #eee; }
          .label { color: #666; font-size: 13px; }
          .value { font-weight: 600; font-size: 13px; }
          .amount { font-size: 28px; font-weight: 800;
                    color: #12B76A; text-align: center;
                    margin: 20px 0; }
          .footer { text-align: center; margin-top: 20px;
                    color: #999; font-size: 11px; }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="logo">GuidePay</div>
          <div style="color: #666; font-size: 12px;">Payment Receipt</div>
        </div>
        <div class="amount">
          ₹${policy.price || policy.weeklyPremium || policy.weekly_premium || 58}
        </div>
        <div class="row">
          <span class="label">Receipt ID</span>
          <span class="value">${receiptId}</span>
        </div>
        <div class="row">
          <span class="label">Worker</span>
          <span class="value">${worker?.name || 'Ravi Kumar'}</span>
        </div>
        <div class="row">
          <span class="label">Plan</span>
          <span class="value">${policy.planName || policy.plan_name || 'Standard'} Plan</span>
        </div>
        <div class="row">
          <span class="label">Coverage</span>
          <span class="value">₹600/week</span>
        </div>
        <div class="row">
          <span class="label">Valid From</span>
          <span class="value">${formatDate(policy.weekStart || policy.week_start)}</span>
        </div>
        <div class="row">
          <span class="label">Valid Until</span>
          <span class="value">${formatDate(policy.weekEnd || policy.week_end)}</span>
        </div>
        <div class="row">
          <span class="label">Payment ID</span>
          <span class="value" style="font-size:10px;">
            ${policy.paymentId || policy.payment_id || 'MOCK_' + Date.now()}
          </span>
        </div>
        <div class="footer">
          GuidePay · Team SentinelX · KL University<br/>
          This is a simulated payment for competition purposes.
        </div>
      </body>
      </html>
    `
    const blob = new Blob([receiptHTML], { type: 'text/html' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `GuidePay-Receipt-${receiptId}.html`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--bg-secondary)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: 20,
    }}>
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: 'spring', stiffness: 300, damping: 25 }}
        style={{ width: '100%', maxWidth: 400 }}
      >
        {/* Success animation */}
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2, type: 'spring', stiffness: 400 }}
            style={{
              width: 80, height: 80,
              borderRadius: 999,
              background: 'rgba(18,183,106,0.12)',
              border: '3px solid #12B76A',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 16px',
            }}
          >
            <CheckCircle size={40} color="#12B76A" strokeWidth={2.5}/>
          </motion.div>
          <h1 style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 26, fontWeight: 800,
            color: 'var(--text-primary)',
            margin: '0 0 6px',
          }}>
            Coverage Active!
          </h1>
          <p style={{
            fontSize: 14, fontFamily: 'Inter',
            color: 'var(--text-secondary)', margin: 0,
          }}>
            You are now protected for this week
          </p>
        </div>

        {/* Receipt card */}
        <div
          ref={receiptRef}
          style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 20,
            overflow: 'hidden',
            marginBottom: 16,
          }}
        >
          {/* Amount */}
          <div style={{
            background: 'linear-gradient(135deg, #D97757, #B85C3A)',
            padding: '20px 24px',
            textAlign: 'center',
          }}>
            <p style={{
              fontSize: 11, fontWeight: 700,
              fontFamily: 'Inter',
              color: 'rgba(255,255,255,0.7)',
              letterSpacing: '2px',
              textTransform: 'uppercase',
              margin: '0 0 4px',
            }}>
              Amount Paid
            </p>
            <p style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 44, fontWeight: 800,
              color: 'white', margin: 0, letterSpacing: -2,
            }}>
              ₹{policy.price || policy.weeklyPremium || policy.weekly_premium || 58}
            </p>
          </div>

          {/* Receipt details */}
          <div style={{ padding: '16px 20px' }}>
            {[
              {
                icon: Hash,
                label: 'Receipt ID',
                value: receiptId,
                mono: true,
              },
              {
                icon: Shield,
                label: 'Plan',
                value: `${policy.planName || policy.plan_name || 'Standard'} — ₹600/week coverage`,
              },
              {
                icon: Calendar,
                label: 'Valid',
                value: `${formatDate(policy.weekStart || policy.week_start)} — ${formatDate(policy.weekEnd || policy.week_end)}`,
              },
            ].map((row, i, arr) => (
              <div key={i} style={{
                display: 'flex',
                alignItems: 'flex-start', gap: 12,
                paddingBottom: i < arr.length - 1 ? 12 : 0,
                marginBottom: i < arr.length - 1 ? 12 : 0,
                borderBottom: i < arr.length - 1
                  ? '1px solid var(--border-light)' : 'none',
              }}>
                <div style={{
                  width: 32, height: 32,
                  borderRadius: 8,
                  background: 'var(--bg-secondary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <row.icon size={14} color="var(--text-tertiary)"/>
                </div>
                <div>
                  <p style={{
                    fontSize: 11, fontFamily: 'Inter',
                    color: 'var(--text-tertiary)',
                    margin: '0 0 2px', fontWeight: 600,
                  }}>
                    {row.label}
                  </p>
                  <p style={{
                    fontSize: row.mono ? 11 : 13,
                    fontFamily: row.mono ? 'monospace' : 'Inter',
                    color: 'var(--text-primary)',
                    margin: 0, fontWeight: 600,
                  }}>
                    {row.value}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {/* Confirmed badge */}
          <div style={{
            background: 'rgba(18,183,106,0.06)',
            borderTop: '1px solid rgba(18,183,106,0.15)',
            padding: '10px 20px',
            display: 'flex',
            alignItems: 'center', gap: 8,
          }}>
            <div style={{
              width: 6, height: 6,
              borderRadius: 999, background: '#12B76A',
            }}/>
            <span style={{
              fontSize: 12, fontWeight: 600,
              fontFamily: 'Inter', color: '#12B76A',
            }}>
              Payment confirmed · Razorpay Test Mode
            </span>
          </div>
        </div>

        {/* Action buttons */}
        <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
          <motion.button
            onClick={handleDownloadReceipt}
            whileTap={{ scale: 0.97 }}
            style={{
              flex: 1, padding: '12px',
              borderRadius: 12,
              border: '1.5px solid var(--border)',
              background: 'var(--bg-card)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center', gap: 7,
              fontSize: 13, fontWeight: 600,
              fontFamily: 'Inter',
              color: 'var(--text-primary)',
            }}
          >
            <Download size={15}/>
            Receipt
          </motion.button>

          <motion.button
            onClick={() => navigate('/dashboard')}
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.97 }}
            style={{
              flex: 2, padding: '12px',
              borderRadius: 12, border: 'none',
              background: 'linear-gradient(135deg, #D97757, #B85C3A)',
              cursor: 'pointer',
              fontSize: 14, fontWeight: 700,
              fontFamily: 'Bricolage Grotesque',
              color: 'white',
              boxShadow: '0 4px 20px rgba(217,119,87,0.35)',
            }}
          >
            Go to Dashboard →
          </motion.button>
        </div>

        <p style={{
          textAlign: 'center',
          fontSize: 11, fontFamily: 'Inter',
          color: 'var(--text-tertiary)', margin: 0,
        }}>
          GuidePay · Team SentinelX · KL University<br/>
          Competition demo — test mode payment
        </p>
      </motion.div>
    </div>
  )
}

export default PaymentSuccess
