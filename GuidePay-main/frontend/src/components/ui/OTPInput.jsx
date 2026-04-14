import { useRef, useState } from 'react'
import { motion } from 'framer-motion'

export default function OTPInput({ length = 4, onChange, onComplete, error }) {
  const [values, setValues] = useState(Array(length).fill(''))
  const inputs = useRef([])

  const handleChange = (index, e) => {
    const val = e.target.value.replace(/\D/g, '').slice(-1)
    const newValues = [...values]
    newValues[index] = val
    setValues(newValues)
    onChange?.(newValues.join(''))

    if (val && index < length - 1) {
      inputs.current[index + 1]?.focus()
    }
    if (newValues.every((v) => v !== '')) {
      onComplete?.(newValues.join(''))
    }
  }

  const handleKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !values[index] && index > 0) {
      inputs.current[index - 1]?.focus()
    }
  }

  const handlePaste = (e) => {
    e.preventDefault()
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, length)
    if (!pasted) return
    const newValues = [...values]
    pasted.split('').forEach((char, i) => { newValues[i] = char })
    setValues(newValues)
    onChange?.(newValues.join(''))
    const lastIndex = Math.min(pasted.length, length - 1)
    inputs.current[lastIndex]?.focus()
    if (newValues.every((v) => v !== '')) onComplete?.(newValues.join(''))
  }

  return (
    <div className="flex gap-3 justify-center">
      {values.map((val, index) => (
        <motion.div
          key={index}
          animate={error ? { x: [0, -6, 6, -6, 6, 0] } : {}}
          transition={{ duration: 0.3 }}
        >
          <motion.input
            ref={(el) => (inputs.current[index] = el)}
            type="text"
            inputMode="numeric"
            maxLength={1}
            value={val}
            onChange={(e) => handleChange(index, e)}
            onKeyDown={(e) => handleKeyDown(index, e)}
            onPaste={handlePaste}
            animate={val ? { scale: [1, 1.05, 1] } : { scale: 1 }}
            transition={{ type: 'spring', stiffness: 400, damping: 20 }}
            className={`
              w-16 h-16 text-center text-[28px] font-display font-bold
              rounded-input border-[1.5px] outline-none
              transition-all duration-150
              ${error ? 'border-danger bg-danger-light' : val ? 'border-brand bg-brand-light' : 'border-[#E4E4E7] bg-white'}
              focus:border-brand focus:shadow-[0_0_0_3px_rgba(217,119,87,0.1)]
            `}
          />
        </motion.div>
      ))}
    </div>
  )
}
