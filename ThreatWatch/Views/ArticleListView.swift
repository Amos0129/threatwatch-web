//
//  ArticleListView.swift
//  ThreatWatch
//

import SwiftUI
import Translation

struct ArticleListView: View {
    @Bindable var viewModel: NewsViewModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            DS.Colors.pageBG.ignoresSafeArea()
                .onTapGesture { searchFocused = false }

            VStack(spacing: 0) {
                customHeader

                if viewModel.isOffline {
                    offlineBanner
                }
                searchBar
                externalSearchLinks
                filterChips

                countLabel
                contentArea
            }
        }
        .translationTask(viewModel.translationCoordinator.configuration) { session in
            await viewModel.translationCoordinator.performTranslation(session: session)
            // 如果蘋果翻譯沒翻到所有標題，用 AI 補上
            await viewModel.applyAITranslationFallback()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.showSettings) { SettingsView() }
        .task { await viewModel.loadNews() }
        .alert("分析失敗", isPresented: Binding(
            get: { viewModel.analysisError != nil },
            set: { if !$0 { viewModel.analysisError = nil } }
        )) {
            Button("確定", role: .cancel) { viewModel.analysisError = nil }
        } message: {
            Text(viewModel.analysisError ?? "")
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        VStack(spacing: 0) {
            ZStack {
                // Center: logo（真正置中）
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "shield.lefthalf.filled.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                    Text("ThreatWatch")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }

                // Left + Right 疊在 ZStack 上
                HStack {
                    // 重新整理（含 badge）
                    Button { Task { await viewModel.loadNews() } } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 17))
                                .foregroundStyle(DS.Colors.accent)
                            if viewModel.newCount > 0 {
                                Text(viewModel.newCount > 99 ? "99+" : "\(viewModel.newCount)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, DS.Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(.red)
                                    .clipShape(Capsule())
                                    .offset(x: 12, y: -8)
                            }
                        }
                    }

                    Spacer()

                    // 所有選項收進一個 Menu
                    Menu {
                        Button {
                            viewModel.toggleTranslation()
                        } label: {
                            Label(
                                viewModel.showTranslation ? "關閉標題翻譯" : "開啟標題翻譯",
                                systemImage: viewModel.showTranslation ? "character.bubble.fill" : "character.bubble"
                            )
                        }

                        Divider()

                        Button { viewModel.showSettings = true } label: {
                            Label("設定", systemImage: "gearshape")
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 17))
                                .foregroundStyle(viewModel.showTranslation ? DS.Colors.accent : DS.Colors.textSecondary)
                            if viewModel.translationCoordinator.isTranslating {
                                Circle()
                                    .fill(DS.Colors.accent)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.pageH)
            .padding(.vertical, DS.Spacing.sm)

            Rectangle()
                .fill(DS.Colors.separator)
                .frame(height: 1)
        }
        .background(DS.Colors.navBG)
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12))
            Text("離線模式 — 顯示上次載入的內容")
                .font(.system(size: 12))
            Spacer()
            Button("重試") { Task { await viewModel.loadNews() } }
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, DS.Spacing.pageH)
        .padding(.vertical, DS.Spacing.sm)
        .background(Color.orange.opacity(0.85))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.Colors.textTertiary)
                .font(.system(size: 15))
            TextField("搜尋新聞、來源…", text: $viewModel.searchText)
                .foregroundStyle(DS.Colors.textPrimary)
                .autocorrectionDisabled()
                .tint(DS.Colors.accent)
                .focused($searchFocused)
                .onSubmit { searchFocused = false }
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    searchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DS.Colors.textTertiary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))
        .padding(.horizontal, DS.Spacing.pageH)
        .padding(.top, DS.Spacing.sm)
    }

    // MARK: - External Search Links

    @ViewBuilder
    private var externalSearchLinks: some View {
        if !viewModel.searchText.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.xs) {
                    Text("外部搜尋：")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .fixedSize()

                    ForEach(externalLinks, id: \.name) { item in
                        if let url = URL(string: item.url) {
                            Link(destination: url) {
                                Text(item.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, DS.Spacing.sm)
                                    .padding(.vertical, DS.Spacing.xs)
                                    .background(DS.Colors.cardBG)
                                    .foregroundStyle(DS.Colors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.pageH)
                .padding(.vertical, DS.Spacing.xs)
            }
        }
    }

    private var externalLinks: [(name: String, url: String)] {
        let q = viewModel.searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return [
            ("NVD/CVE",      "https://nvd.nist.gov/vuln/search/results?query=\(q)"),
            ("VirusTotal",   "https://www.virustotal.com/gui/search/\(q)"),
            ("Shodan",       "https://www.shodan.io/search?query=\(q)"),
            ("GitHub",       "https://github.com/advisories?query=\(q)"),
            ("MITRE ATT&CK", "https://attack.mitre.org/techniques/search/?query=\(q)"),
            ("Google",       "https://www.google.com/search?q=\(q)+cybersecurity"),
        ]
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(TimeFilter.allCases) { filter in
                FilterChip(
                    title: filter.rawValue,
                    isSelected: viewModel.selectedFilter == filter
                ) { viewModel.selectedFilter = filter }
            }
        }
        .padding(.horizontal, DS.Spacing.pageH)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: - Count

    @ViewBuilder
    private var countLabel: some View {
        if !viewModel.isLoading {
            HStack {
                Text("\(viewModel.filteredArticles.count) 則新聞")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
                Spacer()
            }
            .padding(.horizontal, DS.Spacing.pageH)
            .padding(.bottom, DS.Spacing.sm)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            Spacer()
            VStack(spacing: DS.Spacing.md) {
                ProgressView().tint(DS.Colors.accent).scaleEffect(1.2)
                Text("載入中…")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            Spacer()

        } else if let err = viewModel.errorMessage {
            Spacer()
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.Colors.textTertiary)
                Text(err)
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
                Button("重新載入") { Task { await viewModel.loadNews() } }
                    .buttonStyle(.bordered)
                    .tint(DS.Colors.accent)
            }
            Spacer()

        } else if viewModel.filteredArticles.isEmpty {
            Spacer()
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: viewModel.searchText.isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.Colors.textTertiary)
                Text(viewModel.searchText.isEmpty
                     ? "此時間範圍內沒有新聞"
                     : "找不到符合「\(viewModel.searchText)」的新聞")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
                if !viewModel.searchText.isEmpty {
                    Button("清除搜尋") {
                        viewModel.searchText = ""
                        searchFocused = false
                    }
                    .buttonStyle(.bordered)
                    .tint(DS.Colors.accent)
                }
            }
            Spacer()

        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredArticles) { article in
                        NavigationLink {
                            ArticleDetailView(articleLink: article.link, viewModel: viewModel)
                        } label: {
                            ArticleRowView(
                                article:         article,
                                displayTitle:    viewModel.displayTitle(for: article),
                                isRead:          viewModel.isRead(article.link),
                                isBookmarked:    viewModel.isBookmarked(article.link),
                                matchedKeywords: viewModel.matchedKeywords(for: article)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DS.Spacing.pageH)
                        .padding(.vertical, DS.Spacing.xs)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .refreshable { await viewModel.loadNews() }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.sm)
                .background(isSelected ? DS.Colors.accent : DS.Colors.cardBG)
                .foregroundStyle(isSelected ? Color.black : DS.Colors.textSecondary)
                .clipShape(Capsule())
        }
    }
}
