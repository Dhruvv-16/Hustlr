import { useState } from 'react'

export default function Input({
  label,
  helper,
  error,
  prefix,
  suffix,
  className = '',
  ...props
}) {
  const [focused, setFocused] = useState(false)

  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      {label && (
        <label className="text-[13px] font-medium text-[#6B6B6B] font-body">
          {label}
        </label>
      )}
      <div
        className={`
          flex items-center overflow-hidden rounded-input border-[1.5px] transition-all duration-150
          ${error
            ? 'border-danger shadow-[0_0_0_3px_rgba(240,68,56,0.1)]'
            : focused
              ? 'border-brand shadow-[0_0_0_3px_rgba(217,119,87,0.1)]'
              : 'border-[#E4E4E7]'
          }
          bg-white h-[52px]
        `}
      >
        {prefix && (
          <div className="flex items-center justify-center px-3.5 h-full bg-grey-50 border-r border-[#E4E4E7] text-[15px] font-semibold text-[#0F0F0F] font-body flex-shrink-0">
            {prefix}
          </div>
        )}
        <input
          className="flex-1 h-full px-4 text-[15px] font-body text-[#0F0F0F] placeholder:text-[#C4C4C4] bg-transparent outline-none"
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          {...props}
        />
        {suffix && (
          <div className="flex items-center justify-center px-3.5 h-full flex-shrink-0">
            {suffix}
          </div>
        )}
      </div>
      {error && (
        <span className="text-[12px] text-danger font-body">{error}</span>
      )}
      {helper && !error && (
        <span className="text-[12px] text-[#9B9B9B] font-body">{helper}</span>
      )}
    </div>
  )
}
