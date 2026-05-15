//
//  CacheService.swift
//  ThreatWatch
//
//  Responsibilities:
//  - Persist AI-generated key points to disk (JSON file in Documents)
//  - Key = article URL (stable, unique per article)
//  - Read / write / merge operations only — no networking, no UI
//

import Foundation

struct CachedEntry: Codable {
    let keyPoints: [String]
    let cachedAt: Date
    var promptVersion: Int  // 版本號，prompt 更新後舊快取自動失效
}

struct CacheService: Sendable {

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("threatwatch_cache.json")
    }

    /// 每次改變 prompt 格式時遞增，讓舊快取自動失效重新分析
    static let currentPromptVersion = 5

    // MARK: - Public

    func load() -> [String: CachedEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: CachedEntry].self, from: data)
        else { return [:] }
        // 過濾掉舊版本的快取
        return decoded.filter { $0.value.promptVersion == Self.currentPromptVersion }
    }

    func save(_ cache: [String: CachedEntry]) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Merges newly fetched key points into an existing cache snapshot.
    func merging(newKeyPoints: [String: [String]],
                 into existing: [String: CachedEntry]) -> [String: CachedEntry] {
        var updated = existing
        for (url, points) in newKeyPoints {
            updated[url] = CachedEntry(keyPoints: points, cachedAt: Date(),
                                       promptVersion: Self.currentPromptVersion)
        }
        return updated
    }
}
