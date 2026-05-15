//
//  ArticleCacheService.swift
//  ThreatWatch
//
//  Persists raw RSS articles to disk so the app can show
//  previously loaded content when the network is unavailable.
//

import Foundation

struct ArticleCacheService: Sendable {

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("articles_offline.json")
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func save(_ articles: [NewsArticle]) {
        guard let data = try? encoder.encode(articles) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func load() -> [NewsArticle] {
        guard let data     = try? Data(contentsOf: fileURL),
              let articles = try? decoder.decode([NewsArticle].self, from: data)
        else { return [] }
        return articles
    }
}
