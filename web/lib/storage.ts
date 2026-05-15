// 統一管理所有 localStorage 存取，元件層不直接操作 localStorage

import { AI_PROVIDERS, getProvider } from './aiProviders'

export type ViewMode  = 'list' | 'grid2' | 'grid3'
export type FontSize  = 'sm' | 'md' | 'lg' | 'xl'

export const FONT_SIZE_OPTIONS: { value: FontSize; label: string; px: number }[] = [
  { value: 'sm', label: '小',  px: 14 },
  { value: 'md', label: '中',  px: 16 },
  { value: 'lg', label: '大',  px: 18 },
  { value: 'xl', label: '特大', px: 20 },
]

const KEYS = {
  provider:      'selected_provider',
  apiKey:        (id: string) => `${id}_api_key`,
  model:         (id: string) => `selected_model_${id}`,
  viewMode:      'view_mode',
  theme:         'theme',
  fontSize:      'font_size',
  disabledFeeds: 'disabled_feeds',
}

export function getSelectedProviderId(): string {
  return localStorage.getItem(KEYS.provider) ?? 'claude'
}

export function setSelectedProviderId(id: string): void {
  localStorage.setItem(KEYS.provider, id)
}

export function getApiKey(providerId: string): string {
  return localStorage.getItem(KEYS.apiKey(providerId))?.trim() ?? ''
}

export function setApiKey(providerId: string, key: string): void {
  localStorage.setItem(KEYS.apiKey(providerId), key.trim())
}

export function getSelectedModel(providerId: string): string {
  const fallback = getProvider(providerId).models[0].id
  return localStorage.getItem(KEYS.model(providerId)) ?? fallback
}

export function setSelectedModel(providerId: string, modelId: string): void {
  localStorage.setItem(KEYS.model(providerId), modelId)
}

/** 一次取得當前選定的 provider / apiKey / modelId */
export function getActiveSettings(): { providerId: string; apiKey: string; modelId: string } {
  const providerId = getSelectedProviderId()
  return {
    providerId,
    apiKey:  getApiKey(providerId),
    modelId: getSelectedModel(providerId),
  }
}

export function getViewMode(): ViewMode {
  return (localStorage.getItem(KEYS.viewMode) as ViewMode) ?? 'list'
}
export function setViewMode(mode: ViewMode): void {
  localStorage.setItem(KEYS.viewMode, mode)
}

export function getThemeId(): string {
  return localStorage.getItem(KEYS.theme) ?? 'dark'
}
export function setThemeId(id: string): void {
  localStorage.setItem(KEYS.theme, id)
}

export function getFontSize(): FontSize {
  return (localStorage.getItem(KEYS.fontSize) as FontSize) ?? 'lg'
}
export function setFontSize(size: FontSize): void {
  localStorage.setItem(KEYS.fontSize, size)
}

export function getDisabledFeeds(): string[] {
  if (typeof window === 'undefined') return []
  try { return JSON.parse(localStorage.getItem(KEYS.disabledFeeds) ?? '[]') } catch { return [] }
}
export function setDisabledFeeds(names: string[]): void {
  if (typeof window === 'undefined') return
  localStorage.setItem(KEYS.disabledFeeds, JSON.stringify(names))
}

/** 儲存設定頁所有欄位 */
export function saveAllSettings(
  providerId: string,
  apiKeys: Record<string, string>,
  models: Record<string, string>
): void {
  setSelectedProviderId(providerId)
  for (const p of AI_PROVIDERS) {
    setApiKey(p.id, apiKeys[p.id] ?? '')
    setSelectedModel(p.id, models[p.id] ?? p.models[0].id)
  }
}
