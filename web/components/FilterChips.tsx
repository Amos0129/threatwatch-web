'use client'

import { TIME_FILTERS, TimeFilter } from '@/lib/types'

interface Props {
  selected: TimeFilter
  onChange: (f: TimeFilter) => void
}

export default function FilterChips({ selected, onChange }: Props) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none" style={{ scrollbarWidth: 'none' }}>
      {TIME_FILTERS.map(f => (
        <button
          key={f.value}
          onClick={() => onChange(f.value)}
          className="shrink-0 px-4 py-1.5 rounded-full text-sm font-medium transition-colors"
          style={{
            background: selected === f.value ? 'var(--accent)' : 'var(--card-bg)',
            color:      selected === f.value ? '#000' : 'var(--text-2)',
          }}
        >
          {f.label}
        </button>
      ))}
    </div>
  )
}
