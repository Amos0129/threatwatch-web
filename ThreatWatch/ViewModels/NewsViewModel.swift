//
//  NewsViewModel.swift
//  ThreatWatch
//
//  Responsibilities:
//  - Orchestrate RSSService → TranslationCoordinator → AIService → CacheService
//  - Expose filtered/searched article list to Views
//  - Own all UI state (loading, error, filter, search, settings visibility)
//  - Persist bookmarks, read state, keywords, disabled feeds
//  Views interact only with this class — never directly with Services.
//

import Foundation

@Observable
final class NewsViewModel {

    // MARK: - UI State

    var articles:       [NewsArticle] = []
    var isLoading       = false
    var errorMessage:   String?
    var analysisError:  String?
    var selectedFilter: TimeFilter = .all
    var searchText      = ""
    var showSettings    = false
    var showBookmarks    = false
    var newCount         = 0
    var showTranslation  = true
    var isOffline        = false

    // MARK: - Preferences (persisted)

    var bookmarks:     [String: BookmarkedArticle] = [:]
    var readLinks:     Set<String>                 = []
    var keywords:      [String]                    = []
    var disabledFeeds: Set<String>                 = []

    // MARK: - Dependencies

    private let rssService:          RSSService
    private let aiService:           AIService
    private let cacheService:        CacheService
    private let articleCacheService: ArticleCacheService
    let translationCoordinator: TranslationCoordinator

    private var cache: [String: CachedEntry] = [:]

    // MARK: - Init

    init(rssService:             RSSService,
         aiService:              AIService,
         cacheService:           CacheService,
         articleCacheService:    ArticleCacheService,
         translationCoordinator: TranslationCoordinator) {
        self.rssService             = rssService
        self.aiService              = aiService
        self.cacheService           = cacheService
        self.articleCacheService    = articleCacheService
        self.translationCoordinator = translationCoordinator
        loadPreferences()
    }

    // MARK: - Computed

    var cachedArticleCount: Int { cache.count }

