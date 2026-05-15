//
//  ContentView.swift
//  ThreatWatch
//

import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // 主內容
            Group {
                if selectedTab == 0 {
                    NavigationStack {
                        ArticleListView(viewModel: env.newsViewModel)
                    }
                } else {
                    NavigationStack {
                        BookmarkListView(viewModel: env.newsViewModel)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                customTabBar
            }
        }
        .preferredColorScheme(AppTheme.shared.isDark ? .dark : .light)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DS.Colors.separator)
                .frame(height: 1)

            HStack(spacing: 0) {
                tabButton(icon: "newspaper", label: "新聞",  index: 0)
                tabButton(icon: "bookmark",  label: "書籤",  index: 1)
            }
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xs)
            .background(DS.Colors.navBG)
        }
        // 延伸背景到 home indicator 區域
        .background(DS.Colors.navBG.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(icon: String, label: String, index: Int) -> some View {
        let active = selectedTab == index
        return Button { selectedTab = index } label: {
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: active ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10, weight: active ? .semibold : .regular))
            }
            .foregroundStyle(active ? DS.Colors.accent : DS.Colors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.xs)
            .contentShape(Rectangle())
        }
    }
}
