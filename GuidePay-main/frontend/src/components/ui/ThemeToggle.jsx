import { motion } from 'framer-motion'
import { useThemeStore } from '../../store/themeStore'

export default function ThemeToggle() {
  const { isDark, toggle } = useThemeStore()

  return (
    <motion.div
      onClick={(e) => { e.stopPropagation(); toggle() }}
      style={{
        width: 48,
        height: 26,
        borderRadius: 999,
        background: isDark
          ? 'linear-gradient(135deg, #D97757, #B85C3A)'
          : '#D1D5DB',
        padding: '0 4px',
        display: 'flex',
        alignItems: 'center',
        cursor: 'pointer',
        position: 'relative',
        boxShadow: isDark
          ? '0 2px 8px rgba(217,119,87,0.3)'
          : 'inset 0 1px 3px rgba(0,0,0,0.15)',
        transition: 'background 0.3s ease',
      }}
    >
      <motion.div
        style={{
          width: 20,
          height: 20,
          borderRadius: '50%',
          background: '#ffffff',
          boxShadow: '0 1px 4px rgba(0,0,0,0.25)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
        animate={{ x: isDark ? 20 : 0 }}
        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
      >
        <span style={{ fontSize: 11, lineHeight: 1 }}>
          {isDark ? '🌙' : '☀️'}
        </span>
      </motion.div>
    </motion.div>
  )
}
