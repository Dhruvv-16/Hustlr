import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Check, Share2 } from 'lucide-react'
import Button from '../../components/ui/Button'
import { useCountUp } from '../../hooks/useCountUp'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const STORY_LINES = [
  'Ravi filed nothing.',
  'Ravi pressed nothing.',
  'GuidePay handled everything.',
]

const TRANSACTION = [
  { label: 'Transaction ID',  value: 'GP-RZP-20260321-0847', mono: true },
  { label: 'Event',           value: 'IMD Red Alert — Flood' },
  { label: 'Fraud score',     value: '0.04', color: '#12B76A' },
  { label: 'Correlation',     value: '28/33 workers' },
  { label: 'Processed by',    value: 'Razorpay' },
]

export default function PayoutSuccess() {
  const navigate = useNavigate()
  const amount = useCountUp(600, 1200)

  return (
    <motion.div
      className="min-h-screen bg-white flex flex-col items-center justify-start px-4 pt-16 pb-12"
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      {/* Success icon */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: [0, 1.2, 1] }}
        transition={{ type: 'spring', stiffness: 200, damping: 15, delay: 0.1 }}
        className="w-20 h-20 rounded-full bg-success-light border-2 border-success flex items-center justify-center"
      >
        <Check size={32} className="text-success" strokeWidth={2.5} />
      </motion.div>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="text-[14px] text-[#6B6B6B] font-body text-center mt-4"
      >
        Payment received
      </motion.p>

      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: 'spring', stiffness: 200, damping: 20, delay: 0.3 }}
        className="font-display font-extrabold text-[80px] text-[#0F0F0F] text-center tracking-[-4px] leading-none mt-2"
      >
        ₹{amount}
      </motion.div>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5 }}
        className="text-[14px] text-[#6B6B6B] font-body text-center mt-3"
      >
        Sent to UPI · ravi.kumar@okaxis
      </motion.p>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.6 }}
        className="text-[13px] text-[#9B9B9B] font-body text-center mt-1"
      >
        Today 4:31 PM · 1h 57m after flood alert
      </motion.p>

      {/* Transaction card */}
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.7 }}
        className="w-full mt-6 bg-white rounded-card shadow-card overflow-hidden"
      >
        {TRANSACTION.map((row, i) => (
          <div
            key={row.label}
            className={`flex items-center justify-between px-4 py-3 ${i < TRANSACTION.length - 1 ? 'border-b border-grey-50' : ''}`}
          >
            <span className="text-[13px] text-[#6B6B6B] font-body">{row.label}</span>
            <span
              className={`text-[12px] font-body ${row.mono ? 'font-mono' : 'font-semibold'}`}
              style={{ color: row.color || '#0F0F0F' }}
            >
              {row.value}
            </span>
          </div>
        ))}
      </motion.div>

      {/* Closing text */}
      <div className="mt-6 text-center flex flex-col gap-1">
        {STORY_LINES.map((line, i) => (
          <motion.p
            key={line}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.9 + i * 0.15 }}
            className="text-[14px] text-[#6B6B6B] font-body"
          >
            {line}
          </motion.p>
        ))}
      </div>

      {/* CTAs */}
      <div className="w-full mt-6 flex flex-col gap-3">
        <Button onClick={() => navigate('/dashboard')} fullWidth>
          Back to dashboard →
        </Button>
        <Button
          variant="ghost"
          fullWidth
          icon={<Share2 size={16} />}
          onClick={() => {}}
        >
          Share your story
        </Button>
      </div>
    </motion.div>
  )
}
