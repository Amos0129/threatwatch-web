//
//  BookmarkedArticle.swift
//  ThreatWatch
//
//  Persisted representation of a bookmarked article.
//  Stored separately from the live RSS feed so bookmarks survive refreshes.
//

import Foundation

struct BookmarkedArticle: Codable, Identifiable {
    var id: String { link }
    let title: String
    let link: String
    let rawDescription: String
    let pubDate: Date
    let source: String
    var keyPoints: [String]?
    let savedAt: Date

    init(from article: NewsArticle) {
        self.title          = article.title
        self.link           = article.link
        self.rawDescription = article.rawDescription
        self.pubDate        = article.pubDate
        self.source         = article.source
        self.keyPoints      = article.keyPoints
        self.savedAt        = Date()
    }

    func toNewsArticle() -> NewsArticle {
        var a = NewsArticle(
            title:       title,
            link:        link,
            description: rawDescription,
            pubDate:     pubDate,
            source:      source
        )
        a.keyPoints = keyPoints
        return a
    }
}
