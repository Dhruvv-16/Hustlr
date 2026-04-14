import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { useParams, useNavigate } from 'react-router-dom'
import { useWorkerStore } from '../../store/workerStore'
import { CheckCircle, Download, ArrowLeft } from 'lucide-react'
import { shareOnWhatsApp } from '../../utils/whatsappShare'

const PayoutReceipt = () => {
  const { claimId } = useParams()
  const navigate = useNavigate()
  const worker = useWorkerStore(s => s.worker)
  const activePolicy = useWorkerStore(s => s.activePolicy)
  const claims = useWorkerStore(s => s.claims)
  const language = useWorkerStore(s => s.language) || 'en'
  const [claim, setClaim] = useState(null)
  const [paying, setPaying] = useState(false)
  const [paid, setPaid] = useState(false)
  const [payoutData, setPayoutData] = useState(null)

  useEffect(() => {
    // Must have an active policy to access payout
    const hasPolicy = !!(activePolicy && activePolicy.status === 'ACTIVE')
    if (!hasPolicy) {
      navigate('/coverage', { replace: true })
      return
    }

    const found = claims.find(
      c => (c.id || c._id) === claimId
    )
    if (found) {
      setClaim(found)
      if (found.status === 'PAID') {
        setPaid(true)
        if (found.razorpay_payout_id || found.upi_transaction_id) {
          setPayoutData({
            payout_id: found.razorpay_payout_id,
            transaction_id: found.upi_transaction_id,
            upi_id: found.upi_id,
            amount: found.amount,
            status: 'PROCESSED',
            processed_at: found.paid_at,
          })
        }
      }
    } else {
      navigate('/claims', { replace: true })
    }
  }, [claimId, claims, activePolicy])

  const handleSimulatePayout = async () => {
    setPaying(true)
    try {
      const upiId = worker?.upi_id
        || `${worker?.phone || '9876543210'}@upi`

      const USE_MOCK =
        import.meta.env.VITE_USE_MOCK === 'true'

      if (!USE_MOCK) {
        const token = localStorage.getItem('gp-token')
        const res = await fetch(
          `${import.meta.env.VITE_API_URL}/api/v1/payments/simulate-payout`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
              claim_id: claimId,
              upi_id: upiId,
            }),
          }
        )
        const data = await res.json()
        if (data.payout) {
          setPayoutData(data.payout)
        }
      } else {
        await new Promise(r => setTimeout(r, 2000))
        setPayoutData({
          payout_id: `pout_TEST_${Date.now().toString().slice(-10)}`,
          transaction_id: `IMPS${Date.now().toString().slice(-15).toUpperCase()}`,
          upi_id: upiId,
          amount: claim?.amount || 600,
          status: 'PROCESSED',
          processed_at: new Date().toISOString(),
        })
      }

      setPaid(true)
    } catch (e) {
      console.error('Payout error:', e)
    } finally {
      setPaying(false)
    }
  }

  const downloadReceipt = () => {
    if (!payoutData && !claim) return

    const amount = claim?.amount || 600
    const txnId = payoutData?.transaction_id
      || claim?.upi_transaction_id
      || 'PENDING'

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>GuidePay Payout Receipt</title>
        <style>
          body { font-family: Arial, sans-serif;
                 max-width: 400px; margin: 40px auto; }
          .header { text-align: center;
                    border-bottom: 3px solid #12B76A;
                    padding-bottom: 20px;
                    margin-bottom: 20px; }
          .amount { font-size: 40px; font-weight: 800;
                    color: #12B76A; text-align: center;
                    margin: 20px 0; }
          .badge { background: #12B76A; color: white;
                   padding: 4px 12px; border-radius: 20px;
                   font-size: 12px; display: inline-block; }
          .row { display: flex;
                 justify-content: space-between;
                 padding: 8px 0;
                 border-bottom: 1px solid #f0f0f0; }
          .label { color: #666; font-size: 12px; }
          .value { font-weight: 600; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="header">
          <div style="font-size:22px; font-weight:800; color:#D97757;">GuidePay</div>
          <div class="badge">✓ PAYOUT RECEIPT</div>
        </div>
        <div class="amount">₹${amount}</div>
        <div class="row">
          <span class="label">Worker</span>
          <span class="value">${worker?.name || 'Ravi Kumar'}</span>
        </div>
        <div class="row">
          <span class="label">UPI ID</span>
          <span class="value">${payoutData?.upi_id || '98765xxxxx@upi'}</span>
        </div>
        <div class="row">
          <span class="label">Transaction ID</span>
          <span class="value" style="font-size:10px;">${txnId}</span>
        </div>
        <div class="row">
          <span class="label">Trigger Type</span>
          <span class="value">${claim?.trigger_type || 'FLOOD'}</span>
        </div>
        <div class="row">
          <span class="label">Payout ID</span>
          <span class="value" style="font-size:10px;">
            ${payoutData?.payout_id || claim?.razorpay_payout_id || 'PROCESSED'}
          </span>
        </div>
        <div class="row">
          <span class="label">Date & Time</span>
          <span class="value">${new Date().toLocaleString('en-IN')}</span>
        </div>
        <div style="text-align:center; margin-top:20px; color:#999; font-size:11px;">
          GuidePay · Razorpay Test Mode<br/>
          Team SentinelX · Guidewire DEVTrails 2026
        </div>
      </body>
      </html>
    `

    const blob = new Blob([html], { type: 'text/html' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `GuidePay-Payout-${txnId}.html`
    a.click()
    URL.revokeObjectURL(url)
  }

  if (!claim) {
    return (
      <div style={{
        minHeight: '100vh',
        background: 'var(--bg-secondary)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
      }}>
        <p style={{
          fontFamily: 'Inter',
          color: 'var(--text-tertiary)',
          fontSize: 14,
        }}>
          Loading claim...
        </p>
      </div>
    )
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--bg-secondary)',
      padding: 20,
    }}>
      <button
        onClick={() => navigate(-1)}
        style={{
          background: 'none', border: 'none',
          cursor: 'pointer', padding: 0,
          marginBottom: 20, display: 'flex',
          alignItems: 'center', gap: 6,
          fontSize: 13, fontFamily: 'Inter',
          color: 'var(--text-secondary)',
        }}
      >
        <ArrowLeft size={16}/>
        Back to Claim
      </button>

      {paid ? (
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          style={{ maxWidth: 400, margin: '0 auto' }}
        >
          <div style={{ textAlign: 'center', marginBottom: 24 }}>
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 400 }}
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
              <CheckCircle size={40} color="#12B76A"/>
            </motion.div>
            <h1 style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 26, fontWeight: 800,
              color: 'var(--text-primary)',
              margin: '0 0 6px',
            }}>
              Payout Complete!
            </h1>
            <p style={{
              fontSize: 14, fontFamily: 'Inter',
              color: 'var(--text-secondary)', margin: 0,
            }}>
              ₹{claim.amount} sent to your UPI
            </p>
          </div>

          <div style={{
            marginTop: '0px',
            marginBottom: '24px',
            padding: '16px',
            background: 'linear-gradient(135deg, #25D366 0%, #128C7E 100%)',
            borderRadius: '12px',
            textAlign: 'center',
            cursor: 'pointer',
          }} onClick={() => shareOnWhatsApp({
            workerName: worker?.name || 'I',
            amount: claim.amount,
            city: worker?.city || 'my city',
            zone: worker?.zone || 'my zone',
            language: language,
          })}>
            <div style={{ fontSize: '24px', marginBottom: '6px' }}>📲</div>
            <div style={{ 
              color: 'white', 
              fontWeight: '700', 
              fontSize: '15px',
              marginBottom: '4px' 
            }}>
              Share on WhatsApp
            </div>
            <div style={{ 
              color: 'rgba(255,255,255,0.85)', 
              fontSize: '12px' 
            }}>
              Tell your delivery friends about GuidePay
            </div>
          </div>

          <div style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 20,
            overflow: 'hidden',
            marginBottom: 16,
          }}>
            <div style={{
              background: 'linear-gradient(135deg, #12B76A, #0A9456)',
              padding: '20px 24px',
              textAlign: 'center',
            }}>
              <p style={{
                fontSize: 11, fontWeight: 700,
                fontFamily: 'Inter',
                color: 'rgba(255,255,255,0.7)',
                textTransform: 'uppercase',
                letterSpacing: '2px',
                margin: '0 0 4px',
              }}>
                Amount Credited
              </p>
              <p style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 48, fontWeight: 800,
                color: 'white', margin: 0, letterSpacing: -2,
              }}>
                ₹{claim.amount}
              </p>
            </div>

            <div style={{ padding: '16px 20px' }}>
              {[
                {
                  label: 'UPI ID',
                  value: payoutData?.upi_id
                    || worker?.upi_id
                    || '98765xxxxx@upi',
                },
                {
                  label: 'Transaction ID',
                  value: payoutData?.transaction_id
                    || claim.upi_transaction_id
                    || 'IMPS...',
                  mono: true,
                },
                {
                  label: 'Payout ID',
                  value: payoutData?.payout_id
                    || claim.razorpay_payout_id
                    || 'pout_TEST...',
                  mono: true,
                },
                {
                  label: 'Mode',
                  value: 'UPI · Instant Transfer',
                },
                {
                  label: 'Status',
                  value: '✓ Processed',
                  color: '#12B76A',
                },
              ].map((row, i, arr) => (
                <div key={i} style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  padding: '10px 0',
                  borderBottom: i < arr.length - 1
                    ? '1px solid var(--border-light)' : 'none',
                }}>
                  <span style={{
                    fontSize: 12, fontFamily: 'Inter',
                    color: 'var(--text-tertiary)',
                  }}>
                    {row.label}
                  </span>
                  <span style={{
                    fontSize: row.mono ? 10 : 12,
                    fontFamily: row.mono ? 'monospace' : 'Inter',
                    fontWeight: 600,
                    color: row.color || 'var(--text-primary)',
                    maxWidth: '60%',
                    textAlign: 'right',
                    wordBreak: 'break-all',
                  }}>
                    {row.value}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', gap: 10 }}>
            <motion.button
              onClick={downloadReceipt}
              whileTap={{ scale: 0.97 }}
              style={{
                flex: 1, padding: '13px',
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
              whileTap={{ scale: 0.97 }}
              style={{
                flex: 2, padding: '13px',
                borderRadius: 12, border: 'none',
                background: '#12B76A',
                cursor: 'pointer',
                fontSize: 14, fontWeight: 700,
                fontFamily: 'Bricolage Grotesque',
                color: 'white',
              }}
            >
              Dashboard →
            </motion.button>
          </div>
        </motion.div>
      ) : (
        <div style={{
          maxWidth: 400, margin: '0 auto', textAlign: 'center',
        }}>
          <h1 style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 24, fontWeight: 800,
            color: 'var(--text-primary)',
            margin: '0 0 8px',
          }}>
            Initiate UPI Payout
          </h1>
          <p style={{
            fontSize: 14, fontFamily: 'Inter',
            color: 'var(--text-secondary)',
            margin: '0 0 24px',
          }}>
            ₹{claim.amount} will be sent to your registered UPI ID
          </p>

          <div style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 16, padding: 20,
            marginBottom: 20, textAlign: 'left',
          }}>
            <p style={{
              fontSize: 11, fontWeight: 700,
              fontFamily: 'Inter',
              color: 'var(--text-tertiary)',
              textTransform: 'uppercase',
              letterSpacing: '1.5px',
              margin: '0 0 12px',
            }}>
              Payout Details
            </p>
            {[
              { label: 'Amount', value: `₹${claim.amount}` },
              { label: 'Trigger', value: claim.trigger_type },
              { label: 'UPI ID', value: worker?.upi_id || `${worker?.phone || '9876543210'}@upi` },
              { label: 'Mode', value: 'Instant UPI Transfer' },
            ].map((row, i) => (
              <div key={i} style={{
                display: 'flex',
                justifyContent: 'space-between',
                padding: '8px 0',
                borderBottom: '1px solid var(--border-light)',
              }}>
                <span style={{
                  fontSize: 13, fontFamily: 'Inter',
                  color: 'var(--text-tertiary)',
                }}>
                  {row.label}
                </span>
                <span style={{
                  fontSize: 13, fontFamily: 'Inter',
                  fontWeight: 700,
                  color: 'var(--text-primary)',
                }}>
                  {row.value}
                </span>
              </div>
            ))}
          </div>

          <motion.button
            onClick={handleSimulatePayout}
            disabled={paying}
            whileHover={!paying ? { scale: 1.01 } : {}}
            whileTap={!paying ? { scale: 0.97 } : {}}
            style={{
              width: '100%', padding: '16px',
              borderRadius: 14, border: 'none',
              background: paying
                ? 'var(--bg-tertiary)'
                : 'linear-gradient(135deg, #12B76A, #0A9456)',
              color: paying ? 'var(--text-tertiary)' : 'white',
              fontSize: 16, fontWeight: 700,
              fontFamily: 'Bricolage Grotesque',
              cursor: paying ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center', gap: 10,
              boxShadow: paying
                ? 'none'
                : '0 4px 20px rgba(18,183,106,0.35)',
            }}
          >
            {paying ? (
              <>
                <div style={{
                  width: 18, height: 18,
                  border: '2px solid var(--text-tertiary)',
                  borderTopColor: 'transparent',
                  borderRadius: 999,
                  animation: 'spin 0.8s linear infinite',
                }}/>
                Processing UPI Transfer...
              </>
            ) : (
              <>💰 Send ₹{claim.amount} to UPI</>
            )}
          </motion.button>

          <p style={{
            marginTop: 12, fontSize: 11,
            fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
          }}>
            Razorpay Test Mode · No real money
          </p>
        </div>
      )}
    </div>
  )
}

export default PayoutReceipt
