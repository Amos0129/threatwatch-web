//
//  DesignSystem.swift
//  ThreatWatch
//
//  Single source of truth for all visual tokens and AI provider definitions.
//  Usage:  DS.Colors.accent  /  DS.Typography.body(index)  /  DS.Spacing.md
//
//  Themes are driven by AppTheme.shared (an @Observable singleton).
//  Any view that reads DS.Colors.* will automatically re-render on theme change.
//

import SwiftUI

// MARK: - Theme Definition

struct ThemeDefinition: Identifiable {
    let id:            String
    let name:          String
    let isDark:        Bool
    let pageBG:        Color
    let cardBG:        Color
    let accent:        Color
    let textPrimary:   Color
    let textSecondary: Color
    let textTertiary:  Color
    let separator:     Color

    static let all: [ThemeDefinition] = [
        // ── 深色系 ────────────────────────────────────────────────────
        .init(id: "dark",     name: "深色",   isDark: true,
              pageBG:        Color(red: 0.07, green: 0.07, blue: 0.11),
              cardBG:        Color(red: 0.12, green: 0.12, blue: 0.18),
              accent:        Color(red: 0.36, green: 0.75, blue: 0.50),
              textPrimary:   .white,
              textSecondary: Color(white: 0.60),
              textTertiary:  Color(white: 0.38),
              separator:     Color.white.opacity(0.07)),

        .init(id: "midnight", name: "午夜藍", isDark: true,
              pageBG:        Color(red: 0.051, green: 0.067, blue: 0.090),
              cardBG:        Color(red: 0.086, green: 0.106, blue: 0.133),
              accent:        Color(red: 0.345, green: 0.651, blue: 1.0),
              textPrimary:   Color(red: 0.902, green: 0.929, blue: 0.953),
              textSecondary: Color(red: 0.545, green: 0.580, blue: 0.620),
              textTertiary:  Color(red: 0.282, green: 0.310, blue: 0.345),
              separator:     Color.white.opacity(0.06)),

        .init(id: "warm",     name: "暖褐",   isDark: true,
              pageBG:        Color(red: 0.110, green: 0.094, blue: 0.078),
              cardBG:        Color(red: 0.157, green: 0.137, blue: 0.110),
              accent:        Color(red: 0.910, green: 0.659, blue: 0.220),
              textPrimary:   Color(red: 0.941, green: 0.902, blue: 0.816),
              textSecondary: Color(red: 0.659, green: 0.565, blue: 0.439),
              textTertiary:  Color(red: 0.420, green: 0.361, blue: 0.282),
              separator:     Color.white.opacity(0.07)),

        .init(id: "slate",    name: "靛藍",   isDark: true,
              pageBG:        Color(red: 0.059, green: 0.090, blue: 0.165),
              cardBG:        Color(red: 0.118, green: 0.161, blue: 0.231),
              accent:        Color(red: 0.506, green: 0.549, blue: 0.973),
              textPrimary:   Color(red: 0.945, green: 0.961, blue: 0.980),
              textSecondary: Color(red: 0.580, green: 0.639, blue: 0.722),
              textTertiary:  Color(red: 0.282, green: 0.337, blue: 0.408),
              separator:     Color.white.opacity(0.06)),

        .init(id: "forest",   name: "深林",   isDark: true,
              pageBG:        Color(red: 0.051, green: 0.102, blue: 0.059),
              cardBG:        Color(red: 0.086, green: 0.141, blue: 0.094),
              accent:        Color(red: 0.290, green: 0.871, blue: 0.502),
              textPrimary:   Color(red: 0.910, green: 0.961, blue: 0.914),
              textSecondary: Color(red: 0.525, green: 0.663, blue: 0.541),
              textTertiary:  Color(red: 0.290, green: 0.420, blue: 0.306),
              separator:     Color.white.opacity(0.06)),

        // ── 亮色系 ────────────────────────────────────────────────────
        .init(id: "light",    name: "純白",   isDark: false,
              pageBG:        Color(red: 0.949, green: 0.949, blue: 0.969),
              cardBG:        .white,
              accent:        Color(red: 0.165, green: 0.616, blue: 0.361),
              textPrimary:   Color(red: 0.067, green: 0.067, blue: 0.067),
              textSecondary: Color(red: 0.267, green: 0.267, blue: 0.267),
              textTertiary:  Color(red: 0.533, green: 0.533, blue: 0.533),
              separator:     Color.black.opacity(0.08)),

        .init(id: "sky",      name: "天藍",   isDark: false,
              pageBG:        Color(red: 0.910, green: 0.957, blue: 0.992),
              cardBG:        .white,
              accent:        Color(red: 0.008, green: 0.518, blue: 0.780),
              textPrimary:   Color(red: 0.047, green: 0.102, blue: 0.180),
              textSecondary: Color(red: 0.227, green: 0.314, blue: 0.408),
              textTertiary:  Color(red: 0.478, green: 0.604, blue: 0.690),
              separator:     Color(red: 0.008, green: 0.518, blue: 0.780).opacity(0.10)),

        .init(id: "cream",    name: "米白",   isDark: false,
              pageBG:        Color(red: 0.980, green: 0.965, blue: 0.941),
              cardBG:        .white,
              accent:        Color(red: 0.706, green: 0.325, blue: 0.035),
              textPrimary:   Color(red: 0.110, green: 0.078, blue: 0.063),
              textSecondary: Color(red: 0.361, green: 0.290, blue: 0.220),
              textTertiary:  Color(red: 0.612, green: 0.541, blue: 0.471),
              separator:     Color.black.opacity(0.07)),

        .init(id: "rose",     name: "玫瑰",   isDark: false,
              pageBG:        Color(red: 0.992, green: 0.949, blue: 0.957),
              cardBG:        .white,
              accent:        Color(red: 0.882, green: 0.114, blue: 0.282),
              textPrimary:   Color(red: 0.102, green: 0.039, blue: 0.059),
              textSecondary: Color(red: 0.420, green: 0.227, blue: 0.290),
              textTertiary:  Color(red: 0.690, green: 0.502, blue: 0.565),
              separator:     Color(red: 0.882, green: 0.114, blue: 0.282).opacity(0.08)),

        .init(id: "mint",     name: "薄荷",   isDark: false,
              pageBG:        Color(red: 0.941, green: 0.980, blue: 0.957),
              cardBG:        .white,
              accent:        Color(red: 0.020, green: 0.588, blue: 0.412),
              textPrimary:   Color(red: 0.039, green: 0.122, blue: 0.086),
              textSecondary: Color(red: 0.176, green: 0.353, blue: 0.259),
              textTertiary:  Color(red: 0.416, green: 0.667, blue: 0.533),
              separator:     Color(red: 0.020, green: 0.588, blue: 0.412).opacity(0.10)),
    ]

