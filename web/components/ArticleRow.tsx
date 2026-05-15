'use client'

import { ArticleUI, timeAgo } from '@/lib/types'

interface Props {
  article: ArticleUI
  onClick: () => void
  displayTitle?: string
  isRead?: boolean
  matchedKeywords?: string[]
  isBookmarked?: boolean
}

export default function ArticleRow({ article, onClick, displayTitle, isRead, matchedKeywords, isBookmarked }: Props) {
  const hasKeywords = matchedKeywords && matchedKeywords.length > 0

  return (
    <button
      onClick={onClick}
      className="w-full text-left rounded-2xl p-4 transition-opacity active:opacity-70 relative"
      style={{
        background: 'var(--card-bg)',
        opacity: isRead ? 0.5 : 1,
        borderLeft: hasKeywords ? '2px solid var(--accent)' : undefined,
      }}
    >
      {/* Bookmark icon (top-right) */}
      {isBookmarked && (
        <span
          className="absolute top-3 right-3"
          style={{ color: 'var(--accent)', pointerEvents: 'none' }}
          aria-label="已書籤"
        >
          <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M5 3a2 2 0 00-2 2v16l7-3 7 3V5a2 2 0 00-2-2H5z"/>
          </svg>
        </span>
      )}

      {/* Source + time */}
      <div className="flex items-center gap-2 mb-2">
        <span className="w-1.5 h-1.5 rounded-full shrink-0" style={{ background: isRead ? 'var(--text-3)' : 'var(--accent)' }} />
        <span className="text-xs" style={{ color: isRead ? 'var(--text-3)' : 'var(--accent)' }}>{article.source}</span>
        <span className="ml-auto text-xs" style={{ color: 'var(--text-3)' }}>
          {timeAgo(article.pubDate)}
        </span>
      </div>

      {/* Title */}
      <p className="text-sm font-semibold leading-snug" style={{ color: 'var(--text-1)' }}>
        {displayTitle ?? article.title}
      </p>

      {/* Keyword chips */}
      {hasKeywords && (
        <div className="flex flex-wrap gap-1 mt-2">
          {matchedKeywords.map(kw => (
            <span
              key={kw}
              className="px-1.5 py-0.5 rounded text-xs font-medium"
              style={{ background: 'var(--accent)', color: '#000', fontSize: 10 }}
            >
              {kw}
            </span>
          ))}
        </div>
      )}

      {/* Status badge */}
      {(article.isAnalyzing || article.keyPoints) && (
        <div className="flex items-center gap-1.5 mt-2">
          {article.isAnalyzing ? (
            <>
              <svg className="animate-spin w-3 h-3" style={{ color: 'var(--text-3)' }} viewBox="0 0 24 24" fill="none">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
              </svg>
              <span className="text-xs" style={{ color: 'var(--text-3)' }}>說明中…</span>
            </>
          ) : (
            <>
              <svg className="w-3 h-3" style={{ color: 'var(--accent)' }} fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
              </svg>
              <span className="text-xs" style={{ color: 'var(--accent)' }}>已說明</span>
            </>
          )}
        </div>
      )}
    </button>
  )
}
