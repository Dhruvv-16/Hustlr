export default function Badge({ children, variant = 'grey' }) {
  const variants = {
    success: 'bg-success-light text-success',
    warning: 'bg-warning-light text-warning',
    danger:  'bg-danger-light text-danger',
    info:    'bg-[#EFF8FF] text-[#2E90FA]',
    grey:    'bg-grey-50 text-grey-500',
    brand:   'bg-brand-light text-brand',
  }

  return (
    <span
      className={`
        inline-flex items-center px-2 py-[3px] rounded-pill
        text-[11px] font-semibold font-body
        ${variants[variant]}
      `}
    >
      {children}
    </span>
  )
}
