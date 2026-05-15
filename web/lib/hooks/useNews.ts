import { useState, useCallback } from 'react'
import { ArticleUI } from '@/lib/types'
import { loadCache, applyCache } from '@/lib/cache'
import { getKnownIds, saveKnownIds } from '@/lib/localStore'

export function useNews() {
  const [articles, setArticles]   = useState<ArticleUI[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError]         = useState<string | null>(null)
  const [newCount, setNewCount]   = useState(0)

  const load = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const res = await fetch('/api/rss')
      if (!res.ok) throw new Error('載入失敗')
      const data = await res.json() as ArticleUI[]
      const cache = loadCache()
      const processed = applyCache(data, cache)
      const knownIds = getKnownIds()
      if (knownIds.size > 0) {
        const freshCount = processed.filter(a => !knownIds.has(a.id)).length
        setNewCount(freshCount)
      } else {
        setNewCount(0)
      }
      saveKnownIds(processed.map(a => a.id))
      setArticles(processed)
    } catch {
      setError('無法載入新聞，請檢查網路連線')
    } finally {
      setIsLoading(false)
    }
  }, [])

  const refresh = useCallback(() => {
    setNewCount(0)
    load()
  }, [load])

  function updateArticle(updated: ArticleUI) {
    setArticles(prev => prev.map(a => a.link === updated.link ? updated : a))
  }

  return { articles, setArticles, isLoading, error, newCount, load, refresh, updateArticle }
}
