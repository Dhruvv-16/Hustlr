import { motion } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { Home, ArrowLeft } from 'lucide-react'

export default function NotFound() {
  const navigate = useNavigate()

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'var(--bg-secondary)',
      padding: 24,
    }}>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        style={{
          textAlign: 'center',
          maxWidth: 380,
        }}
      >
        <div style={{
          fontSize: 72,
          fontFamily: 'Bricolage Grotesque',
          fontWeight: 800,
          color: 'var(--brand)',
          lineHeight: 1,
          marginBottom: 8,
        }}>
          404
        </div>
        <h1 style={{
          fontFamily: 'Bricolage Grotesque',
          fontSize: 22,
          fontWeight: 700,
          color: 'var(--text-primary)',
          margin: '0 0 8px',
        }}>
          Page not found
        </h1>
        <p style={{
          fontSize: 14,
          fontFamily: 'Inter',
          color: 'var(--text-secondary)',
          lineHeight: 1.6,
          margin: '0 0 28px',
        }}>
          The page you're looking for doesn't exist or has been moved.
        </p>

        <div style={{ display: 'flex', gap: 10, justifyContent: 'center' }}>
          <motion.button
            onClick={() => navigate(-1)}
            whileTap={{ scale: 0.96 }}
            style={{
              padding: '12px 20px',
              borderRadius: 10,
              border: '1px solid var(--border)',
              background: 'var(--bg-card)',
              fontSize: 14,
              fontWeight: 600,
              fontFamily: 'Inter',
              color: 'var(--text-primary)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 6,
            }}
          >
            <ArrowLeft size={16} />
            Go back
          </motion.button>
          <motion.button
            onClick={() => navigate('/')}
            whileTap={{ scale: 0.96 }}
            style={{
              padding: '12px 20px',
              borderRadius: 10,
              border: 'none',
              background: '#D97757',
              fontSize: 14,
              fontWeight: 700,
              fontFamily: 'Inter',
              color: 'white',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              boxShadow: '0 4px 16px rgba(217,119,87,0.3)',
            }}
          >
            <Home size={16} />
            Home
          </motion.button>
        </div>

        <p style={{
          fontSize: 11,
          fontFamily: 'Inter',
          color: 'var(--text-tertiary)',
          marginTop: 32,
        }}>
          GuidePay v2.0 · Team SentinelX
        </p>
      </motion.div>
    </div>
  )
}
