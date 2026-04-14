import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import TopBar from '../../components/ui/TopBar'
import OTPInput from '../../components/ui/OTPInput'
import Button from '../../components/ui/Button'
import { useWorkerStore } from '../../store/workerStore'
import { api } from '../../services/api'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

export default function OTP() {
  const navigate = useNavigate()
  const { phone, login } = useWorkerStore()
  const [otp, setOtp] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(false)
  const [errorMsg, setErrorMsg] = useState('')
  const [success, setSuccess] = useState(false)
  const [countdown, setCountdown] = useState(30)
  const [canResend, setCanResend] = useState(false)

  const displayPhone = phone || '+91'

  useEffect(() => {
    if (countdown <= 0) {
      setCanResend(true)
      return
    }
    const timer = setTimeout(() => setCountdown((current) => current - 1), 1000)
    return () => clearTimeout(timer)
  }, [countdown])

  const handleVerify = async (code) => {
    const value = code || otp
    if (value.length !== 6 && value.length !== 4) return

    setLoading(true)
    setError(false)
    setErrorMsg('')

    try {
      const res = await api.verifyOTP(phone, value)
      login(res.worker)
      setSuccess(true)
      setTimeout(() => navigate('/zone'), 600)
    } catch (e) {
      setError(true)
      setErrorMsg(e?.message || 'Incorrect OTP. Please try again.')
      setLoading(false)
    }
  }

  const handleResend = async () => {
    if (!canResend) return
    setCanResend(false)
    setCountdown(30)
    await api.sendOTP(phone)
  }

  return (
    <motion.div className="min-h-screen bg-white" variants={pageVariants} initial="initial" animate="animate" exit="exit">
      <TopBar showBack />

      <div className="px-6 pt-8">
        <h1 className="font-display font-bold text-[26px] text-[#0F0F0F]">Verify your number</h1>
        <p className="font-body text-[15px] text-[#0F0F0F] font-semibold mt-1.5">
          {displayPhone}{' '}
          <button onClick={() => navigate('/login')} className="text-brand font-medium ml-1">
            Wrong number?
          </button>
        </p>

        <div className="mt-8">
          <OTPInput length={6} onChange={setOtp} onComplete={handleVerify} error={error} />
        </div>

        <div className="mt-3 text-center">
          {!canResend ? (
            <p className="text-[13px] text-[#9B9B9B] font-body">Resend in {countdown}s</p>
          ) : (
            <button onClick={handleResend} className="text-[13px] text-brand font-semibold font-body">
              Resend OTP
            </button>
          )}
        </div>

        <AnimatePresence>
          {error && (
            <motion.p initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="text-[13px] text-danger text-center mt-3 font-body">
              {errorMsg}
            </motion.p>
          )}
        </AnimatePresence>

        <AnimatePresence>
          {success && (
            <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} className="flex justify-center mt-4">
              <div className="w-12 h-12 bg-success-light rounded-full flex items-center justify-center">
                <svg viewBox="0 0 24 24" fill="none" className="w-6 h-6">
                  <path d="M5 13l4 4L19 7" stroke="#12B76A" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="mt-6">
          <Button onClick={() => handleVerify(otp)} loading={loading} fullWidth>
            Verify &amp; Continue
          </Button>
        </div>
      </div>
    </motion.div>
  )
}