    static func find(_ id: String) -> ThemeDefinition {
        all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - AppTheme (Observable singleton)

@Observable
final class AppTheme {
    static let shared = AppTheme()

    private(set) var currentId: String
    private(set) var isDark:        Bool
    var pageBG:        Color
    var cardBG:        Color
    var accent:        Color
    var textPrimary:   Color
    var textSecondary: Color
    var textTertiary:  Color
    var separator:     Color
    var navBG:         Color

    private init() {
        let saved = UserDefaults.standard.string(forKey: "theme_id") ?? "dark"
        let def   = ThemeDefinition.find(saved)
        currentId     = def.id
        isDark        = def.isDark
        pageBG        = def.pageBG
        cardBG        = def.cardBG
        accent        = def.accent
        textPrimary   = def.textPrimary
        textSecondary = def.textSecondary
        textTertiary  = def.textTertiary
        separator     = def.separator
        navBG         = def.pageBG
    }

    func apply(_ def: ThemeDefinition) {
        currentId     = def.id
        isDark        = def.isDark
        pageBG        = def.pageBG
        cardBG        = def.cardBG
        accent        = def.accent
        textPrimary   = def.textPrimary
        textSecondary = def.textSecondary
        textTertiary  = def.textTertiary
        separator     = def.separator
        navBG         = def.pageBG
        UserDefaults.standard.set(def.id, forKey: "theme_id")
    }
}

// MARK: - DS Tokens (read from AppTheme.shared — reactive via @Observable)

enum DS {

    enum Colors {
        static var pageBG:        Color { AppTheme.shared.pageBG }
        static var cardBG:        Color { AppTheme.shared.cardBG }
        static var accent:        Color { AppTheme.shared.accent }
        static var textPrimary:   Color { AppTheme.shared.textPrimary }
        static var textSecondary: Color { AppTheme.shared.textSecondary }
        static var textTertiary:  Color { AppTheme.shared.textTertiary }
        static var separator:     Color { AppTheme.shared.separator }
        static var navBG:         Color { AppTheme.shared.navBG }
    }

    enum Typography {
        static let sizeLabels = ["小", "標準", "大", "特大"]
        static func title(_ i: Int)   -> CGFloat { [17, 20, 23, 27][safe: i] ?? 20 }
        static func body(_ i: Int)    -> CGFloat { [13, 15, 17, 20][safe: i] ?? 15 }
        static func caption(_ i: Int) -> CGFloat { [11, 12, 14, 16][safe: i] ?? 12 }
    }

    enum Spacing {
        static let xs: CGFloat    =  4   // 最小間距
        static let sm: CGFloat    =  8   // 小間距
        static let sm2: CGFloat   = 12   // 中小間距（MD 規範補充）
        static let md: CGFloat    = 16   // 標準間距
        static let lg: CGFloat    = 24   // 大間距
        static let xl: CGFloat    = 32   // 最大間距
        static let pageH: CGFloat = 16   // 頁面水平邊距（對齊 md）
    }

    enum Radius {
        static let input:  CGFloat =  8  // input / button（MD: Medium 8px）
        static let card:   CGFloat = 12  // card（iOS 視覺適配，介於 MD medium/large 之間）
        static let modal:  CGFloat = 16  // modal / container（MD: Large 16px）
        static let chip:   CGFloat = 99  // 膠囊形狀
    }

    enum LineSpacing {
        static let tight:  CGFloat = 3
        static let normal: CGFloat = 5
        static let loose:  CGFloat = 7
    }
}

// MARK: - AI Provider Definitions

struct AIModelOption: Identifiable {
    let id: String
    let name: String
    let note: String
}

enum AIProvider: String, CaseIterable, Identifiable {
    case claude  = "claude"
    case openAI  = "openai"
    case gemini  = "gemini"
    case groq    = "groq"
    case xai     = "xai"
    case mistral = "mistral"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude:  return "Claude"
        case .openAI:  return "ChatGPT"
        case .gemini:  return "Gemini"
        case .groq:    return "Groq"
        case .xai:     return "Grok (xAI)"
        case .mistral: return "Mistral"
        }
    }

