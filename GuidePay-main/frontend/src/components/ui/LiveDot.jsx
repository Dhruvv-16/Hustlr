import { motion } from 'framer-motion'

export default function LiveDot({ status = 'active' }) {
  const colors = {
    active: { dot: 'bg-success', ring: 'bg-success' },
    alert:  { dot: 'bg-danger',  ring: 'bg-danger'  },
    idle:   { dot: 'bg-grey-300', ring: 'bg-grey-300' },
  }

  const { dot, ring } = colors[status] || colors.active

  return (
    <span className="relative inline-flex items-center justify-center w-3 h-3">
      <motion.span
        className={`absolute inset-0 rounded-full ${ring} opacity-40`}
        animate={{ scale: [1, 2, 1], opacity: [0.4, 0, 0.4] }}
        transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
      />
      <motion.span
        className={`w-2 h-2 rounded-full ${dot}`}
        animate={{ scale: [1, 1.15, 1] }}
        transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
      />
    </span>
  )
}
