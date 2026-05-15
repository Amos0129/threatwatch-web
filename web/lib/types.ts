// NewsArticle：從 RSS API 回傳的資料型別，也包含快取的 keyPoints
export interface NewsArticle {
  id: string
  title: string
  link: string
  description: string
  pubDate: string // ISO string
  source: string
  keyPoints?: string[]
}

// ArticleUI：僅在客戶端存在的暫態 UI 狀態，不會序列化或傳給 server
export interface ArticleUI extends NewsArticle {
  isAnalyzing?: boolean
  analyzeError?: string
}

export type TimeFilter = 'all' | 'today' | 'week' | 'month' | '3months' | 'year'

export const TIME_FILTERS: { value: TimeFilter; label: string }[] = [
  { value: 'all',     label: '全部' },
  { value: 'today',   label: '今天' },
  { value: 'week',    label: '一週內' },
  { value: 'month',   label: '一個月內' },
  { value: '3months', label: '三個月' },
  { value: 'year',    label: '一年內' },
]

export function getFilterCutoff(filter: TimeFilter): Date | null {
  const now = new Date()
  switch (filter) {
    case 'today':   return new Date(now.getFullYear(), now.getMonth(), now.getDate())
    case 'week':    return new Date(now.getTime() - 7 * 86400000)
    case 'month':   return new Date(now.getTime() - 30 * 86400000)
    case '3months': return new Date(now.getTime() - 90 * 86400000)
    case 'year':    return new Date(now.getTime() - 365 * 86400000)
    default:        return null
  }
}

export function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime()
  if (diff < 0) return '剛剛'
  const mins = Math.floor(diff / 60000)
  if (mins < 1)     return '剛剛'
  if (mins < 60)    return `${mins} 分鐘前`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24)     return `${hrs} 小時前`
  const days = Math.floor(hrs / 24)
  if (days < 30)    return `${days} 天前`
  const months = Math.floor(days / 30)
  if (months < 12)  return `${months} 個月前`
  return `${Math.floor(months / 12)} 年前`
}

export function stripHtml(html: string): string {
  return html.replace(/<[^>]*>/g, '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&nbsp;/g, ' ').trim()
}
