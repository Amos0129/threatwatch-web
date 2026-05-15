'use client'

import { useState, useCallback } from 'react'
import { ArticleUI } from '@/lib/types'
import {
  loadReadSet, markRead,
  loadBookmarks, toggleBookmark,
  loadKeywords,
} from '@/lib/localStore'
import {
  getActiveSettings, getViewMode, setViewMode, ViewMode,
  getDisabledFeeds,
} from '@/lib/storage'

export function usePreferences() {
  const [hasApiKey, setHasApiKey]         = useState(false)
  const [viewMode, setViewModeState]      = useState<ViewMode>('list')
  const [readIds, setReadIds]             = useState<Set<string>>(() => loadReadSet())
  const [disabledFeeds, setDisabledFeeds] = useState<Set<string>>(() => new Set(getDisabledFeeds()))
  const [keywords, setKeywords]           = useState<string[]>([])
  const [bookmarks, setBookmarks]         = useState<Record<string, ArticleUI>>({})

  // Called once on mount to hydrate all preferences
  const init = useCallback(() => {
    setHasApiKey(!!getActiveSettings().apiKey)
    setViewModeState(getViewMode())
    setKeywords(loadKeywords())
    setBookmarks(loadBookmarks())
  }, [])

  // Called after settings modal closes
  function reloadAfterSettings() {
    setHasApiKey(!!getActiveSettings().apiKey)
    setDisabledFeeds(new Set(getDisabledFeeds()))
    setKeywords(loadKeywords())
  }

  function handleToggleBookmark(article: ArticleUI) {
    toggleBookmark(article)
    setBookmarks(loadBookmarks())
  }

  function markArticleRead(id: string) {
    markRead(id)
    setReadIds(prev => new Set([...prev, id]))
  }

  function cycleViewMode() {
    const next: ViewMode = viewMode === 'list' ? 'grid2' : viewMode === 'grid2' ? 'grid3' : 'list'
    setViewModeState(next)
    setViewMode(next)
  }

  function getMatchedKeywords(article: ArticleUI): string[] {
    if (keywords.length === 0) return []
    return keywords.filter(kw => {
      const q = kw.toLowerCase()
      return (
        article.title.toLowerCase().includes(q) ||
        article.description.toLowerCase().includes(q)
      )
    })
  }

  return {
    hasApiKey,
    viewMode,
    readIds,
    disabledFeeds,
    keywords,
    bookmarks,
    init,
    reloadAfterSettings,
    handleToggleBookmark,
    markArticleRead,
    cycleViewMode,
    getMatchedKeywords,
  }
}
