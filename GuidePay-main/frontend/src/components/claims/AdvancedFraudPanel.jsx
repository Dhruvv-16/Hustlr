import { motion } from 'framer-motion'
import { Shield, MapPin, Cloud,
  AlertTriangle, CheckCircle } from 'lucide-react'

export const AdvancedFraudPanel = ({ claim }) => {
  const checks = claim?.fraud_checks || {}

  const GPS_CHECKS = [
    {
      key: 'zone_boundary',
      label: 'Zone Boundary Check',
      icon: '📍',
      description: 'Worker GPS within registered zone',
    },
    {
      key: 'movement_speed',
      label: 'Movement Speed Check',
      icon: '🏍️',
      description: 'Movement speed physically possible',
    },
    {
      key: 'cluster_spoofing',
      label: 'Cluster Spoofing Check',
      icon: '🕵️',
      description: 'No other workers at same GPS point',
    },
    {
      key: 'gps_spoofing',
      label: 'GPS Spoofing Analysis',
      icon: '📡',
      description: 'Advanced pattern analysis',
    },
  ]

  const WEATHER_CHECKS = [
    {
      key: 'weather_validation',
      label: 'Weather Event Confirmed',
      icon: '🌧️',
      description: 'Cross-validated with IMD + OWM',
    },
    {
      key: 'zone_correlation',
      label: 'Zone Correlation',
      icon: '👥',
      description: 'Multiple workers in same zone affected',
    },
  ]

  const getCheckStatus = (checkData) => {
    if (!checkData) return 'unknown'
    if (checkData.confirmed === true
        || checkData.decision === 'WEATHER_CONFIRMED'
        || (checkData.flag === false
            && checkData.flag !== undefined)
        || checkData.reason === 'WITHIN_ZONE'
        || checkData.reason === 'NORMAL_MOVEMENT') {
      return 'pass'
    }
    if (checkData.flag === true
        || checkData.decision === 'WEATHER_UNCONFIRMED'
        || checkData.gps_spoofing_detected) {
      return 'fail'
    }
    return 'warning'
  }

  const STATUS_CONFIG = {
    pass: {
      color: '#12B76A',
      bg: 'rgba(18,183,106,0.08)',
      icon: '✓',
    },
    fail: {
      color: '#F04438',
      bg: 'rgba(240,68,56,0.08)',
      icon: '✗',
    },
    warning: {
      color: '#F79009',
      bg: 'rgba(247,144,9,0.08)',
      icon: '⚠',
    },
    unknown: {
      color: '#6B6B6B',
      bg: 'rgba(107,107,107,0.08)',
      icon: '?',
    },
  }

  const fraudScore = claim?.fraud_score || 0
  const scorePercent = Math.round(fraudScore * 100)

  return (
    <div style={{
      background: 'var(--bg-card)',
      border: '1px solid var(--border)',
      borderRadius: 16,
      overflow: 'hidden',
      marginTop: 12,
    }}>
      {/* Header */}
      <div style={{
        background: fraudScore < 0.30
          ? 'rgba(18,183,106,0.06)'
          : fraudScore < 0.70
          ? 'rgba(247,144,9,0.06)'
          : 'rgba(240,68,56,0.06)',
        borderBottom: '1px solid var(--border-light)',
        padding: '14px 18px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center', gap: 8,
        }}>
          <Shield size={16} color={
            fraudScore < 0.30 ? '#12B76A'
            : fraudScore < 0.70 ? '#F79009'
            : '#F04438'
          }/>
          <span style={{
            fontSize: 13, fontWeight: 700,
            fontFamily: 'Inter',
            color: 'var(--text-primary)',
          }}>
            Advanced Fraud Analysis v3
          </span>
        </div>
        <div style={{
          textAlign: 'right',
        }}>
          <p style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 20, fontWeight: 800,
            color: fraudScore < 0.30 ? '#12B76A'
              : fraudScore < 0.70 ? '#F79009'
              : '#F04438',
            margin: 0,
          }}>
            {scorePercent}%
          </p>
          <p style={{
            fontSize: 9, fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
            margin: 0, fontWeight: 600,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
          }}>
            Fraud Risk Score
          </p>
        </div>
      </div>

      <div style={{ padding: 18 }}>

        {/* GPS Checks Section */}
        <p style={{
          fontSize: 10, fontWeight: 700,
          fontFamily: 'Inter',
          color: 'var(--text-tertiary)',
          letterSpacing: '2px',
          textTransform: 'uppercase',
          margin: '0 0 10px',
        }}>
          GPS Spoofing Detection
        </p>

        <div style={{
          display: 'flex',
          flexDirection: 'column', gap: 6,
          marginBottom: 16,
        }}>
          {GPS_CHECKS.map(check => {
            const checkData = checks[check.key]
            const status = getCheckStatus(checkData)
            const config = STATUS_CONFIG[status]

            return (
              <div key={check.key} style={{
                display: 'flex',
                alignItems: 'center', gap: 10,
                padding: '9px 12px',
                background: config.bg,
                borderRadius: 10,
                border: `1px solid ${config.color}20`,
              }}>
                <span style={{ fontSize: 16 }}>
                  {check.icon}
                </span>
                <div style={{ flex: 1 }}>
                  <p style={{
                    fontSize: 12, fontWeight: 600,
                    fontFamily: 'Inter',
                    color: 'var(--text-primary)',
                    margin: 0,
                  }}>
                    {check.label}
                  </p>
                  <p style={{
                    fontSize: 10, fontFamily: 'Inter',
                    color: 'var(--text-tertiary)',
                    margin: 0,
                  }}>
                    {checkData?.reason
                      || checkData?.note
                      || check.description}
                  </p>
                </div>
                <span style={{
                  fontSize: 14, fontWeight: 800,
                  color: config.color,
                }}>
                  {config.icon}
                </span>
              </div>
            )
          })}
        </div>

        {/* Weather Validation Section */}
        <p style={{
          fontSize: 10, fontWeight: 700,
          fontFamily: 'Inter',
          color: 'var(--text-tertiary)',
          letterSpacing: '2px',
          textTransform: 'uppercase',
          margin: '0 0 10px',
        }}>
          Historical Weather Validation
        </p>

        <div style={{
          display: 'flex',
          flexDirection: 'column', gap: 6,
        }}>
          {WEATHER_CHECKS.map(check => {
            const checkData = checks[check.key]
              || checks['weather_validation']
            const status = getCheckStatus(checkData)
            const config = STATUS_CONFIG[status]

            return (
              <div key={check.key} style={{
                display: 'flex',
                alignItems: 'center', gap: 10,
                padding: '9px 12px',
                background: config.bg,
                borderRadius: 10,
                border: `1px solid ${config.color}20`,
              }}>
                <span style={{ fontSize: 16 }}>
                  {check.icon}
                </span>
                <div style={{ flex: 1 }}>
                  <p style={{
                    fontSize: 12, fontWeight: 600,
                    fontFamily: 'Inter',
                    color: 'var(--text-primary)',
                    margin: 0,
                  }}>
                    {check.label}
                  </p>
                  <p style={{
                    fontSize: 10, fontFamily: 'Inter',
                    color: 'var(--text-tertiary)',
                    margin: 0,
                  }}>
                    {checkData?.decision
                      || checkData?.note
                      || check.description}
                    {checkData?.confirmed_sources != null
                      && ` (${checkData.confirmed_sources}/${checkData.total_sources} sources confirmed)`}
                  </p>
                </div>
                <span style={{
                  fontSize: 14, fontWeight: 800,
                  color: config.color,
                }}>
                  {config.icon}
                </span>
              </div>
            )
          })}
        </div>

        {/* Fraud version tag */}
        <div style={{
          marginTop: 12,
          display: 'flex',
          justifyContent: 'flex-end',
        }}>
          <span style={{
            fontSize: 9, fontWeight: 700,
            fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
            background: 'var(--bg-secondary)',
            padding: '2px 8px',
            borderRadius: 999,
            letterSpacing: '1px',
          }}>
            FRAUD ENGINE v3 · 9 SIGNALS
          </span>
        </div>
      </div>
    </div>
  )
}
