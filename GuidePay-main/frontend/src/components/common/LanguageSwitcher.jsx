import { useWorkerStore } from '../../store/workerStore'
import { LANGUAGES } from '../../i18n'
import { Globe } from 'lucide-react'

export default function LanguageSwitcher() {
  const { language, setLanguage } = useWorkerStore()

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <Globe size={16} color="var(--text-secondary)" />
      <select
        value={language}
        onChange={(e) => setLanguage(e.target.value)}
        style={{
          background: 'transparent',
          color: 'var(--text-primary)',
          border: '1px solid var(--border-light)',
          borderRadius: 6,
          padding: '4px 6px',
          fontSize: 12,
          fontFamily: 'Inter',
          cursor: 'pointer',
          outline: 'none',
        }}
      >
        {LANGUAGES.map(lang => (
          <option key={lang.code} value={lang.code} style={{ color: 'black' }}>
            {lang.label}
          </option>
        ))}
      </select>
    </div>
  )
}
