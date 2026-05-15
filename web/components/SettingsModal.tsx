'use client'

import { useState, useEffect } from 'react'
import { AI_PROVIDERS, getProvider } from '@/lib/aiProviders'
import { FEEDS } from '@/lib/feeds'
import {
  getSelectedProviderId, getApiKey, getSelectedModel, saveAllSettings,
  getThemeId, setThemeId, getFontSize, setFontSize, FontSize, FONT_SIZE_OPTIONS,
  getDisabledFeeds, setDisabledFeeds,
} from '@/lib/storage'
import { THEMES, ThemeId, applyTheme, Theme } from '@/lib/themes'
import { loadKeywords, saveKeywords } from '@/lib/localStore'

interface Props { onClose: () => void }
type TestState = 'idle' | 'testing' | 'success' | { error: string }

export default function SettingsModal({ onClose }: Props) {
  const [providerId, setProviderId] = useState('claude')
  const [apiKeys, setApiKeys]       = useState<Record<string, string>>({})
  const [models, setModels]         = useState<Record<string, string>>({})
  const [testState, setTestState]   = useState<TestState>('idle')
  const [themeId, setThemeState]    = useState<ThemeId>('dark')
  const [fontSize, setFontState]    = useState<FontSize>('lg')
  const [feedsOpen, setFeedsOpen]   = useState(false)
  const [disabledFeeds, setDisabledState] = useState<string[]>(() => getDisabledFeeds())
  const [keywords, setKeywords]     = useState<string[]>(() => loadKeywords())
  const [kwInput, setKwInput]       = useState('')

  const provider     = getProvider(providerId)
  const currentModel = models[providerId] ?? provider.models[0].id
  const darkThemes   = THEMES.filter(t => t.dark)
  const lightThemes  = THEMES.filter(t => !t.dark)

  useEffect(() => {
    setProviderId(getSelectedProviderId())
    setThemeState(getThemeId() as ThemeId)
    setFontState(getFontSize())
    const keys: Record<string, string> = {}
    const mods: Record<string, string> = {}
    for (const p of AI_PROVIDERS) {
      keys[p.id] = getApiKey(p.id)
      mods[p.id] = getSelectedModel(p.id)
    }
    setApiKeys(keys)
    setModels(mods)
  }, [])

  function handleFeedToggle(name: string) {
    const next = disabledFeeds.includes(name)
      ? disabledFeeds.filter(n => n !== name)
      : [...disabledFeeds, name]
    setDisabledState(next)
    setDisabledFeeds(next)
  }

  function addKeyword() {
    const kw = kwInput.trim()
    if (!kw || keywords.includes(kw)) { setKwInput(''); return }
    const next = [...keywords, kw]
    setKeywords(next)
    saveKeywords(next)
    setKwInput('')
  }

  function removeKeyword(kw: string) {
    const next = keywords.filter(k => k !== kw)
    setKeywords(next)
    saveKeywords(next)
  }

  function handleTheme(id: ThemeId) { setThemeState(id); setThemeId(id); applyTheme(id) }
  function handleFont(f: FontSize) {
    setFontState(f); setFontSize(f)
    document.documentElement.style.fontSize = `${FONT_SIZE_OPTIONS.find(o => o.value === f)?.px ?? 18}px`
  }
  function save() { saveAllSettings(providerId, apiKeys, models); onClose() }

  async function paste() {
    try {
      const t = await navigator.clipboard.readText()
      setApiKeys(p => ({ ...p, [providerId]: t.trim() }))
      setTestState('idle')
    } catch {}
  }

  async function testKey() {
    const key = apiKeys[providerId]?.trim()
    if (!key) return
    setTestState('testing')
    try {
      const res = await fetch('/api/ai', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          article: { id: 't', title: 'test', description: 'hi', link: '', pubDate: '', source: '' },
          provider: providerId, modelID: provider.models[0].id, apiKey: key,
        }),
      })
      const d = await res.json()
      if (res.status === 500) {
        const m: string = d.error ?? ''
        if (m.includes('401') || m.toLowerCase().includes('invalid')) setTestState({ error: 'Key 無效或已過期' })
        else if (m.includes('429')) setTestState({ error: '超過使用限額' })
        else setTestState('success')
      } else setTestState('success')
    } catch { setTestState({ error: '網路錯誤' }) }
  }

  const testColor = testState === 'success' ? 'var(--accent)'
    : testState === 'testing' ? 'orange'
    : typeof testState === 'object' ? '#f87171'
    : 'var(--text-3)'

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-40"
        style={{ background: 'rgba(0,0,0,0.45)', backdropFilter: 'blur(6px)' }}
        onClick={onClose}
      />

      {/* Modal — slides up from bottom on mobile, centered on desktop */}
      <div className="fixed z-50 bottom-0 left-0 right-0 md:inset-0 md:flex md:items-center md:justify-center pointer-events-none">
        <div
          className="pointer-events-auto w-full md:w-[560px] flex flex-col rounded-t-3xl md:rounded-2xl overflow-hidden"
          style={{ background: 'var(--page-bg)', maxHeight: '92vh' }}
        >
          {/* Drag handle (mobile only) */}
          <div className="flex justify-center pt-2.5 md:hidden">
            <div className="w-9 h-1 rounded-full opacity-30" style={{ background: 'var(--text-2)' }} />
          </div>

          {/* Header */}
          <div className="flex items-center justify-between px-5 pt-3 pb-3">
            <button onClick={onClose} className="text-sm w-10" style={{ color: 'var(--text-3)' }}>取消</button>
            <span className="text-sm font-semibold">設定</span>
            <button onClick={save} className="text-sm font-semibold text-right w-10" style={{ color: 'var(--accent)' }}>儲存</button>
          </div>
          <div className="h-px mx-5" style={{ background: 'var(--separator)' }} />

          {/* Body */}
          <div className="flex-1 overflow-y-auto px-5 py-5">

            <div className="flex flex-col gap-4">

              {/* 外觀 */}
              <Card>
                  <Label>主題色系</Label>
                  <div className="space-y-2">
                    <div className="grid grid-cols-5 gap-2">
                      {darkThemes.map(t => <Swatch key={t.id} t={t} active={themeId === t.id} onSelect={handleTheme} />)}
                    </div>
                    <div className="grid grid-cols-5 gap-2">
                      {lightThemes.map(t => <Swatch key={t.id} t={t} active={themeId === t.id} onSelect={handleTheme} />)}
                    </div>
                  </div>
                  <Divider />
                  <Label>字體大小</Label>
                  <div className="flex gap-1.5 p-1 rounded-xl" style={{ background: 'rgba(128,128,128,0.08)' }}>
                    {FONT_SIZE_OPTIONS.map(f => (
                      <button
                        key={f.value}
                        onClick={() => handleFont(f.value)}
                        className="flex-1 py-1.5 rounded-lg text-xs font-medium transition-all"
                        style={{
                          background: fontSize === f.value ? 'var(--card-bg)' : 'transparent',
                          color:      fontSize === f.value ? 'var(--text-1)' : 'var(--text-3)',
                          boxShadow:  fontSize === f.value ? '0 1px 4px rgba(0,0,0,0.15)' : 'none',
                        }}
                      >
                        {f.label}
                      </button>
                    ))}
                  </div>
                </Card>

              {/* AI 服務 */}
              <Card>
                  <Label>AI 服務商</Label>
                  <div className="flex flex-wrap gap-1.5">
                    {AI_PROVIDERS.map(p => (
                      <button
                        key={p.id}
                        onClick={() => { setProviderId(p.id); setTestState('idle') }}
                        className="flex items-center gap-1 px-3 py-1.5 rounded-xl text-xs font-medium transition-all"
                        style={{
                          background: providerId === p.id ? 'var(--accent)' : 'rgba(128,128,128,0.1)',
                          color:      providerId === p.id ? '#000' : 'var(--text-2)',
                        }}
                      >
                        {p.displayName}
                        {p.hasFreetier && <span className="opacity-60 text-xs">·免費</span>}
                      </button>
                    ))}
                  </div>

                  <Divider />

                  <Label>API Key</Label>
                  <div
                    className="flex items-center gap-2 px-3 py-2.5 rounded-xl"
                    style={{ background: 'rgba(128,128,128,0.08)' }}
                  >
                    <input
                      type="password"
                      placeholder={provider.apiKeyPlaceholder}
                      value={apiKeys[providerId] ?? ''}
                      onChange={e => { setApiKeys(p => ({ ...p, [providerId]: e.target.value })); setTestState('idle') }}
                      className="flex-1 bg-transparent text-xs font-mono min-w-0"
                      style={{ color: 'var(--text-1)' }}
                    />
                    {apiKeys[providerId] && (
                      <button
                        onClick={() => { setApiKeys(p => ({ ...p, [providerId]: '' })); setTestState('idle') }}
                        className="shrink-0"
                        style={{ color: 'var(--text-3)' }}
                      >
                        <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd"/>
                        </svg>
                      </button>
                    )}
                    <button onClick={paste} className="shrink-0" style={{ color: 'var(--accent)' }}>
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184"/>
                      </svg>
                    </button>
                  </div>

                  <div className="flex items-center justify-between mt-1.5">
                    <span className="text-xs" style={{ color: 'var(--text-3)' }}>{provider.consoleURL}</span>
                    <button
                      onClick={testKey}
                      disabled={!apiKeys[providerId]?.trim() || testState === 'testing'}
                      className="flex items-center gap-1 text-xs disabled:opacity-40 transition-colors"
                      style={{ color: testColor }}
                    >
                      {testState === 'testing'
                        ? <svg className="animate-spin w-3 h-3" viewBox="0 0 24 24" fill="none"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                        : testState === 'success'
                        ? <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                        : typeof testState === 'object'
                        ? <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd"/></svg>
                        : <svg className="w-3 h-3" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                      }
                      {testState === 'success' ? '有效 ✓' : testState === 'testing' ? '測試中…' : typeof testState === 'object' ? testState.error : '測試連線'}
                    </button>
                  </div>

                  <Divider />

                  <Label>模型</Label>
                  <div className="space-y-1">
                    {provider.models.map(m => (
                      <button
                        key={m.id}
                        onClick={() => setModels(p => ({ ...p, [providerId]: m.id }))}
                        className="flex items-center justify-between w-full px-3 py-2 rounded-xl transition-colors"
                        style={{ background: currentModel === m.id ? 'rgba(128,128,128,0.1)' : 'transparent' }}
                      >
                        <div className="flex items-center gap-2 text-left">
                          <span
                            className="w-3.5 h-3.5 rounded-full border-2 shrink-0 flex items-center justify-center"
                            style={{ borderColor: currentModel === m.id ? 'var(--accent)' : 'var(--text-3)' }}
                          >
                            {currentModel === m.id && (
                              <span className="w-1.5 h-1.5 rounded-full" style={{ background: 'var(--accent)' }} />
                            )}
                          </span>
                          <span className="text-xs" style={{ color: 'var(--text-1)' }}>{m.name}</span>
                        </div>
                        <span className="text-xs" style={{ color: 'var(--text-3)' }}>{m.note}</span>
                      </button>
                    ))}
                  </div>
                </Card>

              {/* 新聞來源 */}
              <Card>
                  <button onClick={() => setFeedsOpen(o => !o)} className="flex items-center justify-between w-full">
                    <Label>新聞來源</Label>
                    <div className="flex items-center gap-1.5">
                      <span className="text-xs" style={{ color: 'var(--text-3)' }}>
                        {FEEDS.length - disabledFeeds.length} / {FEEDS.length}
                      </span>
                      <svg
                        className={`w-3.5 h-3.5 transition-transform ${feedsOpen ? 'rotate-180' : ''}`}
                        style={{ color: 'var(--text-3)' }}
                        fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"
                      >
                        <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7"/>
                      </svg>
                    </div>
                  </button>
                  {feedsOpen && (
                    <div className="space-y-0.5 mt-1">
                      {FEEDS.map(f => {
                        const on = !disabledFeeds.includes(f.name)
                        return (
                          <button
                            key={f.name}
                            onClick={() => handleFeedToggle(f.name)}
                            className="flex items-center gap-2.5 w-full px-1 py-2 rounded-xl"
                            style={{ background: 'transparent' }}
                          >
                            <span
                              className="relative shrink-0 w-8 h-4 rounded-full transition-colors"
                              style={{ background: on ? 'var(--accent)' : 'rgba(128,128,128,0.25)' }}
                            >
                              <span
                                className="absolute top-0.5 w-3 h-3 rounded-full bg-white shadow transition-all"
                                style={{ left: on ? '18px' : '2px' }}
                              />
                            </span>
                            <span
                              className="text-xs font-bold px-1.5 py-0.5 rounded shrink-0"
                              style={{ background: 'rgba(128,128,128,0.1)', color: on ? 'var(--accent)' : 'var(--text-3)', fontSize: 10 }}
                            >
                              {f.abbr}
                            </span>
                            <span className="text-xs" style={{ color: on ? 'var(--text-2)' : 'var(--text-3)' }}>{f.name}</span>
                          </button>
                        )
                      })}
                    </div>
                  )}
                </Card>

              {/* 關鍵字追蹤 */}
              <Card>
                  <Label>關鍵字追蹤</Label>
                  <div className="flex items-center gap-2">
                    <input
                      type="text"
                      placeholder="新增關鍵字…"
                      value={kwInput}
                      onChange={e => setKwInput(e.target.value)}
                      onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); addKeyword() } }}
                      className="flex-1 bg-transparent text-xs px-3 py-2 rounded-xl"
                      style={{ background: 'rgba(128,128,128,0.08)', color: 'var(--text-1)' }}
                    />
                    <button
                      onClick={addKeyword}
                      className="px-3 py-2 rounded-xl text-xs font-medium shrink-0"
                      style={{ background: 'var(--accent)', color: '#000' }}
                    >
                      新增
                    </button>
                  </div>
                  {keywords.length > 0 && (
                    <div className="flex flex-wrap gap-1.5 mt-1">
                      {keywords.map(kw => (
                        <span
                          key={kw}
                          className="flex items-center gap-1 px-2 py-1 rounded-xl text-xs"
                          style={{ background: 'rgba(128,128,128,0.12)', color: 'var(--text-1)' }}
                        >
                          {kw}
                          <button
                            onClick={() => removeKeyword(kw)}
                            className="leading-none"
                            style={{ color: 'var(--text-3)' }}
                            aria-label={`移除 ${kw}`}
                          >
                            ×
                          </button>
                        </span>
                      ))}
                    </div>
                  )}
                </Card>

            </div>{/* end cards */}

          </div>{/* end body */}
        </div>
      </div>
    </>
  )
}

