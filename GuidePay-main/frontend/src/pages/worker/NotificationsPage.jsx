import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft } from 'lucide-react'
import { useWorkerStore } from '../../store/workerStore'
import {
  getMyNotifications,
  getSmartNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from '../../services/api'

const TYPE_STYLES = {
  SUPPORT: { icon: '💬', color: '#2E90FA' },
  SUPPORT_STATUS: { icon: '🛠️', color: '#D97757' },
  CLAIM: { icon: '💰', color: '#12B76A' },
  ALERT: { icon: '🌧️', color: '#F79009' },
  COVERAGE: { icon: '🛡️', color: '#7A5AF8' },
  // Smart notification types
  flood: { icon: '🌊', color: '#2E90FA' },
  expiry: { icon: '⚠️', color: '#F04438' },
  unprotected: { icon: '🛡️', color: '#F04438' },
  paid: { icon: '✅', color: '#12B76A' },
  forecast: { icon: '📊', color: '#F79009' },
}

const timeLabel = (iso) => {
  const diff = Date.now() - new Date(iso).getTime()
  const mins = Math.max(0, Math.floor(diff / 60000))
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  if (mins < 60) return `${mins}m ago`
  if (hours < 24) return `${hours}h ago`
  return `${days}d ago`
}

export default function NotificationsPage() {
  const navigate = useNavigate()
  const notifications = useWorkerStore((s) => s.notifications)
  const setNotifications = useWorkerStore((s) => s.setNotifications)
  const [loading, setLoading] = useState(true)
  const [smartNotifications, setSmartNotifications] = useState([])

  useEffect(() => {
    let active = true

    const load = async () => {
      try {
        const [data, smartData] = await Promise.allSettled([
          getMyNotifications(),
          getSmartNotifications(),
        ])
        if (active) {
          if (data.status === 'fulfilled') setNotifications(data.value.notifications || [])
          if (smartData.status === 'fulfilled') setSmartNotifications(smartData.value.notifications || [])
        }
      } catch (error) {
        console.error('[Notifications] Failed to load:', error)
      } finally {
        if (active) setLoading(false)
      }
    }

    load()
    return () => {
      active = false
    }
  }, [setNotifications])

  const groups = useMemo(() => {
    const items = notifications || []
    return {
      Today: items.filter((item) => Date.now() - new Date(item.created_at).getTime() < 86400000),
      Yesterday: items.filter((item) => {
        const diff = Date.now() - new Date(item.created_at).getTime()
        return diff >= 86400000 && diff < 172800000
      }),
      Earlier: items.filter((item) => Date.now() - new Date(item.created_at).getTime() >= 172800000),
    }
  }, [notifications])

  const unreadCount = (notifications || []).filter((item) => !item.read).length

  const openNotification = async (notification) => {
    try {
      if (!notification.read) {
        await markNotificationRead(notification.id)
        setNotifications((notifications || []).map((item) => (
          item.id === notification.id ? { ...item, read: true } : item
        )))
      }
    } catch {}

    if (notification.link) navigate(notification.link)
  }

  const handleReadAll = async () => {
    try {
      await markAllNotificationsRead()
      setNotifications((notifications || []).map((item) => ({ ...item, read: true })))
    } catch (error) {
      console.error('[Notifications] Mark all failed:', error)
    }
  }

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-secondary)', paddingBottom: 80 }}>
      <div style={{ background: 'var(--bg-card)', borderBottom: '1px solid var(--border-light)', padding: '16px', display: 'flex', alignItems: 'center', gap: 12, position: 'sticky', top: 0, zIndex: 50 }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>
          <ArrowLeft size={22} color="var(--text-primary)" />
        </button>
        <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: 800, color: 'var(--text-primary)', margin: 0, flex: 1 }}>
          Notifications
        </h1>
        {unreadCount > 0 && (
          <button onClick={handleReadAll} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#D97757', fontSize: 12, fontWeight: 700, fontFamily: 'Inter' }}>
            Mark all read
          </button>
        )}
      </div>

      {loading ? (
        <div style={{ padding: 20, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading notifications...</div>
      ) : (
        <div style={{ padding: '8px 0' }}>
          {/* Smart contextual notifications */}
          {smartNotifications.length > 0 && (
            <div>
              <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '1.5px', textTransform: 'uppercase', padding: '12px 16px 6px', margin: 0 }}>
                Live Alerts
              </p>
              {smartNotifications.map((n, i) => {
                const urgencyBg = n.urgency === 'high' ? 'rgba(240,68,56,0.06)' : n.urgency === 'medium' ? 'rgba(247,144,9,0.06)' : 'rgba(18,183,106,0.06)'
                return (
                  <motion.div
                    key={n.id}
                    initial={{ opacity: 0, x: -8 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.04 }}
                    style={{ display: 'flex', gap: 12, padding: '14px 16px', background: urgencyBg, borderBottom: '1px solid var(--border-light)', borderLeft: `3px solid ${n.color}` }}
                  >
                    <div style={{ width: 40, height: 40, borderRadius: 12, background: `${n.color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0 }}>
                      {n.icon}
                    </div>
                    <div style={{ flex: 1 }}>
                      <p style={{ fontSize: 13, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 2px' }}>{n.title}</p>
                      <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)', margin: 0 }}>{n.message}</p>
                    </div>
                  </motion.div>
                )
              })}
            </div>
          )}

          {Object.entries(groups)
            .filter(([, items]) => items.length > 0)
            .map(([group, items]) => (
              <div key={group}>
                <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '1.5px', textTransform: 'uppercase', padding: '12px 16px 6px', margin: 0 }}>
                  {group}
                </p>
                {items.map((notification, index) => {
                  const style = TYPE_STYLES[notification.type] || { icon: '🔔', color: '#D97757' }
                  return (
                    <motion.div
                      key={notification.id}
                      initial={{ opacity: 0, x: -8 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.04 }}
                      onClick={() => openNotification(notification)}
                      style={{
                        display: 'flex',
                        gap: 12,
                        padding: '14px 16px',
                        background: notification.read ? 'transparent' : 'rgba(217,119,87,0.04)',
                        borderBottom: '1px solid var(--border-light)',
                        cursor: notification.link ? 'pointer' : 'default',
                      }}
                    >
                      <div style={{ width: 40, height: 40, borderRadius: 12, background: `${style.color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0 }}>
                        {style.icon}
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
                          <p style={{ fontSize: 13, fontWeight: notification.read ? 500 : 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: 0 }}>
                            {notification.title}
                          </p>
                          <span style={{ fontSize: 10, fontFamily: 'Inter', color: 'var(--text-tertiary)', flexShrink: 0 }}>
                            {timeLabel(notification.created_at)}
                          </span>
                        </div>
                        <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)', margin: '2px 0 0' }}>
                          {notification.body}
                        </p>
                      </div>
                      {!notification.read && (
                        <div style={{ width: 7, height: 7, borderRadius: 999, background: '#D97757', flexShrink: 0, marginTop: 6 }} />
                      )}
                    </motion.div>
                  )
                })}
              </div>
            ))}

          {!loading && (notifications || []).length === 0 && (
            <div style={{ padding: 24, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>
              No notifications yet.
            </div>
          )}
        </div>
      )}
    </div>
  )
}
