import { motion } from 'framer-motion'

export const AnimatedBackground = () => (
  <div style={{
    position: 'fixed',
    inset: 0,
    zIndex: -1,
    overflow: 'hidden',
    pointerEvents: 'none',
  }}>
    <motion.div
      style={{
        position: 'absolute',
        width: '60vw',
        height: '60vw',
        maxWidth: 500,
        maxHeight: 500,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(217,119,87,0.12) 0%, transparent 70%)',
        top: '-20%',
        right: '-10%',
      }}
      animate={{
        x: [0, 30, -10, 20, 0],
        y: [0, -20, 10, -10, 0],
        scale: [1, 1.05, 0.98, 1.02, 1],
      }}
      transition={{ duration: 20, repeat: Infinity, ease: 'easeInOut' }}
    />
    <motion.div
      style={{
        position: 'absolute',
        width: '50vw',
        height: '50vw',
        maxWidth: 400,
        maxHeight: 400,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(240,230,211,0.15) 0%, transparent 70%)',
        bottom: '10%',
        left: '-10%',
      }}
      animate={{
        x: [0, -20, 15, -5, 0],
        y: [0, 15, -20, 10, 0],
        scale: [1, 0.97, 1.03, 0.99, 1],
      }}
      transition={{ duration: 25, repeat: Infinity, ease: 'easeInOut', delay: 5 }}
    />
    <motion.div
      style={{
        position: 'absolute',
        width: '40vw',
        height: '40vw',
        maxWidth: 350,
        maxHeight: 350,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(217,119,87,0.06) 0%, transparent 70%)',
        top: '40%',
        left: '30%',
      }}
      animate={{
        x: [0, 20, -15, 10, 0],
        y: [0, -10, 20, -5, 0],
      }}
      transition={{ duration: 30, repeat: Infinity, ease: 'easeInOut', delay: 10 }}
    />
  </div>
)
