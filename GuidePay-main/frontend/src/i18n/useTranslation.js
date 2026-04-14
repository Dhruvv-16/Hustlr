import { useWorkerStore } from '../store/workerStore'
import { TRANSLATIONS } from './index'

export const useTranslation = () => {
  const language = useWorkerStore(s => s.language) || 'en'
  const englishDict = TRANSLATIONS.en || {}
  
  const t = (key) => {
    const langDict = TRANSLATIONS[language] || englishDict
    return langDict?.[key] ?? englishDict?.[key] ?? key
  }
  
  return { t, language }
}
