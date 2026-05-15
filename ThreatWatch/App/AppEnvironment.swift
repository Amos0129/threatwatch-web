//
//  AppEnvironment.swift
//  ThreatWatch
//
//  Single source of truth for dependency injection.
//  Created once by ThreatWatchApp and injected into the SwiftUI environment.
//  Views access it via @Environment(AppEnvironment.self).
//

import Foundation

@Observable
final class AppEnvironment {
    let newsViewModel: NewsViewModel

    init() {
        let tc = TranslationCoordinator()
        newsViewModel = NewsViewModel(
            rssService:           RSSService(),
            aiService:            AIService(),
            cacheService:         CacheService(),
            articleCacheService:  ArticleCacheService(),
            translationCoordinator: tc
        )
    }
}
