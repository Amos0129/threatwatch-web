export type ThemeId =
  // 深色系
  | 'dark' | 'midnight' | 'warm' | 'slate' | 'forest'
  // 亮色系
  | 'light' | 'sky' | 'cream' | 'rose' | 'mint'

export interface Theme {
  id: ThemeId
  name: string
  dark: boolean   // 用於分組顯示
  vars: Record<string, string>
}

export const THEMES: Theme[] = [

  // ── 深色系 ─────────────────────────────────────────
  {
    id: 'dark', name: '深色', dark: true,
    vars: {
      '--page-bg':   '#111119',
      '--card-bg':   '#1e1e2e',
      '--accent':    '#5dbf80',
      '--text-1':    '#ffffff',
      '--text-2':    '#999999',
      '--text-3':    '#5a5a6a',
      '--separator': 'rgba(255,255,255,0.07)',
    },
  },
  {
    id: 'midnight', name: '午夜藍', dark: true,
    vars: {
      '--page-bg':   '#0d1117',
      '--card-bg':   '#161b22',
      '--accent':    '#58a6ff',
      '--text-1':    '#e6edf3',
      '--text-2':    '#8b949e',
      '--text-3':    '#484f58',
      '--separator': 'rgba(255,255,255,0.06)',
    },
  },
  {
    id: 'warm', name: '暖褐', dark: true,
    vars: {
      '--page-bg':   '#1c1814',
      '--card-bg':   '#28231c',
      '--accent':    '#e8a838',
      '--text-1':    '#f0e6d0',
      '--text-2':    '#a89070',
      '--text-3':    '#6b5c48',
      '--separator': 'rgba(255,255,255,0.07)',
    },
  },
  {
    id: 'slate', name: '靛藍', dark: true,
    vars: {
      '--page-bg':   '#0f172a',
      '--card-bg':   '#1e293b',
      '--accent':    '#818cf8',
      '--text-1':    '#f1f5f9',
      '--text-2':    '#94a3b8',
      '--text-3':    '#475569',
      '--separator': 'rgba(255,255,255,0.06)',
    },
  },
  {
    id: 'forest', name: '深林', dark: true,
    vars: {
      '--page-bg':   '#0d1a0f',
      '--card-bg':   '#162418',
      '--accent':    '#4ade80',
      '--text-1':    '#e8f5e9',
      '--text-2':    '#86a98a',
      '--text-3':    '#4a6b4e',
      '--separator': 'rgba(255,255,255,0.06)',
    },
  },

  // ── 亮色系 ─────────────────────────────────────────
  {
    id: 'light', name: '純白', dark: false,
    vars: {
      '--page-bg':   '#f2f2f7',
      '--card-bg':   '#ffffff',
      '--accent':    '#2a9d5c',
      '--text-1':    '#111111',
      '--text-2':    '#444444',
      '--text-3':    '#888888',
      '--separator': 'rgba(0,0,0,0.08)',
    },
  },
  {
    id: 'sky', name: '天藍', dark: false,
    vars: {
      '--page-bg':   '#e8f4fd',
      '--card-bg':   '#ffffff',
      '--accent':    '#0284c7',
      '--text-1':    '#0c1a2e',
      '--text-2':    '#3a5068',
      '--text-3':    '#7a9ab0',
      '--separator': 'rgba(2,132,199,0.10)',
    },
  },
  {
    id: 'cream', name: '米白', dark: false,
    vars: {
      '--page-bg':   '#faf6f0',
      '--card-bg':   '#ffffff',
      '--accent':    '#b45309',
      '--text-1':    '#1c1410',
      '--text-2':    '#5c4a38',
      '--text-3':    '#9c8a78',
      '--separator': 'rgba(0,0,0,0.07)',
    },
  },
  {
    id: 'rose', name: '玫瑰', dark: false,
    vars: {
      '--page-bg':   '#fdf2f4',
      '--card-bg':   '#ffffff',
      '--accent':    '#e11d48',
      '--text-1':    '#1a0a0f',
      '--text-2':    '#6b3a4a',
      '--text-3':    '#b08090',
      '--separator': 'rgba(225,29,72,0.08)',
    },
  },
  {
    id: 'mint', name: '薄荷', dark: false,
    vars: {
      '--page-bg':   '#f0faf4',
      '--card-bg':   '#ffffff',
      '--accent':    '#059669',
      '--text-1':    '#0a1f16',
      '--text-2':    '#2d5a42',
      '--text-3':    '#6aaa88',
      '--separator': 'rgba(5,150,105,0.10)',
    },
  },
]

export function getTheme(id: ThemeId): Theme {
  return THEMES.find(t => t.id === id) ?? THEMES[0]
}

export function applyTheme(id: ThemeId): void {
  const theme = getTheme(id)
  const root  = document.documentElement.style
  for (const [k, v] of Object.entries(theme.vars)) {
    root.setProperty(k, v)
  }
}
