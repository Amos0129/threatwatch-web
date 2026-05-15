export interface AIModelOption {
  id: string
  name: string
  note: string
}

export interface AIProvider {
  id: string
  displayName: string
  companyName: string
  hasFreetier: boolean
  apiKeyPlaceholder: string
  consoleURL: string
  models: AIModelOption[]
}

export const AI_PROVIDERS: AIProvider[] = [
  {
    id: 'claude',
    displayName: 'Claude',
    companyName: 'Anthropic',
    hasFreetier: false,
    apiKeyPlaceholder: 'sk-ant-…',
    consoleURL: 'console.anthropic.com',
    models: [
      { id: 'claude-haiku-4-5-20251001', name: 'Claude Haiku 4.5',  note: '最快、最省費用' },
      { id: 'claude-sonnet-4-6',         name: 'Claude Sonnet 4.6', note: '速度與品質平衡' },
      { id: 'claude-opus-4-6',           name: 'Claude Opus 4.6',   note: '最強，費用較高' },
    ],
  },
  {
    id: 'openai',
    displayName: 'ChatGPT',
    companyName: 'OpenAI',
    hasFreetier: false,
    apiKeyPlaceholder: 'sk-proj-…',
    consoleURL: 'platform.openai.com/api-keys',
    models: [
      { id: 'gpt-4o-mini', name: 'GPT-4o mini', note: '快速、低成本' },
      { id: 'gpt-4o',      name: 'GPT-4o',      note: '高品質' },
      { id: 'o4-mini',     name: 'o4-mini',      note: '強推理能力' },
      { id: 'o3',          name: 'o3',           note: '最強推理，費用高' },
    ],
  },
  {
    id: 'gemini',
    displayName: 'Gemini',
    companyName: 'Google',
    hasFreetier: true,
    apiKeyPlaceholder: 'AIza…',
    consoleURL: 'aistudio.google.com/app/apikey',
    models: [
      { id: 'gemini-2.0-flash',              name: 'Gemini 2.0 Flash', note: '快速，免費額度多' },
      { id: 'gemini-2.5-flash-preview-04-17',name: 'Gemini 2.5 Flash', note: '最新輕量版' },
      { id: 'gemini-1.5-flash',              name: 'Gemini 1.5 Flash', note: '輕量穩定' },
      { id: 'gemini-1.5-pro',                name: 'Gemini 1.5 Pro',   note: '高品質分析' },
      { id: 'gemini-2.5-pro-preview-05-06',  name: 'Gemini 2.5 Pro',   note: '最強，費用較高' },
    ],
  },
  {
    id: 'groq',
    displayName: 'Groq',
    companyName: 'Groq',
    hasFreetier: true,
    apiKeyPlaceholder: 'gsk_…',
    consoleURL: 'console.groq.com/keys',
    models: [
      { id: 'llama-3.3-70b-versatile', name: 'Llama 3.3 70B', note: '免費、品質佳' },
      { id: 'llama-3.1-8b-instant',    name: 'Llama 3.1 8B',  note: '免費、極速' },
      { id: 'mixtral-8x7b-32768',      name: 'Mixtral 8x7B',  note: '免費、長文本' },
      { id: 'gemma2-9b-it',            name: 'Gemma 2 9B',    note: '免費、Google 出品' },
    ],
  },
  {
    id: 'xai',
    displayName: 'Grok (xAI)',
    companyName: 'xAI',
    hasFreetier: false,
    apiKeyPlaceholder: 'xai-…',
    consoleURL: 'console.x.ai',
    models: [
      { id: 'grok-3',      name: 'Grok 3',      note: '最強版本' },
      { id: 'grok-3-mini', name: 'Grok 3 Mini', note: '快速低成本' },
      { id: 'grok-2',      name: 'Grok 2',      note: '穩定版本' },
    ],
  },
  {
    id: 'mistral',
    displayName: 'Mistral',
    companyName: 'Mistral AI',
    hasFreetier: false,
    apiKeyPlaceholder: '…',
    consoleURL: 'console.mistral.ai/api-keys',
    models: [
      { id: 'mistral-small-latest',  name: 'Mistral Small',  note: '輕量快速' },
      { id: 'mistral-medium-latest', name: 'Mistral Medium', note: '平衡選擇' },
      { id: 'mistral-large-latest',  name: 'Mistral Large',  note: '最強版本' },
    ],
  },
]

export function getProvider(id: string): AIProvider {
  return AI_PROVIDERS.find(p => p.id === id) ?? AI_PROVIDERS[0]
}
