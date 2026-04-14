import { motion } from 'framer-motion'
import { ArrowLeft } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

const Maintenance = ({
  feature = 'This feature',
  eta = 'Coming soon',
}) => {
  const navigate = useNavigate()

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: 24,
      background: 'var(--bg-primary)',
      textAlign: 'center',
    }}>
      <motion.div
        animate={{ rotate: [-20, 20, -20] }}
        transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
        style={{ fontSize: 48, marginBottom: 24 }}
      >
        🔧
      </motion.div>

      <h2 style={{
        fontFamily: 'Bricolage Grotesque, sans-serif',
        fontSize: 24,
        fontWeight: 800,
        color: 'var(--text-primary)',
        marginBottom: 8,
      }}>
        We're building this
      </h2>

      <p style={{
        fontSize: 15,
        color: 'var(--text-secondary)',
        fontFamily: 'Inter, sans-serif',
        marginBottom: 6,
        lineHeight: 1.5,
        maxWidth: 280,
      }}>
        {feature} is under active development.
      </p>

      <p style={{
        fontSize: 13,
        color: 'var(--brand, #D97757)',
        fontFamily: 'Inter, sans-serif',
        fontWeight: 500,
        marginBottom: 32,
      }}>
        {eta}
      </p>

      <div style={{
        width: 200,
        height: 4,
        background: 'var(--bg-secondary)',
        borderRadius: 999,
        marginBottom: 32,
        overflow: 'hidden',
      }}>
        <motion.div
          style={{
            height: '100%',
            background: 'var(--brand, #D97757)',
            borderRadius: 999,
          }}
          animate={{ width: ['0%', '75%', '60%', '80%'] }}
          transition={{ duration: 3, repeat: Infinity, ease: 'easeInOut' }}
        />
      </div>

      <motion.button
        onClick={() => navigate(-1)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          background: 'none',
          border: '1px solid var(--border)',
          borderRadius: 10,
          padding: '10px 20px',
          cursor: 'pointer',
          fontSize: 14,
          fontWeight: 500,
          fontFamily: 'Inter, sans-serif',
          color: 'var(--text-primary)',
        }}
        whileTap={{ scale: 0.97 }}
      >
        <ArrowLeft size={16} />
        Go back
      </motion.button>
    </div>
  )
}

export default Maintenance
