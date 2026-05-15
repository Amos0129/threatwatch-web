// 封裝 AI 分析的完整流程：讀設定 → 呼叫 API → 更新快取 → 通知父元件
// ArticleDetail 只需呼叫 analyze(article)，不需要知道任何實作細節

import { ArticleUI } from '@/lib/types'
import { getActiveSettings } from '@/lib/storage'
import { saveToCache } from '@/lib/cache'

export function useArticleAnalysis(onUpdate: (article: ArticleUI) => void) {
  async function analyze(article: ArticleUI): Promise<void> {
    const { providerId, apiKey, modelId } = getActiveSettings()
    if (!apiKey) return

    onUpdate({ ...article, isAnalyzing: true, analyzeError: undefined })

    try {
      const res = await fetch('/api/ai', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          article,
          provider: providerId,
          modelID:  modelId,
          apiKey,
        }),
      })

      const data = await res.json()

      if (data.keyPoints?.length) {
        saveToCache(article.link, data.keyPoints)
        onUpdate({ ...article, keyPoints: data.keyPoints, isAnalyzing: false, analyzeError: undefined })
      } else {
        onUpdate({ ...article, isAnalyzing: false, analyzeError: data.error ?? '分析失敗，請稍後再試' })
      }
    } catch {
      onUpdate({ ...article, isAnalyzing: false, analyzeError: '網路錯誤，請稍後再試' })
    }
  }

  return { analyze }
}