    var filteredArticles: [NewsArticle] {
        var result = articles
        if !disabledFeeds.isEmpty {
            result = result.filter { !disabledFeeds.contains($0.source) }
        }
        if let cutoff = selectedFilter.cutoffDate {
            result = result.filter { $0.pubDate >= cutoff }
        }
        if !searchText.isEmpty {
            let q = searchText
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(q) ||
                $0.source.localizedCaseInsensitiveContains(q) ||
                $0.cleanDescription.localizedCaseInsensitiveContains(q)
            }
        }
        return result.sorted { a, b in
            let aAnalyzed = a.keyPoints != nil
            let bAnalyzed = b.keyPoints != nil
            if aAnalyzed != bAnalyzed { return aAnalyzed }
            return a.pubDate > b.pubDate
        }
    }

    /// The list actually shown in the UI — either filtered news or bookmarks.
    var displayArticles: [NewsArticle] {
        guard showBookmarks else { return filteredArticles }
        return bookmarks.values
            .map { $0.toNewsArticle() }
            .sorted { $0.pubDate > $1.pubDate }
    }

    /// Returns translated title if translation is enabled and available, otherwise original English title.
    func displayTitle(for article: NewsArticle) -> String {
        guard showTranslation else { return article.title }
        return translationCoordinator.translatedTitles[article.title] ?? article.title
    }

    func toggleTranslation() {
        showTranslation.toggle()
        UserDefaults.standard.set(showTranslation, forKey: "show_translation")
        // 開啟時若有未翻譯的標題，立刻排進翻譯佇列
        if showTranslation {
            let missing = articles.map(\.title)
                .filter { translationCoordinator.translatedTitles[$0] == nil }
            if !missing.isEmpty {
                translationCoordinator.requestTranslation(for: missing)
            }
        }
    }

    /// Looks up an article from the live feed first, then falls back to bookmarks.
    func articleData(for link: String) -> NewsArticle? {
        articles.first { $0.link == link } ?? bookmarks[link]?.toNewsArticle()
    }

    func isBookmarked(_ link: String) -> Bool { bookmarks[link] != nil }
    func isRead(_ link: String) -> Bool { readLinks.contains(link) }

    /// Returns which tracked keywords match this article's title + description.
    func matchedKeywords(for article: NewsArticle) -> [String] {
        guard !keywords.isEmpty else { return [] }
        return keywords.filter { kw in
            let q = kw.lowercased()
            return article.title.lowercased().contains(q) ||
                   article.cleanDescription.lowercased().contains(q)
        }
    }

    // MARK: - News Loading

    func loadNews() async {
        isLoading    = true
        errorMessage = nil
        isOffline    = false
        cache        = cacheService.load()

        let fetched = await rssService.fetchAll()

        if fetched.isEmpty {
            // 嘗試從本地快取讀取上次的文章
            let offline = articleCacheService.load()
            if !offline.isEmpty {
                isOffline = true
                articles  = offline.map { var a = $0; a.keyPoints = cache[a.link]?.keyPoints; return a }
            } else {
                errorMessage = "無法載入新聞，請檢查網路連線"
            }
            isLoading = false
            return
        }

        // 成功取得文章：存到本地供離線使用
        articleCacheService.save(fetched)

        let lastLinks = Set(UserDefaults.standard.stringArray(forKey: "last_seen_links") ?? [])
        newCount = lastLinks.isEmpty ? 0 : fetched.filter { !lastLinks.contains($0.link) }.count
        UserDefaults.standard.set(fetched.map(\.link), forKey: "last_seen_links")

        articles  = fetched.map { var a = $0; a.keyPoints = cache[a.link]?.keyPoints; return a }
        isLoading = false

        translationCoordinator.requestTranslation(for: fetched.map(\.title))
    }

    // MARK: - AI Analysis

    func analyzeArticle(link: String) async {
        let ud = UserDefaults.standard
        let providerRaw = ud.string(forKey: "selected_provider") ?? AIProvider.claude.rawValue
        let provider    = AIProvider(rawValue: providerRaw) ?? .claude
        let apiKey      = ud.string(forKey: provider.apiKeyStorageKey) ?? ""
        let modelID     = ud.string(forKey: "selected_model_\(provider.rawValue)") ?? provider.defaultModelID

        guard !apiKey.isEmpty,
              let article = articleData(for: link),
              article.keyPoints == nil else { return }

        analysisError = nil
        updateArticle(link: link) { $0.analyzeError = nil }
        setAnalyzing(true, for: link)

        do {
            let keyPointsMap = try await aiService.batchAnalyze(
                articles: [article], apiKey: apiKey, provider: provider, modelID: modelID)
            let updatedCache = cacheService.merging(newKeyPoints: keyPointsMap, into: cache)
            cacheService.save(updatedCache)
            cache = updatedCache

            if let points = keyPointsMap[link] {
                updateArticle(link: link) { $0.keyPoints = points; $0.isAnalyzing = false }
                if bookmarks[link] != nil {
                    bookmarks[link]?.keyPoints = points
                    saveBookmarks()
                }
            } else {
                let msg = "AI 未回傳有效結果，請稍後再試"
                setAnalyzing(false, for: link)
                updateArticle(link: link) { $0.analyzeError = msg }
                analysisError = msg
            }
        } catch {
            let msg = error.localizedDescription
            setAnalyzing(false, for: link)
            updateArticle(link: link) { $0.analyzeError = msg }
            analysisError = msg
        }
    }

    func clearCache() {
        cache = [:]
        cacheService.save([:])
        articles = articles.map { var a = $0; a.keyPoints = nil; return a }
    }

    /// Apple Translation 完成後，對仍未翻譯的標題用 AI 補譯
    func applyAITranslationFallback() async {
        let ud          = UserDefaults.standard
        let providerRaw = ud.string(forKey: "selected_provider") ?? AIProvider.claude.rawValue
        let provider    = AIProvider(rawValue: providerRaw) ?? .claude
        let apiKey      = ud.string(forKey: provider.apiKeyStorageKey) ?? ""
        let modelID     = ud.string(forKey: "selected_model_\(provider.rawValue)") ?? provider.defaultModelID
        guard !apiKey.isEmpty else { return }

        let missing = articles.map(\.title)
            .filter { translationCoordinator.translatedTitles[$0] == nil }
        guard !missing.isEmpty else { return }

        guard let result = try? await aiService.translateTexts(
            missing, apiKey: apiKey, provider: provider, modelID: modelID)
        else { return }

        for (original, translated) in result {
            translationCoordinator.translatedTitles[original] = translated
        }
    }

    /// 用 AI 翻譯單篇文章的描述（Apple Translation 無法翻譯時的備案）
    func translateDescriptionWithAI(_ text: String) async -> String? {
        let ud          = UserDefaults.standard
        let providerRaw = ud.string(forKey: "selected_provider") ?? AIProvider.claude.rawValue
        let provider    = AIProvider(rawValue: providerRaw) ?? .claude
        let apiKey      = ud.string(forKey: provider.apiKeyStorageKey) ?? ""
        let modelID     = ud.string(forKey: "selected_model_\(provider.rawValue)") ?? provider.defaultModelID
        guard !apiKey.isEmpty else { return nil }

        let result = try? await aiService.translateTexts(
            [text], apiKey: apiKey, provider: provider, modelID: modelID)
        if let translated = result?[text], !translated.isEmpty {
            translationCoordinator.translatedDescriptions[text] = translated
            return translated
        }
        return nil
    }

    // MARK: - Preferences Actions

    func markRead(_ link: String) {
        guard !readLinks.contains(link) else { return }
        readLinks.insert(link)
        if newCount > 0 { newCount -= 1 }
        UserDefaults.standard.set(Array(readLinks), forKey: "read_links")
    }

    func toggleBookmark(article: NewsArticle) {
        if bookmarks[article.link] != nil {
            bookmarks.removeValue(forKey: article.link)
        } else {
            bookmarks[article.link] = BookmarkedArticle(from: article)
        }
        saveBookmarks()
    }

    func addKeyword(_ keyword: String) {
        let kw = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kw.isEmpty, !keywords.contains(kw) else { return }
        keywords.append(kw)
        UserDefaults.standard.set(keywords, forKey: "keywords")
    }

    func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
        UserDefaults.standard.set(keywords, forKey: "keywords")
    }

    func toggleFeed(_ feedName: String) {
        if disabledFeeds.contains(feedName) {
            disabledFeeds.remove(feedName)
        } else {
            disabledFeeds.insert(feedName)
        }
        UserDefaults.standard.set(Array(disabledFeeds), forKey: "disabled_feeds")
    }

    // MARK: - Persistence

    private func loadPreferences() {
        let ud        = UserDefaults.standard
        readLinks       = Set(ud.stringArray(forKey: "read_links")    ?? [])
        keywords        = ud.stringArray(forKey: "keywords")          ?? []
        disabledFeeds   = Set(ud.stringArray(forKey: "disabled_feeds") ?? [])
        showTranslation = ud.object(forKey: "show_translation") as? Bool ?? true
        if let data    = ud.data(forKey: "bookmarks_v1"),
           let decoded = try? JSONDecoder().decode([String: BookmarkedArticle].self, from: data) {
            bookmarks = decoded
        }
    }

    private func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: "bookmarks_v1")
    }

    // MARK: - Private helpers

    private func setAnalyzing(_ value: Bool, for link: String) {
        updateArticle(link: link) { $0.isAnalyzing = value }
    }

    private func updateArticle(link: String, mutation: (inout NewsArticle) -> Void) {
        guard let idx = articles.firstIndex(where: { $0.link == link }) else { return }
        mutation(&articles[idx])
    }
}
