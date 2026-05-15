//
//  SettingsView.swift
//  ThreatWatch
//

import SwiftUI

struct SettingsView: View {

    @AppStorage("selected_provider") private var selectedProviderRaw = AIProvider.claude.rawValue
    @AppStorage("font_size_index")   private var fontSizeIndex = 1

    @State private var testStates:     [String: TestState] = [:]
    @State private var apiKeys:        [String: String]    = [:]
    @State private var selectedModels: [String: String]    = [:]
    @State private var selectedThemeId = AppTheme.shared.currentId
    @State private var feedsExpanded   = false

    @FocusState private var keyFocused: Bool
    @Environment(\.dismiss)           private var dismiss
    @Environment(AppEnvironment.self) private var env

    private var vm: NewsViewModel { env.newsViewModel }
    private var provider: AIProvider { AIProvider(rawValue: selectedProviderRaw) ?? .claude }

    // MARK: - TestState

    enum TestState: Equatable {
        case idle, testing, success, failure(String)
        var color: Color {
            switch self {
            case .idle:    return .gray
            case .testing: return .orange
            case .success: return .green
            case .failure: return .red
            }
        }
        var label: String {
            switch self {
            case .idle:           return "測試連線"
            case .testing:        return "測試中…"
            case .success:        return "有效 ✓"
            case .failure(let m): return m
            }
        }
        var icon: String {
            switch self {
            case .idle:    return "checkmark.circle"
            case .testing: return "clock"
            case .success: return "checkmark.circle.fill"
            case .failure: return "xmark.circle.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DS.Colors.pageBG.ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle
                sheetHeader
                Rectangle().fill(DS.Colors.separator).frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        appearanceCard
                        aiCard
                        feedsCard
                        tokenTipCard
                    }
                    .padding(DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.xl)
                }
            }
        }
        .onAppear { loadFromDefaults() }
    }

    // MARK: - Sheet Chrome

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(DS.Colors.textTertiary.opacity(0.4))
            .frame(width: 36, height: 4)
            .padding(.top, DS.Spacing.sm)
    }

    private var sheetHeader: some View {
        HStack {
            Button("取消") { dismiss() }
                .font(.system(size: 15))
                .foregroundStyle(DS.Colors.textTertiary)
            Spacer()
            Text("設定")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Button("儲存") { save(); dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm2)
    }

    // MARK: - 1. 外觀

    private var appearanceCard: some View {
        Card {
            SectionLabel("主題", icon: "paintpalette")

            let darkThemes  = ThemeDefinition.all.filter { $0.isDark }
            let lightThemes = ThemeDefinition.all.filter { !$0.isDark }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("深色")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.textTertiary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DS.Spacing.sm) {
                    ForEach(darkThemes) { t in
                        ThemeSwatch(t: t, selected: selectedThemeId == t.id) { applyTheme(t) }
                    }
                }
                Text("亮色")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.textTertiary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DS.Spacing.sm) {
                    ForEach(lightThemes) { t in
                        ThemeSwatch(t: t, selected: selectedThemeId == t.id) { applyTheme(t) }
                    }
                }
            }

            CardDivider()

            SectionLabel("字體大小", icon: "textformat.size")

            HStack(spacing: DS.Spacing.xs) {
                ForEach(0..<DS.Typography.sizeLabels.count, id: \.self) { i in
                    Button { fontSizeIndex = i } label: {
                        Text(DS.Typography.sizeLabels[i])
                            .font(.system(size: 13, weight: fontSizeIndex == i ? .semibold : .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(fontSizeIndex == i ? DS.Colors.accent : DS.Colors.pageBG)
                            .foregroundStyle(fontSizeIndex == i ? Color.black : DS.Colors.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))
                    }
                }
            }

            Text("ThreatWatch 資安新聞 — 預覽文字")
                .font(.system(size: DS.Typography.body(fontSizeIndex)))
                .foregroundStyle(DS.Colors.textTertiary)
        }
    }

    // MARK: - 2. AI

    private var aiCard: some View {
        Card {
            SectionLabel("AI 服務商", icon: "cpu")

            // 3 + 3 整齊排列
            let all  = AIProvider.allCases
            let row1 = Array(all.prefix(3))
            let row2 = Array(all.dropFirst(3))

            VStack(spacing: DS.Spacing.sm) {
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(row1) { p in providerChip(p) }
                }
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(row2) { p in providerChip(p) }
                }
            }

            CardDivider()

            SectionLabel("\(provider.displayName) API Key", icon: "key.fill")

            // Key 輸入框
            HStack(spacing: DS.Spacing.sm) {
                SecureField(provider.apiKeyPlaceholder, text: apiKeyBinding(for: provider))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($keyFocused)
                    .onChange(of: apiKeys[provider.apiKeyStorageKey]) {
                        testStates[provider.rawValue] = .idle
                    }

                if !(apiKeys[provider.apiKeyStorageKey] ?? "").isEmpty {
                    Button {
                        apiKeys[provider.apiKeyStorageKey] = ""
                        testStates[provider.rawValue] = .idle
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DS.Colors.textTertiary)
                    }
                }

                Button {
                    if let s = UIPasteboard.general.string {
                        apiKeys[provider.apiKeyStorageKey] = s.trimmingCharacters(in: .whitespacesAndNewlines)
                        testStates[provider.rawValue] = .idle
                    }
                    keyFocused = false
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundStyle(DS.Colors.accent)
                }
            }
            .padding(DS.Spacing.sm2)
            .background(DS.Colors.pageBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))

            // Console URL + 測試按鈕
            HStack {
                Text(provider.consoleURL)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .lineLimit(1)
                Spacer()

                let state = testStates[provider.rawValue] ?? .idle
                Button {
                    keyFocused = false
                    Task { await testAPIKey(provider: provider) }
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        if case .testing = state {
                            ProgressView().scaleEffect(0.7).tint(state.color)
                        } else {
                            Image(systemName: state.icon).font(.system(size: 11))
                        }
                        Text(state.label)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(state.color)
                }
                .disabled(
                    (apiKeys[provider.apiKeyStorageKey] ?? "").trimmingCharacters(in: .whitespaces).isEmpty ||
                    state == .testing
                )
            }

            CardDivider()

            SectionLabel("模型選擇", icon: "slider.horizontal.3")

            VStack(spacing: 0) {
                ForEach(provider.models) { model in
                    let key    = "selected_model_\(provider.rawValue)"
                    let picked = (selectedModels[key] ?? provider.defaultModelID) == model.id
                    Button { selectedModels[key] = model.id } label: {
                        HStack(spacing: DS.Spacing.sm2) {
                            ZStack {
                                Circle()
                                    .strokeBorder(picked ? DS.Colors.accent : DS.Colors.textTertiary, lineWidth: 1.5)
                                    .frame(width: 16, height: 16)
                                if picked {
                                    Circle().fill(DS.Colors.accent).frame(width: 8, height: 8)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.system(size: 14))
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Text(model.note)
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Colors.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, DS.Spacing.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 3. 新聞來源

    private var feedsCard: some View {
        Card {
            Button { withAnimation(.easeInOut(duration: 0.2)) { feedsExpanded.toggle() } } label: {
                HStack {
                    SectionLabel("新聞來源", icon: "newspaper")
                    Spacer()
                    Text("\(cybersecurityFeeds.count - vm.disabledFeeds.count) / \(cybersecurityFeeds.count)")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textTertiary)
                    Image(systemName: feedsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if feedsExpanded {
                VStack(spacing: 0) {
                    ForEach(cybersecurityFeeds, id: \.name) { feed in
                        HStack {
                            Image(systemName: feed.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Colors.textTertiary)
                                .frame(width: 20)
                            Text(feed.name)
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Colors.textPrimary)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { !vm.disabledFeeds.contains(feed.name) },
                                set: { _ in vm.toggleFeed(feed.name) }
                            ))
                            .labelsHidden()
                            .tint(DS.Colors.accent)
                            .scaleEffect(0.85)
                        }
                        .padding(.vertical, DS.Spacing.xs)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text("關閉的來源不會出現在列表中")
                .font(.system(size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
        }
    }

    // MARK: - 4. Token Tip

    private var tokenTipCard: some View {
        Card {
            HStack(alignment: .top, spacing: DS.Spacing.sm2) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("節省 Token 策略")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("單篇按需分析，點進文章才觸發。已分析文章從本地快取讀取，不重複呼叫。")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .lineSpacing(DS.LineSpacing.tight)
                }
            }
        }
    }

    // MARK: - Provider Chip

    private func providerChip(_ p: AIProvider) -> some View {
        Button { selectedProviderRaw = p.rawValue; testStates[p.rawValue] = .idle } label: {
            Text(p.displayName)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.sm)
                .background(selectedProviderRaw == p.rawValue ? DS.Colors.accent : DS.Colors.pageBG)
                .foregroundStyle(selectedProviderRaw == p.rawValue ? Color.black : DS.Colors.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))
        }
    }

    // MARK: - Helpers

    private func applyTheme(_ def: ThemeDefinition) {
        selectedThemeId = def.id
        AppTheme.shared.apply(def)
    }

    private func apiKeyBinding(for p: AIProvider) -> Binding<String> {
        Binding(
            get: { apiKeys[p.apiKeyStorageKey] ?? "" },
            set: { apiKeys[p.apiKeyStorageKey] = $0 }
        )
    }

    private func loadFromDefaults() {
        let ud = UserDefaults.standard
        for p in AIProvider.allCases {
            apiKeys[p.apiKeyStorageKey] = ud.string(forKey: p.apiKeyStorageKey) ?? ""
            let mKey = "selected_model_\(p.rawValue)"
            selectedModels[mKey] = ud.string(forKey: mKey) ?? p.defaultModelID
        }
    }

    private func save() {
        let ud = UserDefaults.standard
        for p in AIProvider.allCases {
            ud.set(apiKeys[p.apiKeyStorageKey]?.trimmingCharacters(in: .whitespaces) ?? "", forKey: p.apiKeyStorageKey)
            let mKey = "selected_model_\(p.rawValue)"
            ud.set(selectedModels[mKey] ?? p.defaultModelID, forKey: mKey)
        }
    }

    // MARK: - API Test

    private func testAPIKey(provider: AIProvider) async {
        let key = (apiKeys[provider.apiKeyStorageKey] ?? "").trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        testStates[provider.rawValue] = .testing
        do {
            let status = try await performTest(provider: provider, key: key)
            switch status {
            case 200: testStates[provider.rawValue] = .success
            case 401: testStates[provider.rawValue] = .failure("Key 無效或已過期")
            case 429: testStates[provider.rawValue] = .failure("超過使用限額")
            default:  testStates[provider.rawValue] = .failure("HTTP \(status)")
            }
        } catch {
            testStates[provider.rawValue] = .failure("網路錯誤")
        }
    }

    private func performTest(provider: AIProvider, key: String) async throws -> Int {
        let req: URLRequest
        switch provider {
        case .claude:
            struct P: Encodable { let model: String; let max_tokens: Int; let messages: [[String:String]] }
            var r = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            r.httpMethod = "POST"
            r.setValue(key, forHTTPHeaderField: "x-api-key")
            r.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            r.setValue("application/json", forHTTPHeaderField: "content-type")
            r.httpBody = try JSONEncoder().encode(P(model: provider.defaultModelID, max_tokens: 16, messages: [["role":"user","content":"hi"]]))
            req = r
        case .gemini:
            struct Part: Encodable { let text: String }
            struct Cont: Encodable { let parts: [Part] }
            struct P: Encodable { let contents: [Cont] }
            let url = "https://generativelanguage.googleapis.com/v1beta/models/\(provider.defaultModelID):generateContent?key=\(key)"
            var r = URLRequest(url: URL(string: url)!)
            r.httpMethod = "POST"; r.setValue("application/json", forHTTPHeaderField: "content-type")
            r.httpBody = try JSONEncoder().encode(P(contents: [.init(parts: [.init(text: "hi")])]))
            req = r
        case .openAI, .groq, .xai, .mistral:
            struct Msg: Encodable { let role: String; let content: String }
            struct P: Encodable { let model: String; let messages: [Msg]; let max_tokens: Int }
            let base: String
            switch provider {
            case .openAI: base = "https://api.openai.com/v1"
            case .groq:   base = "https://api.groq.com/openai/v1"
            case .xai:    base = "https://api.x.ai/v1"
            default:      base = "https://api.mistral.ai/v1"
            }
            var r = URLRequest(url: URL(string: "\(base)/chat/completions")!)
            r.httpMethod = "POST"
            r.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            r.setValue("application/json", forHTTPHeaderField: "content-type")
            r.httpBody = try JSONEncoder().encode(P(model: provider.defaultModelID, messages: [.init(role:"user",content:"hi")], max_tokens: 16))
            req = r
        }
        let (_, response) = try await URLSession.shared.data(for: req)
        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }
}

// MARK: - Sub-components

private struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm2) {
            content()
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

private struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Colors.separator)
            .frame(height: 1)
            .padding(.horizontal, -DS.Spacing.md)
    }
}

private struct SectionLabel: View {
    let text: String
    let icon: String
    init(_ text: String, icon: String) { self.text = text; self.icon = icon }
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }
}

private struct ThemeSwatch: View {
    let t: ThemeDefinition
    let selected: Bool
    let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: DS.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(t.pageBG)
                        .frame(width: 44, height: 44)
                        .overlay { RoundedRectangle(cornerRadius: 7).fill(t.cardBG).padding(5) }
                        .overlay(alignment: .bottomTrailing) {
                            Circle().fill(t.accent).frame(width: 10, height: 10).padding(5)
                        }
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(selected ? t.accent : Color.gray.opacity(0.2),
                                      lineWidth: selected ? 2 : 1)
                        .frame(width: 44, height: 44)
                }
                Text(t.name)
                    .font(.system(size: 9))
                    .foregroundStyle(selected ? DS.Colors.accent : DS.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
