import { useState, useMemo } from 'react'
import { ArticleUI, TimeFilter, getFilterCutoff } from '@/lib/types'

export function useArticleFilter(articles: ArticleUI[], disabledFeeds: Set<string>) {
  const [filter, setFilterState]           = useState<TimeFilter>('all')
  const [search, setSearchState]           = useState('')
  const [displayLimit, setDisplayLimit]    = useState(30)

  const filteredArticles = useMemo(() => {
    return articles
      .filter(a => {
        if (disabledFeeds.has(a.source)) return false
        const cutoff = getFilterCutoff(filter)
        if (cutoff && new Date(a.pubDate) < cutoff) return false
        if (search) {
          const q = search.toLowerCase()
          return (
            a.title.toLowerCase().includes(q) ||
            a.source.toLowerCase().includes(q) ||
            a.description.toLowerCase().includes(q)
          )
        }
        return true
      })
      .sort((a, b) => {
        const aA = !!a.keyPoints
        const bA = !!b.keyPoints
        if (aA !== bA) return aA ? -1 : 1
        return new Date(b.pubDate).getTime() - new Date(a.pubDate).getTime()
      })
  }, [articles, disabledFeeds, filter, search])

  function setFilter(f: TimeFilter) {
    setFilterState(f)
    setDisplayLimit(30)
  }

  function setSearch(s: string) {
    setSearchState(s)
    setDisplayLimit(30)
  }

  function showMore() {
    setDisplayLimit(n => n + 30)
  }

  return { filter, setFilter, search, setSearch, displayLimit, setDisplayLimit, filteredArticles, showMore }
}
