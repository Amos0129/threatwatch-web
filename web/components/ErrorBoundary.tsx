'use client'

import { Component, ReactNode } from 'react'

interface Props { children: ReactNode }
interface State { error: Error | null }

export default class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null }

  static getDerivedStateFromError(error: Error): State {
    return { error }
  }

  render() {
    if (this.state.error) {
      return (
        <div className="min-h-screen flex flex-col items-center justify-center gap-4 px-6"
          style={{ background: 'var(--page-bg)' }}>
          <svg className="w-12 h-12" style={{ color: 'var(--text-3)' }} fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
          </svg>
          <p className="text-sm font-medium" style={{ color: 'var(--text-1)' }}>發生了一些錯誤</p>
          <p className="text-xs text-center" style={{ color: 'var(--text-3)' }}>{this.state.error.message}</p>
          <button
            onClick={() => { this.setState({ error: null }); window.location.reload() }}
            className="px-5 py-2 rounded-xl text-sm font-medium"
            style={{ background: 'var(--card-bg)', color: 'var(--accent)' }}
          >
            重新整理
          </button>
        </div>
      )
    }
    return this.props.children
  }
}
