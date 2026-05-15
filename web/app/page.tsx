'use client'

import { useState, useEffect } from 'react'
import { applyTheme, ThemeId } from '@/lib/themes'
import { getThemeId, getFontSize, FONT_SIZE_OPTIONS } from '@/lib/storage'
import { useNews } from '@/lib/hooks/useNews'
import { useArticleFilter } from '@/lib/hooks/useArticleFilter'
import { usePreferences } from '@/lib/hooks/usePreferences'
import { useArticleAnalysis } from '@/lib/hooks/useArticleAnalysis'
import { useTranslations } from '@/lib/hooks/useTranslations'
import FilterChips from '@/components/FilterChips'
import ArticleRow from '@/components/ArticleRow'
import ArticleDetail from '@/components/ArticleDetail'
import SettingsModal from '@/components/SettingsModal'

export default function Home() {
  const [selectedLink, setSelectedLink] = useState<string | null>(null)
  const [showSettings, setShowSettings] = useState(false)
  const [showBookmarks, setShowBookmarks] = useState(false)

  const prefs = usePreferences()
  const { articles, isLoading, error, newCount, load, refresh, updateArticle } = useNews()
  const { filter, setFilter, search, setSearch, displayLimit, filteredArticles, showMore } = useArticleFilter(articles, prefs.disabledFeeds)
  const { analyze } = useArticleAnalysis(updateArticle)
  const { enabled: translateEnabled, isTranslating, toggle: toggleTranslate, getTitle } = useTranslations()

  useEffect(() => {
    load()
    prefs.init()
    applyTheme(getThemeId() as ThemeId)
    const px = FONT_SIZE_OPTIONS.find(f => f.value === getFontSize())?.px ?? 18
    document.documentElement.style.fontSize = `${px}px`
  }, [load, prefs.init])

  const displayArticles = showBookmarks ? Object.values(prefs.bookmarks) : filteredArticles
  const selectedArticle = selectedLink ? articles.find(a => a.link === selectedLink) ?? null : null

  function handleSettingsClose() {
    setShowSettings(false)
    prefs.reloadAfterSettings()
  }

  return (
    <div className="min-h-screen flex flex-col max-w-7xl mx-auto w-full">

      {/* Navbar */}
      <header className="sticky top-0 z-30 flex items-center justify-between px-5 py-3 border-b"
        style={{ background: 'var(--page-bg)', borderColor: 'var(--separator)' }}>
        <button onClick={refresh} className="p-1 relative" aria-label="重新整理">
          <svg className="w-5 h-5" style={{ color: 'var(--accent)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
          </svg>
          {newCount > 0 && (
            <span className="absolute -top-1 -right-1 flex items-center justify-center rounded-full bg-red-500 text-white font-bold leading-none"
              style={{ width: 16, height: 16, fontSize: 9, minWidth: 16 }}>
              {newCount > 99 ? '99+' : newCount}
            </span>
          )}
        </button>
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5" style={{ color: 'var(--accent)' }} fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
          </svg>
          <span className="font-semibold text-base">ThreatWatch</span>
        </div>
        <div className="flex items-center gap-1">
          <button onClick={() => toggleTranslate(filteredArticles)} className="p-1 relative" aria-label="切換翻譯">
            {isTranslating ? (
              <svg className="animate-spin w-5 h-5" style={{ color: 'var(--accent)' }} viewBox="0 0 24 24" fill="none">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
              </svg>
            ) : (
              <svg className="w-5 h-5" style={{ color: translateEnabled ? 'var(--accent)' : 'var(--text-2)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/>
              </svg>
            )}
          </button>
          <button onClick={() => setShowBookmarks(b => !b)} className="p-1" aria-label="書籤">
            {showBookmarks ? (
              <svg className="w-5 h-5" style={{ color: 'var(--accent)' }} fill="currentColor" viewBox="0 0 24 24">
                <path d="M5 3a2 2 0 00-2 2v16l7-3 7 3V5a2 2 0 00-2-2H5z"/>
              </svg>
            ) : (
              <svg className="w-5 h-5" style={{ color: 'var(--text-2)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 3a2 2 0 00-2 2v16l7-3 7 3V5a2 2 0 00-2-2H5z"/>
              </svg>
            )}
          </button>
          <button onClick={prefs.cycleViewMode} className="p-1" aria-label="切換顯示方式">
            {prefs.viewMode === 'list' ? (
              <svg className="w-5 h-5" style={{ color: 'var(--text-2)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
              </svg>
            ) : prefs.viewMode === 'grid2' ? (
              <svg className="w-5 h-5" style={{ color: 'var(--accent)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <rect x="3" y="3" width="8" height="8" rx="1.5"/><rect x="13" y="3" width="8" height="8" rx="1.5"/>
                <rect x="3" y="13" width="8" height="8" rx="1.5"/><rect x="13" y="13" width="8" height="8" rx="1.5"/>
              </svg>
            ) : (
              <svg className="w-5 h-5" style={{ color: 'var(--accent)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <rect x="2" y="3" width="6" height="8" rx="1"/><rect x="9" y="3" width="6" height="8" rx="1"/><rect x="16" y="3" width="6" height="8" rx="1"/>
                <rect x="2" y="13" width="6" height="8" rx="1"/><rect x="9" y="13" width="6" height="8" rx="1"/><rect x="16" y="13" width="6" height="8" rx="1"/>
              </svg>
            )}
          </button>
          <button onClick={() => setShowSettings(true)} className="p-1" aria-label="設定">
            <svg className="w-5 h-5" style={{ color: 'var(--text-2)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
          </button>
        </div>
      </header>

      {/* Search */}
      {!showBookmarks && (
        <div className="px-5 pt-4 pb-2">
          <div className="flex items-center gap-2 px-3 py-2 rounded-xl" style={{ background: 'var(--card-bg)' }}>
            <svg className="w-4 h-4 shrink-0" style={{ color: 'var(--text-3)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
            <input
              type="text"
              placeholder="搜尋新聞、來源…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="flex-1 bg-transparent text-sm"
              style={{ color: 'var(--text-1)' }}
            />
            {search && (
              <button onClick={() => setSearch('')} style={{ color: 'var(--text-3)' }}>
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd"/>
                </svg>
              </button>
            )}
          </div>
        </div>
      )}

      {/* External search links */}
      {!showBookmarks && search.trim() && (
        <div className="px-5 pb-1">
          <div className="flex items-center gap-1.5 flex-wrap">
            <span className="text-xs shrink-0" style={{ color: 'var(--text-3)' }}>外部搜尋：</span>
            {[
              { label: 'NVD/CVE', url: `https://nvd.nist.gov/vuln/search/results?query=${encodeURIComponent(search)}` },
              { label: 'VirusTotal', url: `https://www.virustotal.com/gui/search/${encodeURIComponent(search)}` },
              { label: 'Shodan', url: `https://www.shodan.io/search?query=${encodeURIComponent(search)}` },
              { label: 'GitHub Advisories', url: `https://github.com/advisories?query=${encodeURIComponent(search)}` },
              { label: 'MITRE ATT&CK', url: `https://attack.mitre.org/techniques/search/?query=${encodeURIComponent(search)}` },
              { label: 'Google', url: `https://www.google.com/search?q=${encodeURIComponent(search + ' cybersecurity')}` },
            ].map(({ label, url }) => (
              <a key={label} href={url} target="_blank" rel="noopener noreferrer"
                className="px-2 py-0.5 rounded-lg text-xs font-medium"
                style={{ background: 'var(--card-bg)', color: 'var(--accent)' }}>
                {label}
              </a>
            ))}
          </div>
        </div>
      )}

      {/* Filter chips */}
      {!showBookmarks && (
        <div className="px-5 pb-2">
          <FilterChips selected={filter} onChange={setFilter} />
        </div>
      )}

      {/* Count */}
      {!isLoading && (
        <div className="px-5 pb-2">
          <p className="text-xs" style={{ color: 'var(--text-3)' }}>
            {showBookmarks ? `書籤 ${displayArticles.length} 則` : `${filteredArticles.length} 則新聞`}
          </p>
        </div>
      )}

      {/* Article list */}
      <main className="flex-1 px-5 pb-10">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center gap-3 py-20">
            <svg className="animate-spin w-8 h-8" style={{ color: 'var(--accent)' }} viewBox="0 0 24 24" fill="none">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
            </svg>
            <p className="text-sm" style={{ color: 'var(--text-3)' }}>載入中…</p>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center gap-4 py-20">
            <svg className="w-12 h-12" style={{ color: 'var(--text-3)' }} fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M8.288 15.038a5.25 5.25 0 017.424 0M5.106 11.856c3.807-3.808 9.98-3.808 13.788 0M1.924 8.674c5.565-5.565 14.587-5.565 20.152 0M12.53 18.22l-.53.53-.53-.53a.75.75 0 011.06 0z"/>
            </svg>
            <p className="text-sm" style={{ color: 'var(--text-2)' }}>{error}</p>
            <button onClick={refresh} className="px-5 py-2 rounded-xl text-sm font-medium"
              style={{ background: 'var(--card-bg)', color: 'var(--accent)' }}>
              重新載入
            </button>
          </div>
        ) : displayArticles.length === 0 ? (
          <div className="flex flex-col items-center gap-2 py-20">
            <p className="text-sm" style={{ color: 'var(--text-3)' }}>
              {showBookmarks ? '尚未加入書籤' : '找不到符合的新聞'}
            </p>
          </div>
        ) : (
          <>
            <div className={
              prefs.viewMode === 'grid3' ? 'grid gap-2 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
              : prefs.viewMode === 'grid2' ? 'grid gap-2 grid-cols-1 sm:grid-cols-2'
              : 'flex flex-col gap-2'
            }>
              {(filter === 'all' && !search && !showBookmarks
                ? displayArticles.slice(0, displayLimit)
                : displayArticles
              ).map(article => (
                <ArticleRow
                  key={article.id}
                  article={article}
                  isRead={prefs.readIds.has(article.id)}
                  onClick={() => {
                    prefs.markArticleRead(article.id)
                    setSelectedLink(article.link)
                  }}
                  displayTitle={getTitle(article.title)}
                  matchedKeywords={prefs.getMatchedKeywords(article)}
                  isBookmarked={!!prefs.bookmarks[article.id]}
                />
              ))}
            </div>
            {filter === 'all' && !search && !showBookmarks && filteredArticles.length > displayLimit && (
              <button onClick={showMore}
                className="mt-4 w-full py-3 rounded-2xl text-sm font-medium"
                style={{ background: 'var(--card-bg)', color: 'var(--accent)' }}>
                顯示更多（還有 {filteredArticles.length - displayLimit} 則）
              </button>
            )}
          </>
        )}
      </main>

      {selectedArticle && (
        <ArticleDetail
          article={selectedArticle}
          hasApiKey={prefs.hasApiKey}
          onClose={() => setSelectedLink(null)}
          onAnalyze={analyze}
          isBookmarked={!!prefs.bookmarks[selectedArticle.id]}
          onToggleBookmark={() => prefs.handleToggleBookmark(selectedArticle)}
        />
      )}

      {showSettings && <SettingsModal onClose={handleSettingsClose} />}
    </div>
  )
}