    var companyName: String {
        switch self {
        case .claude:  return "Anthropic"
        case .openAI:  return "OpenAI"
        case .gemini:  return "Google"
        case .groq:    return "Groq"
        case .xai:     return "xAI"
        case .mistral: return "Mistral AI"
        }
    }

    var hasFreetier: Bool {
        switch self {
        case .gemini, .groq: return true
        default:             return false
        }
    }

    var apiKeyStorageKey: String { "\(rawValue)_api_key" }

    var apiKeyPlaceholder: String {
        switch self {
        case .claude:  return "sk-ant-…"
        case .openAI:  return "sk-proj-…"
        case .gemini:  return "AIza…"
        case .groq:    return "gsk_…"
        case .xai:     return "xai-…"
        case .mistral: return "…"
        }
    }

    var consoleURL: String {
        switch self {
        case .claude:  return "console.anthropic.com"
        case .openAI:  return "platform.openai.com/api-keys"
        case .gemini:  return "aistudio.google.com/app/apikey"
        case .groq:    return "console.groq.com/keys"
        case .xai:     return "console.x.ai"
        case .mistral: return "console.mistral.ai/api-keys"
        }
    }

    var models: [AIModelOption] {
        switch self {
        case .claude:
            return [
                .init(id: "claude-haiku-4-5-20251001", name: "Claude Haiku 4.5",  note: "最快、最省費用"),
                .init(id: "claude-sonnet-4-6",         name: "Claude Sonnet 4.6", note: "速度與品質平衡"),
                .init(id: "claude-opus-4-6",           name: "Claude Opus 4.6",   note: "最強，費用較高"),
            ]
        case .openAI:
            return [
                .init(id: "gpt-4o-mini",  name: "GPT-4o mini",  note: "快速、低成本"),
                .init(id: "gpt-4o",       name: "GPT-4o",       note: "高品質"),
                .init(id: "o4-mini",      name: "o4-mini",      note: "強推理能力"),
                .init(id: "o3",           name: "o3",           note: "最強推理，費用高"),
            ]
        case .gemini:
            return [
                .init(id: "gemini-2.0-flash",              name: "Gemini 2.0 Flash",  note: "快速，免費額度多"),
                .init(id: "gemini-2.5-flash-preview-04-17",name: "Gemini 2.5 Flash",  note: "最新輕量版"),
                .init(id: "gemini-1.5-flash",              name: "Gemini 1.5 Flash",  note: "輕量穩定"),
                .init(id: "gemini-1.5-pro",                name: "Gemini 1.5 Pro",    note: "高品質分析"),
                .init(id: "gemini-2.5-pro-preview-05-06",  name: "Gemini 2.5 Pro",    note: "最強，費用較高"),
            ]
        case .groq:
            return [
                .init(id: "llama-3.3-70b-versatile", name: "Llama 3.3 70B", note: "免費、品質佳"),
                .init(id: "llama-3.1-8b-instant",    name: "Llama 3.1 8B",  note: "免費、極速"),
                .init(id: "mixtral-8x7b-32768",      name: "Mixtral 8x7B",  note: "免費、長文本"),
                .init(id: "gemma2-9b-it",            name: "Gemma 2 9B",    note: "免費、Google 出品"),
            ]
        case .xai:
            return [
                .init(id: "grok-3",      name: "Grok 3",      note: "最強版本"),
                .init(id: "grok-3-mini", name: "Grok 3 Mini", note: "快速低成本"),
                .init(id: "grok-2",      name: "Grok 2",      note: "穩定版本"),
            ]
        case .mistral:
            return [
                .init(id: "mistral-small-latest",  name: "Mistral Small",  note: "輕量快速"),
                .init(id: "mistral-medium-latest", name: "Mistral Medium", note: "平衡選擇"),
                .init(id: "mistral-large-latest",  name: "Mistral Large",  note: "最強版本"),
            ]
        }
    }

    var defaultModelID: String { models[0].id }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
