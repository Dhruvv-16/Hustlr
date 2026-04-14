import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const WORDS = ['गाइडपे', 'गाईडपे', 'கைடு பே', 'గైడ్ పే', 'GuidePay']

export const LoadingScreen = ({ onComplete }) => {
  const [index, setIndex] = useState(0)
  const [isExiting, setIsExiting] = useState(false)

  useEffect(() => {
    if (index < WORDS.length - 1) {
      const timer = setTimeout(() => {
        setIndex((prev) => prev + 1)
      }, 350)
      return () => clearTimeout(timer)
    } else if (!isExiting) {
      const timer = setTimeout(() => {
        setIsExiting(true)
      }, 1000)
      return () => clearTimeout(timer)
    }
  }, [index, isExiting])

  useEffect(() => {
    if (isExiting) {
      const timer = setTimeout(() => {
        onComplete?.()
      }, 800)
      return () => clearTimeout(timer)
    }
  }, [isExiting, onComplete])

  return (
    <motion.div
      animate={{ y: isExiting ? '-100%' : '0%', opacity: isExiting ? 0 : 1 }}
      transition={{ duration: 0.8, ease: [0.76, 0, 0.24, 1] }}
      style={{
        position: 'fixed',
        inset: 0,
        background: '#0A0A0B',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
        flexDirection: 'column',
      }}
    >
      <div style={{ height: 60, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <AnimatePresence mode="wait">
          <motion.div
            key={index}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.2 }}
            style={{
              fontSize: 36,
              fontWeight: 400,
              fontFamily: 'Barlow, sans-serif',
              color: 'white',
              letterSpacing: '-0.02em',
            }}
          >
            {WORDS[index]}
          </motion.div>
        </AnimatePresence>
      </div>

      <div style={{ display: 'flex', gap: 6, marginTop: 24 }}>
        {[0, 1, 2].map(i => (
          <motion.div
            key={i}
            animate={{ y: [0, -6, 0], opacity: [0.4, 1, 0.4] }}
            transition={{ delay: i * 0.15, duration: 0.6, repeat: Infinity, ease: 'easeInOut' }}
            style={{
              width: 6, height: 6,
              borderRadius: 999,
              background: '#D97757',
            }}
          />
        ))}
      </div>
    </motion.div>
  )
}

export default LoadingScreen
