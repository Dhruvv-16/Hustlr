import { useEffect } from 'react'
import { motion } from 'framer-motion'
import { Bell } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useWorkerStore } from '../../store/workerStore'
import { getMyNotifications } from '../../services/api'

export const NotificationBell = () => {
  const navigate = useNavigate()
  const notifications = useWorkerStore((s) => s.notifications)
  const setNotifications = useWorkerStore((s) => s.setNotifications)
  const unreadCount = (notifications || []).filter((item) => !item.read).length

  useEffect(() => {
    let active = true

    const loadNotifications = async () => {
      try {
        const data = await getMyNotifications()
        if (active) setNotifications(data.notifications || [])
      } catch {}
    }

    loadNotifications()
    const interval = setInterval(loadNotifications, 15000)
    return () => {
      active = false
      clearInterval(interval)
    }
  }, [setNotifications])

  return (
    <motion.button
      onClick={() => navigate('/notifications')}
      style={{
        position: 'relative',
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        width: 36,
        height: 36,
        borderRadius: 999,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
      whileTap={{ scale: 0.9 }}
    >
      <Bell size={20} style={{ color: 'var(--text-secondary)' }} />
      {unreadCount > 0 && (
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          style={{
            position: 'absolute',
            top: 4, right: 2,
            minWidth: 16, height: 16,
            borderRadius: 999,
            background: '#F04438',
            border: '1.5px solid var(--bg-card, white)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <span style={{
            fontSize: 9, fontWeight: 700,
            fontFamily: 'Inter', color: 'white',
            lineHeight: 1,
          }}>
            {unreadCount}
          </span>
        </motion.div>
      )}
    </motion.button>
  )
}

export default NotificationBell
