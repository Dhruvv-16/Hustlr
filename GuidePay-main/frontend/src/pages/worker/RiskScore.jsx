import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, TrendingUp, TrendingDown } from 'lucide-react'
import { useWorkerStore } from '../../store/workerStore'

const RiskScore = () => {
  const navigate = useNavigate()
  const worker = useWorkerStore(s => s.worker)
  const riskScore = useWorkerStore(s => s.riskScore)
    || worker?.risk_score || 0.82
  const zone = worker?.zone || 'kondapur-hyderabad'

  // Premium breakdown calculation
  const BASE = 49
  const zoneMultiplier = {
    'kondapur-hyderabad': 1.18,
    'kurla-mumbai': 1.22,
    'tnagar-chennai': 1.08,
    'koramangala-bengaluru': 0.92,
    'dwarka-delhi': 0.95,
  }[zone] || 1.0

  const workerMultiplier = riskScore > 0.75
    ? 0.85 : riskScore >= 0.50 ? 1.00 : 1.15

  const zoneAdj = Math.round(BASE * (zoneMultiplier - 1))
  const workerAdj = Math.round(
    BASE * zoneMultiplier * (workerMultiplier - 1)
  )
  const total = Math.round(
    BASE * zoneMultiplier * workerMultiplier
  )

  const scorePercent = Math.round(riskScore * 100)

  // Score segments
  const segments = [
    { label: 'Delivery history', value: 35,
      filled: Math.round(riskScore * 35),
      tip: 'Complete more deliveries to improve' },
    { label: 'Zone consistency', value: 25,
      filled: Math.round(riskScore * 25),
      tip: 'Stay in your registered zone' },
    { label: 'Claim history', value: 25,
      filled: 22,
      tip: 'Clean claim history maintained' },
    { label: 'Account age', value: 15,
      filled: Math.round(riskScore * 15),
      tip: 'Score improves with account age' },
  ]

  const improvements = [
    { action: 'Complete 10 more deliveries this week',
      impact: '-₹2 premium' },
    { action: 'Stay in Kondapur zone consistently',
      impact: '-₹1 premium' },
    { action: 'No fraudulent claims',
      impact: 'Score protected' },
  ]

  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--bg-secondary)',
      paddingBottom: 40,
    }}>
      {/* TopBar */}
      <div style={{
        background: 'var(--bg-card)',
        borderBottom: '1px solid var(--border-light)',
        padding: '16px',
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        position: 'sticky', top: 0, zIndex: 50,
      }}>
        <button onClick={() => navigate(-1)}
          style={{ background: 'none', border: 'none',
            cursor: 'pointer', padding: 0 }}>
          <ArrowLeft size={22}
            color="var(--text-primary)"/>
        </button>
        <h1 style={{
          fontFamily: 'Bricolage Grotesque',
          fontSize: 18, fontWeight: 800,
          color: 'var(--text-primary)', margin: 0,
        }}>
          Your Risk Score
        </h1>
      </div>

      <div style={{ padding: 16 }}>

        {/* Score gauge */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 16,
          padding: 24,
          textAlign: 'center',
          marginBottom: 12,
          border: '1px solid var(--border)',
        }}>
          <div style={{
            width: 120, height: 120,
            borderRadius: 999,
            background: `conic-gradient(
              #12B76A ${scorePercent * 3.6}deg,
              var(--bg-secondary) 0deg
            )`,
            margin: '0 auto 16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            position: 'relative',
          }}>
            <div style={{
              width: 88, height: 88,
              borderRadius: 999,
              background: 'var(--bg-card)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexDirection: 'column',
            }}>
              <p style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 28, fontWeight: 800,
                color: '#12B76A', margin: 0,
                lineHeight: 1,
              }}>
                {scorePercent}
              </p>
              <p style={{
                fontSize: 10, fontFamily: 'Inter',
                color: 'var(--text-tertiary)',
                margin: 0,
              }}>
                /100
              </p>
            </div>
          </div>

          <p style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 18, fontWeight: 700,
            color: 'var(--text-primary)',
            margin: '0 0 4px',
          }}>
            {riskScore > 0.75 ? 'Trusted Worker'
              : riskScore > 0.50 ? 'Good Standing'
              : 'Building Trust'}
          </p>
          <p style={{
            fontSize: 13, fontFamily: 'Inter',
            color: 'var(--text-secondary)', margin: 0,
          }}>
            Your score qualifies you for
            {riskScore > 0.75 ? ' reduced' : ' standard'} premium
          </p>
        </div>

        {/* Premium breakdown */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 16,
          padding: 18,
          marginBottom: 12,
          border: '1px solid var(--border)',
        }}>
          <p style={{
            fontSize: 11, fontWeight: 700,
            fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
            letterSpacing: '2px',
            textTransform: 'uppercase',
            margin: '0 0 14px',
          }}>
            Premium Breakdown
          </p>

          {[
            { label: 'Base premium', value: `₹${BASE}`,
              sub: 'Standard rate for all workers' },
            { label: 'Zone adjustment',
              value: zoneAdj >= 0
                ? `+₹${zoneAdj}` : `-₹${Math.abs(zoneAdj)}`,
              sub: `${worker?.city || 'Hyderabad'} flood risk`,
              color: zoneAdj > 0 ? '#F04438' : '#12B76A' },
            { label: 'Your score',
              value: workerAdj >= 0
                ? `+₹${workerAdj}` : `-₹${Math.abs(workerAdj)}`,
              sub: riskScore > 0.75
                ? 'Trusted worker discount'
                : 'Standard worker rate',
              color: workerAdj > 0 ? '#F04438' : '#12B76A' },
          ].map((row, i) => (
            <div key={i} style={{
              display: 'flex',
              justifyContent: 'space-between',
              padding: '10px 0',
              borderBottom: '1px solid var(--border-light)',
            }}>
              <div>
                <p style={{
                  fontSize: 14, fontWeight: 600,
                  fontFamily: 'Inter',
                  color: 'var(--text-primary)', margin: 0,
                }}>
                  {row.label}
                </p>
                <p style={{
                  fontSize: 11, fontFamily: 'Inter',
                  color: 'var(--text-tertiary)',
                  margin: '2px 0 0',
                }}>
                  {row.sub}
                </p>
              </div>
              <p style={{
                fontFamily: 'Bricolage Grotesque',
                fontSize: 18, fontWeight: 800,
                color: row.color || 'var(--text-primary)',
                margin: 0, alignSelf: 'center',
              }}>
                {row.value}
              </p>
            </div>
          ))}

          {/* Total */}
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            paddingTop: 12,
          }}>
            <p style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 16, fontWeight: 800,
              color: 'var(--text-primary)', margin: 0,
            }}>
              Your weekly premium
            </p>
            <p style={{
              fontFamily: 'Bricolage Grotesque',
              fontSize: 24, fontWeight: 800,
              color: '#D97757', margin: 0,
            }}>
              ₹{total}
            </p>
          </div>
        </div>

        {/* Score breakdown bars */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 16,
          padding: 18,
          marginBottom: 12,
          border: '1px solid var(--border)',
        }}>
          <p style={{
            fontSize: 11, fontWeight: 700,
            fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
            letterSpacing: '2px',
            textTransform: 'uppercase',
            margin: '0 0 14px',
          }}>
            Score Components
          </p>
          {segments.map(seg => (
            <div key={seg.label} style={{
              marginBottom: 14,
            }}>
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                marginBottom: 5,
              }}>
                <span style={{
                  fontSize: 12, fontFamily: 'Inter',
                  color: 'var(--text-secondary)',
                  fontWeight: 600,
                }}>
                  {seg.label}
                </span>
                <span style={{
                  fontSize: 12, fontFamily: 'Inter',
                  color: 'var(--text-tertiary)',
                }}>
                  {seg.filled}/{seg.value}
                </span>
              </div>
              <div style={{
                height: 6,
                background: 'var(--bg-secondary)',
                borderRadius: 999,
                overflow: 'hidden',
              }}>
                <motion.div
                  initial={{ width: 0 }}
                  animate={{
                    width: `${(seg.filled/seg.value)*100}%`
                  }}
                  transition={{ delay: 0.2, duration: 0.6 }}
                  style={{
                    height: '100%',
                    background: '#12B76A',
                    borderRadius: 999,
                  }}
                />
              </div>
              <p style={{
                fontSize: 10, fontFamily: 'Inter',
                color: 'var(--text-tertiary)',
                margin: '3px 0 0',
              }}>
                {seg.tip}
              </p>
            </div>
          ))}
        </div>

        {/* How to improve */}
        <div style={{
          background: 'rgba(18,183,106,0.06)',
          border: '1px solid rgba(18,183,106,0.2)',
          borderRadius: 14,
          padding: 16,
        }}>
          <p style={{
            fontSize: 12, fontWeight: 700,
            fontFamily: 'Inter', color: '#12B76A',
            letterSpacing: '1px',
            textTransform: 'uppercase',
            margin: '0 0 10px',
          }}>
            How to lower your premium
          </p>
          {improvements.map((item, i) => (
            <div key={i} style={{
              display: 'flex',
              justifyContent: 'space-between',
              padding: '8px 0',
              borderBottom: i < improvements.length - 1
                ? '1px solid rgba(18,183,106,0.1)'
                : 'none',
            }}>
              <p style={{
                fontSize: 12, fontFamily: 'Inter',
                color: 'var(--text-secondary)',
                margin: 0, flex: 1, lineHeight: 1.4,
              }}>
                {item.action}
              </p>
              <span style={{
                fontSize: 12, fontWeight: 700,
                fontFamily: 'Inter', color: '#12B76A',
                marginLeft: 12, flexShrink: 0,
              }}>
                {item.impact}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default RiskScore
