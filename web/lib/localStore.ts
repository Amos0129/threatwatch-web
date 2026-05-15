import { ArticleUI } from './types'

// ─── Read state ───────────────────────────────────────────────────────────────

const READ_KEY = 'threatwatch_read'

export function loadReadSet(): Set<string> {
  if (typeof window === 'undefined') return new Set()
  try {
    const arr: string[] = JSON.parse(localStorage.getItem(READ_KEY) ?? '[]')
    return new Set(arr)
  } catch { return new Set() }
}

export function markRead(id: string): void {
  if (typeof window === 'undefined') return
  try {
    const set = loadReadSet()
    set.add(id)
    localStorage.setItem(READ_KEY, JSON.stringify([...set]))
  } catch {}
}

// ─── Bookmarks ────────────────────────────────────────────────────────────────

const BOOKMARKS_KEY = 'threatwatch_bookmarks'

export function loadBookmarks(): Record<string, ArticleUI> {
  if (typeof window === 'undefined') return {}
  try {
    const raw = localStorage.getItem(BOOKMARKS_KEY)
    if (!raw) return {}
    return JSON.parse(raw) as Record<string, ArticleUI>
  } catch {
    return {}
  }
}

export function toggleBookmark(article: ArticleUI): boolean {
  const current = loadBookmarks()
  if (current[article.id]) {
    delete current[article.id]
    localStorage.setItem(BOOKMARKS_KEY, JSON.stringify(current))
    return false
  } else {
    current[article.id] = article
    localStorage.setItem(BOOKMARKS_KEY, JSON.stringify(current))
    return true
  }
}

export function isBookmarked(id: string): boolean {
  const current = loadBookmarks()
  return !!current[id]
}

// ─── Keywords ─────────────────────────────────────────────────────────────────

const KEYWORDS_KEY = 'threatwatch_keywords'

export function loadKeywords(): string[] {
  if (typeof window === 'undefined') return []
  try {
    const raw = localStorage.getItem(KEYWORDS_KEY)
    if (!raw) return []
    return JSON.parse(raw) as string[]
  } catch {
    return []
  }
}

export function saveKeywords(kws: string[]): void {
  if (typeof window === 'undefined') return
  localStorage.setItem(KEYWORDS_KEY, JSON.stringify(kws))
}

// ─── Known IDs (new article tracking) ────────────────────────────────────────

const KNOWN_IDS_KEY = 'threatwatch_known_ids'

export function getKnownIds(): Set<string> {
  if (typeof window === 'undefined') return new Set()
  try {
    const raw = localStorage.getItem(KNOWN_IDS_KEY)
    if (!raw) return new Set()
    return new Set(JSON.parse(raw) as string[])
  } catch {
    return new Set()
  }
}

export function saveKnownIds(ids: string[]): void {
  if (typeof window === 'undefined') return
  localStorage.setItem(KNOWN_IDS_KEY, JSON.stringify(ids))
}

// ─── Translation cache ────────────────────────────────────────────────────────

const TRANSLATIONS_KEY = 'threatwatch_translations'

export function loadTranslations(): Record<string, string> {
  if (typeof window === 'undefined') return {}
  try {
    return JSON.parse(localStorage.getItem(TRANSLATIONS_KEY) ?? '{}')
  } catch { return {} }
}

export function saveTranslations(map: Record<string, string>): void {
  if (typeof window === 'undefined') return
  try {
    const existing = loadTranslations()
    localStorage.setItem(TRANSLATIONS_KEY, JSON.stringify({ ...existing, ...map }))
  } catch {}
}
