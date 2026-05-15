import { NextResponse } from 'next/server'
import { XMLParser } from 'fast-xml-parser'
import { FEEDS } from '@/lib/feeds'
import { NewsArticle, stripHtml } from '@/lib/types'
import crypto from 'crypto'

export const runtime = 'nodejs'
export const revalidate = 300

const SCRAPE_UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

async function fetchWithRetry(url: string, options: RequestInit, retries = 2): Promise<Response> {
  for (let i = 0; i <= retries; i++) {
    try {
      const res = await fetch(url, options)
      if (res.ok) return res
      if (i === retries) return res   // return last failed response
    } catch (err) {
      if (i === retries) throw err
      await new Promise(r => setTimeout(r, 500 * (i + 1)))  // 500ms, 1000ms backoff
    }
  }
  throw new Error('fetchWithRetry exhausted')
}

// hasExplicitTimezone returns true when the date string carries its own offset/zone
function hasExplicitTimezone(s: string): boolean {
  return /[Zz]$/.test(s) ||
    /[+-]\d{2}:?\d{2}$/.test(s) ||
    /\b(GMT|UTC|EST|EDT|CST|CDT|MST|MDT|PST|PDT)\b/i.test(s)
}

// parseDate converts various RSS date formats to an ISO 8601 UTC string.
// utcOffsetMins: assumed UTC offset (minutes) for feeds that publish timezone-less dates.
function parseDate(str: string | null | undefined, utcOffsetMins = 0): string {
  if (!str) return new Date().toISOString()
  const s = str.trim()
  // Unix timestamp in seconds (10 digits)
  if (/^\d{10}$/.test(s)) return new Date(parseInt(s) * 1000).toISOString()
  // If no explicit timezone, apply the feed's known UTC offset so the result
  // is server-timezone-independent (fixes e.g. iThome publishing Taiwan local time).
  if (!hasExplicitTimezone(s) && utcOffsetMins !== 0) {
    const sign = utcOffsetMins >= 0 ? '+' : '-'
    const abs = Math.abs(utcOffsetMins)
    const hh = String(Math.floor(abs / 60)).padStart(2, '0')
    const mm = String(abs % 60).padStart(2, '0')
    const withTz = `${s}${sign}${hh}:${mm}`
    const d = new Date(withTz)
    if (!isNaN(d.getTime())) return d.toISOString()
  }
  const d = new Date(s)
  return isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString()
}

// Helper to extract plain string from fast-xml-parser node (handles CDATA, text node, raw string)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function str(val: any): string {
  if (!val) return ''
  if (typeof val === 'string') return val
  if (typeof val === 'number') return String(val)
  if (val.__cdata) return String(val.__cdata)
  if (val['#text']) return String(val['#text'])
  return ''
}

const xmlParser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '@_',
  textNodeName: '#text',
  cdataPropName: '__cdata',
  isArray: (name) => name === 'item' || name === 'entry',
  allowBooleanAttributes: true,
  parseTagValue: false,      // keep all tag values as strings, prevents dates becoming numbers
  parseAttributeValue: false,
})

function parseFeed(xml: string, sourceName: string, utcOffsetMins = 0): NewsArticle[] {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let doc: any
  try {
    doc = xmlParser.parse(xml)
  } catch {
    return []
  }

  const isAtom = !!doc.feed
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const items: any[] = isAtom
    ? (doc.feed?.entry ?? [])
    : (doc.rss?.channel?.item ?? [])

  return items.map(item => {
    const title = stripHtml(str(item.title))

    // Atom: <link href="..."/> — may be array or object
    let link = ''
    if (isAtom) {
      const l = item.link
      if (Array.isArray(l)) {
        const alt = l.find((x: { '@_rel'?: string }) => x['@_rel'] !== 'self')
        link = alt?.['@_href'] ?? l[0]?.['@_href'] ?? ''
      } else {
        link = l?.['@_href'] ?? str(l)
      }
    } else {
      link = str(item.link) || str(item.guid)
    }

    const description = stripHtml(
      str(item['content:encoded']) ||
      str(item.description) ||
      str(item.summary) ||
      str(item.content)
    )

    const pubDate = parseDate(
      str(item.pubDate) ||
      str(item.published) ||
      str(item.updated) ||
      str(item['dc:date']),
      utcOffsetMins
    )

    return {
      id: crypto.createHash('md5').update(link || title).digest('hex'),
      title,
      link,
      description,
      pubDate,
      source: sourceName,
    } satisfies NewsArticle
  }).filter(a => a.title && a.link)
}

