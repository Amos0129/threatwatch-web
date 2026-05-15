//
//  ArticleDetailView.swift
//  ThreatWatch
//

import SwiftUI

struct ArticleDetailView: View {
    let articleLink: String
    let viewModel: NewsViewModel

    @AppStorage("font_size_index") private var sizeIndex = 1
    @Environment(\.dismiss) private var dismiss

    /// 使用者是否想看中文描述（預設跟隨全局翻譯開關）
    @State private var showDescTranslation = false
    @State private var isTranslatingDesc   = false

    private var article: NewsArticle? { viewModel.articleData(for: articleLink) }

    private var hasActiveAPIKey: Bool {
        let ud = UserDefaults.standard
        let providerRaw = ud.string(forKey: "selected_provider") ?? AIProvider.claude.rawValue
        let provider = AIProvider(rawValue: providerRaw) ?? .claude
        return !(ud.string(forKey: provider.apiKeyStorageKey) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            DS.Colors.pageBG.ignoresSafeArea()

            if let article {
                VStack(spacing: 0) {
                    customHeader(article)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            titleBlock(article)
                            aiSection(article)
                            originalSection(article)
                            openLinkButton(article)
                        }
                        .padding(.horizontal, DS.Spacing.pageH)
                        .padding(.bottom, DS.Spacing.xl)
                    }
                }
            } else {
                VStack(spacing: DS.Spacing.md) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 36))
                        .foregroundStyle(DS.Colors.textTertiary)
                    Text("找不到文章")
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.markRead(articleLink)
            showDescTranslation = false
        }
    }

    // MARK: - Custom Header

    private func customHeader(_ article: NewsArticle) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button { dismiss() } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 15))
                    }
                    .foregroundStyle(DS.Colors.accent)
                }
                .frame(minWidth: 70, alignment: .leading)

                Spacer()

                Text(article.source)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: DS.Spacing.lg) {
                    Button { viewModel.toggleBookmark(article: article) } label: {
                        Image(systemName: viewModel.isBookmarked(article.link) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 17))
                            .foregroundStyle(viewModel.isBookmarked(article.link) ? DS.Colors.accent : DS.Colors.textSecondary)
                    }
                    if let url = URL(string: article.link) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17))
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                }
                .frame(minWidth: 70, alignment: .trailing)
            }
            .padding(.horizontal, DS.Spacing.pageH)
            .padding(.vertical, DS.Spacing.sm)

            line
        }
        .background(DS.Colors.navBG)
    }

    // MARK: - Title Block

    private func titleBlock(_ article: NewsArticle) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                HStack(spacing: DS.Spacing.sm) {
                    Circle().fill(DS.Colors.accent).frame(width: 5, height: 5)
                    Text(article.source)
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.accent)
                }
                Spacer()
                Text(article.pubDate, style: .date)
                    .font(.system(size: DS.Typography.caption(sizeIndex)))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            .padding(.top, DS.Spacing.lg)

            let displayed  = viewModel.displayTitle(for: article)
            let translated = viewModel.showTranslation && displayed != article.title

            Text(displayed)
                .font(.system(size: DS.Typography.title(sizeIndex), weight: .bold))
                .foregroundStyle(DS.Colors.textPrimary)
                .lineSpacing(DS.LineSpacing.tight)
                .fixedSize(horizontal: false, vertical: true)

            if translated {
                Text(article.title)
                    .font(.system(size: DS.Typography.caption(sizeIndex)))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            line.padding(.top, DS.Spacing.sm)
        }
    }

    // MARK: - AI Section

    @ViewBuilder
    private func aiSection(_ article: NewsArticle) -> some View {
        if article.isAnalyzing {
            HStack(spacing: DS.Spacing.sm2) {
                ProgressView().tint(DS.Colors.textSecondary)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("AI 說明中…")
                        .font(.system(size: DS.Typography.body(sizeIndex)))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("通常需要 10–20 秒")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
            }
            .padding(.vertical, DS.Spacing.lg)
            line

        } else if let points = article.keyPoints, !points.isEmpty {
            if let tldr = points.first, !tldr.isEmpty {
                Text(tldr)
                    .font(.system(size: DS.Typography.body(sizeIndex), weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .lineSpacing(DS.LineSpacing.tight)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, DS.Spacing.lg)
                line
            }
            if points.count > 1, !points[1].isEmpty {
                Text(points[1])
                    .font(.system(size: DS.Typography.body(sizeIndex)))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineSpacing(DS.LineSpacing.loose)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, DS.Spacing.lg)
                line
            }

        } else if let errMsg = article.analyzeError {
            // 分析失敗 — 顯示錯誤 + 重試按鈕
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                    Text(errMsg)
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    Task { await viewModel.analyzeArticle(link: article.link) }
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("重新分析")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: DS.Typography.body(sizeIndex)))
                    .foregroundStyle(DS.Colors.accent)
                }
            }
            .padding(.vertical, DS.Spacing.lg)
            line

        } else {
            Button {
                Task { await viewModel.analyzeArticle(link: article.link) }
            } label: {
                HStack {
                    Image(systemName: "text.bubble").foregroundStyle(DS.Colors.accent)
                    Text("讓 AI 說明這篇文章")
                        .font(.system(size: DS.Typography.body(sizeIndex), weight: .medium))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
                .padding(.vertical, DS.Spacing.lg)
            }
            .buttonStyle(.plain)
            .disabled(!hasActiveAPIKey)

            if !hasActiveAPIKey {
                Text("請先在設定中選擇 AI 服務並輸入 API Key")
                    .font(.system(size: DS.Typography.caption(sizeIndex)))
                    .foregroundStyle(.orange)
                    .padding(.bottom, DS.Spacing.sm)
            }
            line
        }
    }

    // MARK: - 原文描述（含翻譯切換）

    @ViewBuilder
    private func originalSection(_ article: NewsArticle) -> some View {
        if !article.cleanDescription.isEmpty {
            let desc           = article.cleanDescription
            let cachedTranslation = viewModel.translationCoordinator.translatedDescriptions[desc]

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("原文摘要")
                        .font(.system(size: DS.Typography.caption(sizeIndex), weight: .medium))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .padding(.top, DS.Spacing.lg)

                    Spacer()

                    // 單一翻譯按鈕 — Apple 有結果用 Apple，沒有自動 AI 兜底
                    if isTranslatingDesc {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(DS.Colors.accent)
                            .padding(.top, DS.Spacing.lg)
                    } else {
                        Button {
                            if cachedTranslation != nil || showDescTranslation {
                                showDescTranslation.toggle()
                            } else {
                                isTranslatingDesc = true
                                Task {
                                    // Apple Translation 有快取直接用；否則 AI 翻譯
                                    if cachedTranslation != nil {
                                        showDescTranslation = true
                                    } else {
                                        await viewModel.translateDescriptionWithAI(desc)
                                        showDescTranslation = true
                                    }
                                    isTranslatingDesc = false
                                }
                            }
                        } label: {
                            Text(showDescTranslation ? "原文" : "翻譯")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DS.Colors.accent)
                        }
                        .padding(.top, DS.Spacing.lg)
                    }
                }

                // 原文 / 譯文直接替換
                let displayText: String = {
                    if showDescTranslation {
                        return viewModel.translationCoordinator.translatedDescriptions[desc] ?? desc
                    }
                    return desc
                }()
                Text(displayText)
                    .font(.system(size: DS.Typography.body(sizeIndex)))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .lineSpacing(DS.LineSpacing.normal)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.15), value: showDescTranslation)
            }

            line.padding(.top, DS.Spacing.lg)
        }
    }

    // MARK: - Open Link

    @ViewBuilder
    private func openLinkButton(_ article: NewsArticle) -> some View {
        if let url = URL(string: article.link) {
            Link(destination: url) {
                HStack {
                    Text("開啟原文")
                        .font(.system(size: DS.Typography.body(sizeIndex), weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                }
                .foregroundStyle(DS.Colors.accent)
                .padding(.vertical, DS.Spacing.lg)
            }
        }
    }

    private var line: some View {
        Rectangle().fill(DS.Colors.separator).frame(height: 1)
    }
}
