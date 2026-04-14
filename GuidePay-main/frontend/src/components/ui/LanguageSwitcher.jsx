import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useWorkerStore } from '../../store/workerStore'
import { LANGUAGES } from '../../i18n/index'

export const LanguageSwitcher = ({ compact = false }) => {
  const language = useWorkerStore(s => s.language)
  const setLanguage = useWorkerStore(s => s.setLanguage)
  const [open, setOpen] = useState(false)

  const current = LANGUAGES.find(l => l.code === language) || LANGUAGES[0]

  const handleSelect = (code) => {
    setLanguage(code)
    document.documentElement.lang = code
    setOpen(false)
  }

  if (compact) {
    return (
      <div style={{ position: 'relative' }}>
        <button
          onClick={() => setOpen(o => !o)}
          style={{
            padding: '4px 10px',
            borderRadius: 8,
            border: '1px solid var(--border)',
            background: 'var(--bg-secondary)',
            color: 'var(--text-secondary)',
            fontSize: 12,
            fontWeight: 700,
            fontFamily: 'Inter',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 4,
          }}
        >
          {current.code.toUpperCase()} ▾
        </button>
        <AnimatePresence>
          {open && (
            <>
              <div
                onClick={() => setOpen(false)}
                style={{ position: 'fixed', inset: 0, zIndex: 98 }}
              />
              <motion.div
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -4 }}
                style={{
                  position: 'absolute',
                  top: '100%',
                  right: 0,
                  marginTop: 4,
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  zIndex: 99,
                  minWidth: 160,
                  overflow: 'hidden',
                  boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
                }}
              >
                {LANGUAGES.map(lang => (
                  <button
                    key={lang.code}
                    onClick={() => handleSelect(lang.code)}
                    style={{
                      display: 'block',
                      width: '100%',
                      padding: '10px 14px',
                      textAlign: 'left',
                      border: 'none',
                      background: language === lang.code ? 'var(--bg-secondary)' : 'transparent',
                      color: language === lang.code ? 'var(--brand)' : 'var(--text-primary)',
                      fontSize: 13,
                      fontWeight: language === lang.code ? 700 : 400,
                      fontFamily: 'Inter',
                      cursor: 'pointer',
                    }}
                  >
                    {lang.label}
                  </button>
                ))}
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </div>
    )
  }

  // Full (non-compact) — inline select-style
  return (
    <div style={{ position: 'relative' }}>
      <button
        onClick={() => setOpen(o => !o)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 6,
          padding: '5px 10px',
          borderRadius: 8,
          border: '1px solid var(--border)',
          background: 'var(--bg-secondary)',
          color: 'var(--text-secondary)',
          fontSize: 12,
          fontWeight: 600,
          fontFamily: 'Inter',
          cursor: 'pointer',
        }}
      >
        <span>{current.code.toUpperCase()}</span>
        <span style={{
          fontSize: 10,
          transform: open ? 'rotate(180deg)' : 'none',
          transition: 'transform 0.2s',
          display: 'inline-block',
        }}>▾</span>
      </button>
      <AnimatePresence>
        {open && (
          <>
            <div
              onClick={() => setOpen(false)}
              style={{ position: 'fixed', inset: 0, zIndex: 98 }}
            />
            <motion.div
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              style={{
                position: 'absolute',
                top: '100%',
                right: 0,
                marginTop: 4,
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: 12,
                zIndex: 99,
                minWidth: 180,
                overflow: 'hidden',
                boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
              }}
            >
              {LANGUAGES.map(lang => (
                <button
                  key={lang.code}
                  onClick={() => handleSelect(lang.code)}
                  style={{
                    display: 'block',
                    width: '100%',
                    padding: '11px 16px',
                    textAlign: 'left',
                    border: 'none',
                    background: language === lang.code ? 'var(--bg-secondary)' : 'transparent',
                    color: language === lang.code ? 'var(--brand)' : 'var(--text-primary)',
                    fontSize: 13,
                    fontWeight: language === lang.code ? 700 : 400,
                    fontFamily: 'Inter',
                    cursor: 'pointer',
                    borderBottom: '1px solid var(--border-light)',
                  }}
                >
                  {lang.label}
                </button>
              ))}
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  )
}

export default LanguageSwitcher
