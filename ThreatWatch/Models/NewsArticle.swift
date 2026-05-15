//
//  NewsArticle.swift
//  ThreatWatch
//

import Foundation

struct NewsArticle: Identifiable, Sendable, Codable {
    let id: UUID
    let title: String
    let link: String
    let rawDescription: String
    let pubDate: Date
    let source: String

    // Runtime state — not persisted to disk
    var chineseTitle: String?
    var keyPoints:    [String]?
    var isAnalyzing:  Bool
    var analyzeError: String?

    // Only encode/decode the stable fields for offline cache
    enum CodingKeys: String, CodingKey {
        case id, title, link, rawDescription, pubDate, source
    }

    init(from decoder: Decoder) throws {
        let c      = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,   forKey: .id)
        title          = try c.decode(String.self, forKey: .title)
        link           = try c.decode(String.self, forKey: .link)
        rawDescription = try c.decode(String.self, forKey: .rawDescription)
        pubDate        = try c.decode(Date.self,   forKey: .pubDate)
        source         = try c.decode(String.self, forKey: .source)
        chineseTitle   = nil; keyPoints = nil; isAnalyzing = false; analyzeError = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(title, forKey: .title)
        try c.encode(link, forKey: .link); try c.encode(rawDescription, forKey: .rawDescription)
        try c.encode(pubDate, forKey: .pubDate); try c.encode(source, forKey: .source)
    }

    var cleanDescription: String {
        rawDescription
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(title: String, link: String, description: String, pubDate: Date, source: String) {
        self.id = UUID()
        self.title = title
        self.link = link
        self.rawDescription = description
        self.pubDate = pubDate
        self.source = source
        self.isAnalyzing  = false
        self.analyzeError = nil
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh-TW")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