// ── 資安人 custom scraper ────────────────────────────────────────────

async function fetchInfoSecArticle(aid: string, sourceName: string): Promise<NewsArticle | null> {
  const link = `https://www.informationsecurity.com.tw/article/article_detail.aspx?aid=${aid}`
  try {
    const res = await fetchWithRetry(link, { headers: { 'User-Agent': SCRAPE_UA } })
    if (!res.ok) return null
    const html = await res.text()

    const h1Match = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i)
    const title = h1Match ? h1Match[1].replace(/<[^>]+>/g, '').trim() : ''
    if (!title) return null

    const afterH1 = h1Match ? html.slice(html.indexOf(h1Match[0]) + h1Match[0].length, html.indexOf(h1Match[0]) + h1Match[0].length + 300) : ''
    const dateMatch = afterH1.match(/(\d{4})\s*\/\s*(\d{1,2})\s*\/\s*(\d{1,2})/)
    const pubDate = dateMatch
      ? new Date(`${dateMatch[1]}-${dateMatch[2].padStart(2, '0')}-${dateMatch[3].padStart(2, '0')}`).toISOString()
      : new Date().toISOString()

    const paras = [...html.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/g)]
      .map(m => m[1].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim())
      .filter(t => t.length > 20)
    const description = paras.slice(0, 3).join(' ').slice(0, 1500)

    return {
      id: crypto.createHash('md5').update(link).digest('hex'),
      title, link, description, pubDate, source: sourceName,
    }
  } catch {
    return null
  }
}

async function scrapeInfoSec(sourceName: string): Promise<NewsArticle[]> {
  try {
    const homeRes = await fetchWithRetry('https://www.informationsecurity.com.tw/', {
      headers: { 'User-Agent': SCRAPE_UA },
      next: { revalidate: 300 },
    })
    if (!homeRes.ok) return []
    const homeHtml = await homeRes.text()
    const aids = [...new Set(
      [...homeHtml.matchAll(/article_detail\.aspx\?aid=(\d+)/g)].map(m => m[1])
    )]
    const results = await Promise.allSettled(aids.map(aid => fetchInfoSecArticle(aid, sourceName)))
    return results
      .filter(r => r.status === 'fulfilled' && r.value)
      .map(r => (r as PromiseFulfilledResult<NewsArticle>).value)
  } catch {
    return []
  }
}

// ── Feed fetcher ─────────────────────────────────────────────────────

async function fetchFeed(feed: typeof FEEDS[0]): Promise<NewsArticle[]> {
  try {
    if (feed.url.startsWith('scrape:')) {
      const id = feed.url.split(':')[1]
      if (id === 'informationsecurity') return scrapeInfoSec(feed.name)
      return []
    }
    const res = await fetchWithRetry(feed.url, {
      headers: { 'User-Agent': 'ThreatWatch/1.0 RSS Reader' },
      next: { revalidate: 300 },
    })
    if (!res.ok) return []
    return parseFeed(await res.text(), feed.name, feed.utcOffset ?? 0)
  } catch {
    return []
  }
}

export async function GET() {
  const results = await Promise.allSettled(FEEDS.map(fetchFeed))
  const articles: NewsArticle[] = results
    .flatMap(r => r.status === 'fulfilled' ? r.value : [])
    .sort((a, b) => new Date(b.pubDate).getTime() - new Date(a.pubDate).getTime())
  return NextResponse.json(articles)
}
