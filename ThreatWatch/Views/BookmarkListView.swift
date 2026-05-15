//
//  BookmarkListView.swift
//  ThreatWatch
//

import SwiftUI

struct BookmarkListView: View {
    let viewModel: NewsViewModel

    private var sorted: [BookmarkedArticle] {
        viewModel.bookmarks.values.sorted { $0.savedAt > $1.savedAt }
    }

    var body: some View {
        ZStack {
            DS.Colors.pageBG.ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                if sorted.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sorted) { bookmark in
                                let article = bookmark.toNewsArticle()
                                NavigationLink {
                                    ArticleDetailView(articleLink: article.link, viewModel: viewModel)
                                } label: {
                                    ArticleRowView(
                                        article:      article,
                                        displayTitle: viewModel.displayTitle(for: article),
                                        isRead:       viewModel.isRead(article.link),
                                        isBookmarked: true
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, DS.Spacing.pageH)
                                .padding(.vertical, DS.Spacing.xs)
                            }
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var customHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                    Text("書籤")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                Spacer()
                Text("\(sorted.count) 則")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            .padding(.horizontal, DS.Spacing.pageH)
            .padding(.vertical, DS.Spacing.sm + DS.Spacing.xs)

            Rectangle()
                .fill(DS.Colors.separator)
                .frame(height: 1)
        }
        .background(DS.Colors.navBG)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "bookmark")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.Colors.textTertiary)
                Text("尚未加入書籤")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("在文章頁面點擊書籤圖示即可儲存")
                    .font(.caption)
                    .foregroundStyle(DS.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
}
