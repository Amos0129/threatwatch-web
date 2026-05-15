import { NextRequest, NextResponse } from 'next/server'

export const runtime = 'nodejs'

// MyMemory free limit is ~500 chars per request
function chunkText(text: string, maxLen = 400): string[] {
  if (text.length <= maxLen) return [text]
  const chunks: string[] = []
  let remaining = text
  while (remaining.length > 0) {
    if (remaining.length <= maxLen) { chunks.push(remaining); break }
    // Try to cut at sentence boundary
    let cutAt = maxLen
    const dot = remaining.lastIndexOf('. ', maxLen)
    if (dot > maxLen / 2) cutAt = dot + 2
    chunks.push(remaining.slice(0, cutAt).trim())
    remaining = remaining.slice(cutAt).trim()
  }
  return chunks
}

async function translateChunk(text: string): Promise<string> {
  const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=en|zh-TW`
  const res = await fetch(url)
  if (!res.ok) throw new Error(`MyMemory ${res.status}`)
  const data = await res.json()
  return data.responseData?.translatedText ?? text
}

async function translateOne(text: string): Promise<string> {
  if (text.length <= 400) return translateChunk(text)
  const chunks = chunkText(text)
  const results = await Promise.all(chunks.map(c => translateChunk(c)))
  return results.join(' ')
}

export async function POST(req: NextRequest) {
  try {
    const { titles }: { titles: string[] } = await req.json()
    if (!titles?.length) {
      return NextResponse.json({ error: '缺少參數' }, { status: 400 })
    }

    const translations: Record<string, string> = {}

    // 每批 5 篇並行，避免 rate limit
    const BATCH = 5
    for (let i = 0; i < titles.length; i += BATCH) {
      const batch = titles.slice(i, i + BATCH)
      const results = await Promise.allSettled(batch.map(t => translateOne(t)))
      results.forEach((r, idx) => {
        if (r.status === 'fulfilled') translations[batch[idx]] = r.value
      })
    }

    return NextResponse.json({ translations })
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : '未知錯誤' }, { status: 500 })
  }
}
