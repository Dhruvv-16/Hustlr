import { useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'

export default function TopBar({ title, showBack = false, rightAction, onBack, bgClass = 'bg-white' }) {
  const navigate = useNavigate()

  const handleBack = () => {
    if (onBack) onBack()
    else navigate(-1)
  }

  return (
    <div
      className={`sticky top-0 z-50 ${bgClass} border-b border-[#F4F4F5] flex items-center justify-between px-4 h-14`}
    >
      <div className="flex items-center gap-3">
        {showBack && (
          <button
            onClick={handleBack}
            className="flex items-center justify-center w-10 h-10 -ml-2 rounded-full hover:bg-grey-50 transition-colors"
            aria-label="Go back"
          >
            <ArrowLeft size={20} className="text-[#0F0F0F]" />
          </button>
        )}
        {title && (
          <h1 className="font-display font-semibold text-[17px] text-[#0F0F0F]">
            {title}
          </h1>
        )}
      </div>
      {rightAction && (
        <div className="flex items-center">{rightAction}</div>
      )}
    </div>
  )
}
