import { motion } from 'framer-motion'

export default function Button({
  children,
  variant = 'primary',
  loading = false,
  fullWidth = true,
  onClick,
  disabled,
  icon,
  size = 'default',
}) {
  const base = `
    relative inline-flex items-center justify-center gap-2
    font-body font-semibold text-[15px] rounded-button
    transition-colors duration-150 select-none
    min-h-[52px] px-5
    ${fullWidth ? 'w-full' : 'w-auto'}
    ${disabled || loading ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer'}
  `

  const variants = {
    primary: 'bg-brand text-white hover:bg-brand-dark active:bg-brand-dark',
    secondary: 'bg-brand-light text-brand hover:bg-orange-100 active:bg-orange-100',
    ghost: 'bg-white border border-[#E4E4E7] text-[#6B6B6B] hover:bg-grey-50 active:bg-grey-50',
    danger: 'bg-danger text-white hover:bg-red-600',
  }

  return (
    <motion.button
      whileTap={disabled || loading ? {} : { scale: 0.97 }}
      whileHover={disabled || loading ? {} : { scale: 1.01 }}
      className={`${base} ${variants[variant]}`}
      onClick={disabled || loading ? undefined : onClick}
      disabled={disabled || loading}
      type="button"
    >
      {loading ? (
        <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
        </svg>
      ) : (
        <>
          {icon && <span className="flex-shrink-0">{icon}</span>}
          {children}
        </>
      )}
    </motion.button>
  )
}