// ── Sub-components ──────────────────────────────────────────

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-2xl p-4 space-y-3" style={{ background: 'var(--card-bg)' }}>
      {children}
    </div>
  )
}

function Label({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs font-semibold uppercase tracking-widest" style={{ color: 'var(--text-3)', letterSpacing: '0.08em' }}>
      {children}
    </p>
  )
}

function Divider() {
  return <div className="h-px -mx-4" style={{ background: 'var(--separator)' }} />
}

function Swatch({ t, active, onSelect }: { t: Theme; active: boolean; onSelect: (id: ThemeId) => void }) {
  return (
    <button onClick={() => onSelect(t.id)} className="flex flex-col items-center gap-1">
      <span
        className="w-10 h-10 rounded-xl relative overflow-hidden transition-all"
        style={{
          background: t.vars['--page-bg'],
          boxShadow: active ? `0 0 0 2px var(--accent)` : `0 0 0 1px rgba(128,128,128,0.18)`,
        }}
      >
        <span className="absolute inset-x-1.5 top-1.5 bottom-1.5 rounded-lg" style={{ background: t.vars['--card-bg'] }} />
        <span className="absolute bottom-2 right-2 w-2 h-2 rounded-full" style={{ background: t.vars['--accent'] }} />
      </span>
      <span style={{ fontSize: 10, color: active ? 'var(--accent)' : 'var(--text-3)' }}>{t.name}</span>
    </button>
  )
}
