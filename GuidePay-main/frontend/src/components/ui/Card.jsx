import { motion } from 'framer-motion'

export default function Card({
  children,
  padding = 'p-4',
  bordered = false,
  interactive = false,
  onClick,
  className = '',
  style = {},
}) {
  const baseStyle = {
    background: 'var(--bg-card)',
    borderRadius: 16,
    boxShadow: 'var(--shadow-card)',
    ...(bordered ? { border: '1px solid var(--border)' } : {}),
    ...style,
  }

  if (interactive) {
    return (
      <motion.div
        className={`${padding} ${className}`}
        style={{ ...baseStyle, cursor: 'pointer' }}
        onClick={onClick}
        whileTap={{ scale: 0.98 }}
        whileHover={{ y: -1, boxShadow: '0 6px 20px rgba(0,0,0,0.1)' }}
      >
        {children}
      </motion.div>
    )
  }

  return (
    <div className={`${padding} ${className}`} style={baseStyle}>
      {children}
    </div>
  )
}
