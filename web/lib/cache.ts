import { NewsArticle, ArticleUI } from './types'
import { PROMPT_VERSION } from './constants'

const CACHE_KEY = 'threatwatch_cache'

interface CacheEntry {
  keyPoints: string[]
  cachedAt: string
  promptVersion: number
}

type CacheMap = Record<string, CacheEntry>

export function loadCache(): Record<string, string[]> {
  if (typeof window === 'undefined') return {}
  try {
    const raw = localStorage.getItem(CACHE_KEY)
    if (!raw) return {}
    const parsed: CacheMap = JSON.parse(raw)
    const result: Record<string, string[]> = {}
    for (const [url, entry] of Object.entries(parsed)) {
      if (entry.promptVersion === PROMPT_VERSION) {
        result[url] = entry.keyPoints
      }
    }
    return result
  } catch {
    return {}
  }
}

export function saveToCache(url: string, keyPoints: string[]): void {
  if (typeof window === 'undefined') return
  try {
    const raw = localStorage.getItem(CACHE_KEY)
    const parsed: CacheMap = raw ? JSON.parse(raw) : {}
    parsed[url] = { keyPoints, cachedAt: new Date().toISOString(), promptVersion: PROMPT_VERSION }
    localStorage.setItem(CACHE_KEY, JSON.stringify(parsed))
  } catch {}
}

export function applyCache(articles: NewsArticle[], cache: Record<string, string[]>): ArticleUI[] {
  return articles.map(a => ({ ...a, keyPoints: cache[a.link] }))
}
