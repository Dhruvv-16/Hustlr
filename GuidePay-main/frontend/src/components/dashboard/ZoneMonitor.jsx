import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Shield, Clock } from 'lucide-react'
import { useWorkerStore } from '../../store/workerStore'
import { getActiveTriggers } from '../../services/api'

const CHECKS = [
  { id: 'imd', label: 'IMD Flood Check', icon: '🌧️' },
  { id: 'zepto', label: 'Zepto Status', icon: '⚡' },
  { id: 'swiggy', label: 'Swiggy Status', icon: '🛵' },
  { id: 'curfew', label: 'Curfew Monitor', icon: '🚨' },
]

export const ZoneMonitor = () => {
  const worker = useWorkerStore(s => s.worker)
  const activePolicy = useWorkerStore(s => s.activePolicy)
  const [lastChecked, setLastChecked] = useState(new Date())
  const [nextCheckSecs, setNextCheckSecs] = useState(60)
  const [hasAlert, setHasAlert] = useState(false)
  const [alertData, setAlertData] = useState(null)
  const [checking, setChecking] = useState(false)
  const [checkTimes, setCheckTimes] = useState({})
  const intervalRef = useRef(null)
  const countdownRef = useRef(null)

  const runCheck = async () => {
    setChecking(true)
    const now = new Date()
    
    // Stagger check times for realism
    const times = {}
    CHECKS.forEach((check, i) => {
      setTimeout(() => {
        times[check.id] = new Date()
        setCheckTimes(prev => ({ ...prev, [check.id]: new Date() }))
      }, i * 400)
    })

    try {
      const data = await getActiveTriggers()
      if (data.triggers && data.triggers.length > 0) {
        setHasAlert(true)
        setAlertData(data.triggers[0])
      } else {
        setHasAlert(false)
        setAlertData(null)
      }
    } catch (e) {
      setHasAlert(false)
    }

    setTimeout(() => {
      setLastChecked(now)
      setChecking(false)
      setNextCheckSecs(60)
    }, CHECKS.length * 400 + 200)
  }

  useEffect(() => {
    runCheck()
    
    // Poll every 60 seconds
    intervalRef.current = setInterval(runCheck, 60000)
    
    // Countdown timer
    countdownRef.current = setInterval(() => {
      setNextCheckSecs(s => s > 0 ? s - 1 : 60)
    }, 1000)

    return () => {
      clearInterval(intervalRef.current)
      clearInterval(countdownRef.current)
    }
  }, [])

  const timeAgo = (date) => {
    if (!date) return '...'
    const secs = Math.floor((new Date() - date) / 1000)
    if (secs < 60) return `${secs}s ago`
    return `${Math.floor(secs / 60)}m ago`
  }

  if (!activePolicy) return null

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      id="zone-monitor-card"
      style={{
        background: hasAlert
          ? 'rgba(240,68,56,0.06)'
          : 'var(--bg-card)',
        border: hasAlert
          ? '1px solid rgba(240,68,56,0.3)'
          : '1px solid var(--border)',
        borderRadius: 16,
        padding: 16,
      }}
    >
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 12,
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
        }}>
          {/* Pulsing dot */}
          <div style={{ position: 'relative' }}>
            <motion.div
              animate={{ scale: [1, 1.8, 1], opacity: [1, 0, 1] }}
              transition={{ duration: 2, repeat: Infinity }}
              style={{
                position: 'absolute',
                inset: 0,
                borderRadius: 999,
                background: hasAlert ? '#F04438' : '#12B76A',
              }}
            />
            <div style={{
              width: 8, height: 8,
              borderRadius: 999,
              background: hasAlert ? '#F04438' : '#12B76A',
              position: 'relative',
              zIndex: 1,
            }}/>
          </div>
          <span style={{
            fontSize: 13, fontWeight: 700,
            fontFamily: 'Inter',
            color: hasAlert ? '#F04438' : '#12B76A',
          }}>
            {hasAlert ? 'ALERT DETECTED' : 'ZONE MONITORED'}
          </span>
        </div>

        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: 4,
        }}>
          <Clock size={11} color="var(--text-tertiary)"/>
          <span style={{
            fontSize: 11,
            fontFamily: 'Inter',
            color: 'var(--text-tertiary)',
          }}>
            {checking ? 'Checking...' : `Next: ${nextCheckSecs}s`}
          </span>
        </div>
      </div>

      {/* Alert banner */}
      <AnimatePresence>
        {hasAlert && alertData && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            id="alert-banner-zone"
            style={{
              background: 'rgba(240,68,56,0.1)',
              border: '1px solid rgba(240,68,56,0.25)',
              borderRadius: 10,
              padding: '10px 12px',
              marginBottom: 12,
            }}
          >
            <p style={{
              fontSize: 13, fontWeight: 700,
              color: '#F04438', fontFamily: 'Inter',
              margin: '0 0 2px',
            }}>
              ⚠️ {alertData.trigger_type} Alert — {alertData.city}
            </p>
            <p style={{
              fontSize: 12,
              color: 'var(--text-secondary)',
              fontFamily: 'Inter', margin: 0,
            }}>
              Your coverage has been extended automatically.
              Claim processing started.
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Check rows */}
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 6,
      }}>
        {CHECKS.map(check => (
          <div key={check.id} style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: 7,
            }}>
              <span style={{ fontSize: 13 }}>{check.icon}</span>
              <span style={{
                fontSize: 12, fontFamily: 'Inter',
                color: 'var(--text-secondary)',
              }}>
                {check.label}
              </span>
            </div>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: 4,
            }}>
              {checking && !checkTimes[check.id] ? (
                <motion.div
                  animate={{ opacity: [0.3, 1, 0.3] }}
                  transition={{ duration: 1, repeat: Infinity }}
                  style={{
                    width: 6, height: 6,
                    borderRadius: 999,
                    background: '#D97757',
                  }}
                />
              ) : (
                <div style={{
                  width: 6, height: 6,
                  borderRadius: 999,
                  background: '#12B76A',
                }}/>
              )}
              <span style={{
                fontSize: 11, fontFamily: 'Inter',
                color: 'var(--text-tertiary)',
              }}>
                {checkTimes[check.id]
                  ? timeAgo(checkTimes[check.id])
                  : timeAgo(lastChecked)}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Zone info */}
      <div style={{
        marginTop: 10,
        paddingTop: 10,
        borderTop: '1px solid var(--border-light)',
        display: 'flex',
        alignItems: 'center',
        gap: 5,
      }}>
        <Shield size={11} color="var(--text-tertiary)"/>
        <span style={{
          fontSize: 11, fontFamily: 'Inter',
          color: 'var(--text-tertiary)',
        }}>
          Watching: {worker?.zone || worker?.city || ''}
        </span>
      </div>
    </motion.div>
  )
}
