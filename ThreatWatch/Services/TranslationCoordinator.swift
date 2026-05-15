//
//  TranslationCoordinator.swift
//  ThreatWatch
//

import Foundation
import Translation

@Observable
final class TranslationCoordinator {

    // MARK: - Observable State

    var configuration: TranslationSession.Configuration?
    var translatedTitles:       [String: String] = [:]
    var translatedDescriptions: [String: String] = [:]
    private(set) var isTranslating = false

    // MARK: - Private

    private var pendingTitles:       [String] = []
    private var pendingDescriptions: [String] = []

    // MARK: - ViewModel Interface

    /// 批次翻譯標題（文章列表載入後呼叫）
    func requestTranslation(for titles: [String]) {
        let untranslated = titles.filter { translatedTitles[$0] == nil }
        guard !untranslated.isEmpty else { return }
        pendingTitles.append(contentsOf: untranslated)
        triggerSession()
    }

    /// 單篇描述翻譯（進入文章詳細頁時呼叫）
    func requestDescriptionTranslation(for text: String) {
        guard !text.isEmpty, translatedDescriptions[text] == nil,
              !pendingDescriptions.contains(text) else { return }
        pendingDescriptions.append(text)
        triggerSession()
    }

    // MARK: - View Interface

    func performTranslation(session: TranslationSession) async {
        let titles = pendingTitles
        let descs  = pendingDescriptions
        defer {
            pendingTitles       = []
            pendingDescriptions = []
            configuration       = nil
            isTranslating       = false
        }
        guard !titles.isEmpty || !descs.isEmpty else { return }

        await withTaskGroup(of: (String, String, Bool)?.self) { group in
            for t in titles {
                group.addTask {
                    guard let r = try? await session.translate(t) else { return nil }
                    return (t, r.targetText, true)
                }
            }
            for d in descs {
                group.addTask {
                    guard let r = try? await session.translate(d) else { return nil }
                    return (d, r.targetText, false)
                }
            }
            for await result in group {
                guard let (original, translated, isTitle) = result else { continue }
                if isTitle { translatedTitles[original]       = translated }
                else        { translatedDescriptions[original] = translated }
            }
        }
    }

    // MARK: - Private

    private func triggerSession() {
        isTranslating = true
        configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "zh-Hant")
        )
    }
}
