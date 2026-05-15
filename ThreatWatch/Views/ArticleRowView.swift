//
//  ArticleRowView.swift
//  ThreatWatch
//

import SwiftUI

struct ArticleRowView: View {
    let article: NewsArticle
    let displayTitle: String
    var isRead:          Bool     = false
    var isBookmarked:    Bool     = false
    var matchedKeywords: [String] = []

    @AppStorage("font_size_index") private var sizeIndex = 1

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {

            // Source + bookmark icon + time
            HStack(spacing: DS.Spacing.sm) {
                Circle()
                    .fill(isRead ? DS.Colors.textTertiary : DS.Colors.accent)
                    .frame(width: 5, height: 5)
                Text(article.source)
                    .font(.system(size: DS.Typography.caption(sizeIndex)))
                    .foregroundStyle(isRead ? DS.Colors.textTertiary : DS.Colors.accent)
                Spacer()
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.accent)
                }
                Text(article.pubDate.timeAgoDisplay())
                    .font(.system(size: DS.Typography.caption(sizeIndex)))
                    .foregroundStyle(DS.Colors.textTertiary)
            }

            // Title
            Text(displayTitle)
                .font(.system(size: DS.Typography.body(sizeIndex), weight: .semibold))
                .foregroundStyle(DS.Colors.textPrimary)
                .lineSpacing(DS.LineSpacing.tight)
                .fixedSize(horizontal: false, vertical: true)

            // Description preview (2 lines)
            if !article.cleanDescription.isEmpty {
                Text(article.cleanDescription)
                    .font(.system(size: DS.Typography.caption(sizeIndex)))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .lineLimit(2)
                    .lineSpacing(DS.LineSpacing.tight)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Keyword chips
            if !matchedKeywords.isEmpty {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(matchedKeywords, id: \.self) { kw in
                        Text(kw)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xs)
                            .background(DS.Colors.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))
                    }
                }
            }

            // Status badge
            HStack(spacing: DS.Spacing.sm) {
                if article.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.55)
                        .tint(DS.Colors.textTertiary)
                    Text("說明中…")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.textTertiary)
                } else if article.keyPoints != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.accent)
                    Text("已說明")
                        .font(.system(size: DS.Typography.caption(sizeIndex)))
                        .foregroundStyle(DS.Colors.accent)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .opacity(isRead ? 0.55 : 1.0)
        .overlay(alignment: .leading) {
            if !matchedKeywords.isEmpty {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Colors.accent)
                    .frame(width: 3)
            }
        }
    }
}
