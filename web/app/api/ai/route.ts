import { NextRequest, NextResponse } from 'next/server'
import { NewsArticle } from '@/lib/types'
import { PROMPT_VERSION } from '@/lib/constants'

export const runtime = 'nodejs'

interface RequestBody {
  article: NewsArticle
  provider: string
  modelID: string
  apiKey: string
}


function buildPrompt(article: NewsArticle): string {
  return `請用繁體中文說明以下新聞在講什麼，讓一般人也能看懂。

標題: ${article.title}
內容: ${article.description.slice(0, 600)}

提供兩項內容：
第一項：一句話說明這篇文章的重點（20字以內）
第二項：詳細說明這篇文章在講什麼，根據文章內容完整說明，不要省略，用自然的方式描述即可

請嚴格以下列 JSON 格式回傳，不要有任何其他文字：
{
  "keyPoints": [
    "一句話重點",
    "詳細說明..."
  ]
}`
}

async function callClaude(prompt: string, apiKey: string, modelID: string): Promise<string[]> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: modelID,
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    }),
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Claude error ${res.status}: ${err}`)
  }
  const data = await res.json()
  return parseKeyPoints(data.content?.[0]?.text ?? '')
}

async function callGemini(prompt: string, apiKey: string, modelID: string): Promise<string[]> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelID}:generateContent?key=${apiKey}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini error ${res.status}: ${err}`)
  }
  const data = await res.json()
  return parseKeyPoints(data.candidates?.[0]?.content?.parts?.[0]?.text ?? '')
}

async function callOpenAICompatible(
  prompt: string, apiKey: string, modelID: string, baseURL: string
): Promise<string[]> {
  const res = await fetch(`${baseURL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: modelID,
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    }),
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`API error ${res.status}: ${err}`)
  }
  const data = await res.json()
  return parseKeyPoints(data.choices?.[0]?.message?.content ?? '')
}

function parseKeyPoints(text: string): string[] {
  let clean = text
  if (clean.includes('```json')) clean = clean.split('```json')[1].split('```')[0]
  else if (clean.includes('```')) clean = clean.split('```')[1].split('```')[0]
  clean = clean.trim()
  try {
    const parsed = JSON.parse(clean)
    return parsed.keyPoints ?? []
  } catch {
    return []
  }
}

const BASE_URLS: Record<string, string> = {
  openai:  'https://api.openai.com/v1',
  groq:    'https://api.groq.com/openai/v1',
  xai:     'https://api.x.ai/v1',
  mistral: 'https://api.mistral.ai/v1',
}

export async function POST(req: NextRequest) {
  try {
    const body: RequestBody = await req.json()
    const { article, provider, modelID, apiKey } = body

    if (!apiKey?.trim()) {
      return NextResponse.json({ error: '未提供 API Key' }, { status: 400 })
    }

    const prompt = buildPrompt(article)
    let keyPoints: string[]

    switch (provider) {
      case 'claude':
        keyPoints = await callClaude(prompt, apiKey, modelID)
        break
      case 'gemini':
        keyPoints = await callGemini(prompt, apiKey, modelID)
        break
      default:
        keyPoints = await callOpenAICompatible(prompt, apiKey, modelID, BASE_URLS[provider] ?? '')
    }

    return NextResponse.json({ keyPoints, promptVersion: PROMPT_VERSION })
  } catch (err) {
    const msg = err instanceof Error ? err.message : '未知錯誤'
    return NextResponse.json({ error: msg }, { status: 500 })
  }
}
