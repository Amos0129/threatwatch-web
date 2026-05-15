'use client'

import { useState } from 'react'
import { ArticleUI } from '@/lib/types'

interface Props {
  article: ArticleUI
  hasApiKey: boolean
  onClose: () => void
  onAnalyze: (article: ArticleUI) => void
  isBookmarked: boolean
  onToggleBookmark: () => void
}

export default function ArticleDetail({ article, hasApiKey, onClose, onAnalyze, isBookmarked, onToggleBookmark }: Props) {
  const [translatedDesc, setTranslatedDesc] = useState<string | null>(null)
  const [showTranslated, setShowTranslated] = useState(false)
  const [isTranslatingDesc, setIsTranslatingDesc] = useState(false)
  const [copied, setCopied] = useState(false)

  const pubDate = new Date(article.pubDate).toLocaleDateString('zh-TW', {
    year: 'numeric', month: 'long', day: 'numeric',
  })

  async function handleTranslateDesc() {
    if (translatedDesc) { setShowTranslated(p => !p); return }
    setIsTranslatingDesc(true)
    try {
      const res = await fetch('/api/translate', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ titles: [article.description] }),
      })
      const data = await res.json()
      const t = data.translations?.[article.description]
      if (t) { setTranslatedDesc(t); setShowTranslated(true) }
    } finally {
      setIsTranslatingDesc(false)
    }
  }

  async function handleShare() {
    const text = article.title + '\n' + article.link
    try {
      if (navigator.share) {
        await navigator.share({ title: article.title, url: article.link })
        return
      }
    } catch {
      // fall through to clipboard
    }
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // ignore clipboard errors
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col" style={{ background: 'var(--page-bg)' }}>
      {/* Nav bar */}
      <div className="flex items-center px-4 py-3 border-b" style={{ borderColor: 'var(--separator)' }}>
        <button onClick={onClose} className="flex items-center gap-1 text-sm" style={{ color: 'var(--accent)' }}>
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7"/>
          </svg>
          返回
        </button>
        <span className="mx-auto text-sm font-medium" style={{ color: 'var(--text-2)' }}>{article.source}</span>
        {/* Bookmark + Share buttons */}
        <div className="flex items-center gap-1">
          {copied ? (
            <span className="text-xs px-1" style={{ color: 'var(--accent)' }}>已複製</span>
          ) : (
            <button onClick={handleShare} className="p-1" aria-label="分享">
              <svg className="w-5 h-5" style={{ color: 'var(--text-2)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"/>
              </svg>
            </button>
          )}
          <button onClick={onToggleBookmark} className="p-1" aria-label={isBookmarked ? '移除書籤' : '加入書籤'}>
            {isBookmarked ? (
              <svg className="w-5 h-5" style={{ color: 'var(--accent)' }} fill="currentColor" viewBox="0 0 24 24">
                <path d="M5 3a2 2 0 00-2 2v16l7-3 7 3V5a2 2 0 00-2-2H5z"/>
              </svg>
            ) : (
              <svg className="w-5 h-5" style={{ color: 'var(--text-2)' }} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 3a2 2 0 00-2 2v16l7-3 7 3V5a2 2 0 00-2-2H5z"/>
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-10">

        {/* Header */}
        <div className="mt-6 mb-1">
          <div className="flex items-center gap-2 mb-3">
            <span className="w-1.5 h-1.5 rounded-full" style={{ background: 'var(--accent)' }} />
            <span className="text-xs" style={{ color: 'var(--accent)' }}>{article.source}</span>
            <span className="ml-auto text-xs" style={{ color: 'var(--text-3)' }}>{pubDate}</span>
          </div>
          <h1 className="text-lg font-bold leading-snug" style={{ color: 'var(--text-1)' }}>
            {article.title}
          </h1>
        </div>

        <div className="h-px my-5" style={{ background: 'var(--separator)' }} />

        {/* AI section */}
        {article.isAnalyzing ? (
          <div className="flex items-center gap-3 py-6">
            <svg className="animate-spin w-5 h-5 shrink-0" style={{ color: 'var(--text-2)' }} viewBox="0 0 24 24" fill="none">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
            </svg>
            <div>
              <p className="text-sm" style={{ color: 'var(--text-1)' }}>AI 說明中…</p>
              <p className="text-xs mt-0.5" style={{ color: 'var(--text-3)' }}>通常需要 10–20 秒</p>
            </div>
          </div>

        ) : article.analyzeError ? (
          <div className="py-5">
            <div className="flex items-center gap-2 mb-2">
              <svg className="w-4 h-4" style={{ color: '#f87171' }} fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd"/>
              </svg>
              <p className="text-sm" style={{ color: '#f87171' }}>{article.analyzeError}</p>
            </div>
            <button onClick={() => onAnalyze(article)} className="text-sm underline" style={{ color: 'var(--accent)' }}>
              重新分析
            </button>
          </div>

        ) : article.keyPoints?.length ? (
          <>
            {article.keyPoints[0] && (
              <p className="text-sm font-semibold leading-relaxed py-5" style={{ color: 'var(--text-1)' }}>
                {article.keyPoints[0]}
              </p>
            )}
            <div className="h-px" style={{ background: 'var(--separator)' }} />
            {article.keyPoints[1] && (
              <p className="text-sm leading-7 py-5" style={{ color: 'var(--text-2)' }}>
                {article.keyPoints[1]}
              </p>
            )}
            <div className="h-px" style={{ background: 'var(--separator)' }} />
          </>

        ) : (
          <>
            <button
              onClick={() => onAnalyze(article)}
              disabled={!hasApiKey}
              className="w-full flex items-center gap-3 py-5 disabled:opacity-40"
            >
              <svg className="w-5 h-5 shrink-0" style={{ color: 'var(--accent)' }} fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z"/>
              </svg>
              <span className="text-sm font-medium" style={{ color: 'var(--text-1)' }}>
                讓 AI 說明這篇文章
              </span>
            </button>
            {!hasApiKey && (
              <p className="text-xs pb-3" style={{ color: 'orange' }}>
                請先在設定中選擇 AI 服務並輸入 API Key
              </p>
            )}
            <div className="h-px" style={{ background: 'var(--separator)' }} />
          </>
        )}

        {/* Article content */}
        {article.description && (
          <div className="mt-6">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs uppercase tracking-widest" style={{ color: 'var(--text-3)' }}>原文內容</p>
              <button
                onClick={handleTranslateDesc}
                disabled={isTranslatingDesc}
                className="flex items-center gap-1 text-xs disabled:opacity-50"
                style={{ color: 'var(--accent)' }}
              >
                {isTranslatingDesc ? (
                  <svg className="animate-spin w-3 h-3" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
                  </svg>
                ) : (
                  <svg className="w-3 h-3" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/>
                  </svg>
                )}
                {showTranslated ? '顯示原文' : '翻譯'}
              </button>
            </div>
            <p className="text-sm leading-7" style={{ color: 'var(--text-2)' }}>
              {(() => {
                const text = showTranslated && translatedDesc ? translatedDesc : article.description
                const ends = /[.!?。！？"'»\]）)]\s*$/.test(text)
                return ends ? text : text + '…'
              })()}
            </p>
          </div>
        )}

        {/* Original article link */}
        <a
          href={article.link}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-8 flex items-center justify-center gap-2 w-full py-3.5 rounded-2xl text-sm font-semibold"
          style={{ background: 'var(--card-bg)', color: 'var(--accent)' }}
        >
          前往原文
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
          </svg>
        </a>
      </div>
    </div>
  )
}
