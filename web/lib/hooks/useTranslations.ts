import { useState, useCallback } from 'react'
import { ArticleUI } from '@/lib/types'
import { loadTranslations, saveTranslations } from '@/lib/localStore'

export function useTranslations() {
  const [translations, setTranslations] = useState<Record<string, string>>(() => loadTranslations())
  const [isTranslating, setIsTranslating] = useState(false)
  const [enabled, setEnabled] = useState(false)

  const translate = useCallback(async (articles: ArticleUI[]) => {
    const untranslated = [...new Set(articles.map(a => a.title))].filter(t => !translations[t])
    if (!untranslated.length) return

    setIsTranslating(true)
    try {
      const res = await fetch('/api/translate', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ titles: untranslated }),
      })
      const data = await res.json()
      if (data.translations) {
        saveTranslations(data.translations)
        setTranslations(prev => ({ ...prev, ...data.translations }))
      }
    } finally {
      setIsTranslating(false)
    }
  }, [translations])

  function toggle(articles: ArticleUI[]) {
    const next = !enabled
    setEnabled(next)
    if (next) translate(articles)
  }

  function getTitle(original: string): string {
    return (enabled && translations[original]) ? translations[original] : original
  }

  return { enabled, isTranslating, toggle, getTitle }
}
