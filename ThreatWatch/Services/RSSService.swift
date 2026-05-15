//
//  RSSService.swift
//  ThreatWatch
//
//  Responsibilities:
//  - Define feed sources
//  - Fetch RSS over the network
//  - Parse XML into [NewsArticle]
//  No knowledge of ViewModel, Cache, or Translation.
//

import Foundation

// MARK: - Feed Sources

struct RSSFeedSource: Sendable {
    let name:      String
    let url:       String
    let icon:      String  // SF Symbol name
    let utcOffset: Int     // minutes — applied when feed publishes dates without timezone

    init(name: String, url: String, icon: String, utcOffset: Int = 0) {
        self.name = name; self.url = url; self.icon = icon; self.utcOffset = utcOffset
    }
}

let cybersecurityFeeds: [RSSFeedSource] = [
    .init(name: "The Hacker News",      url: "https://feeds.feedburner.com/TheHackersNews",            icon: "newspaper.fill"),
    .init(name: "Krebs on Security",    url: "https://krebsonsecurity.com/feed/",                      icon: "lock.shield.fill"),
    .init(name: "BleepingComputer",     url: "https://www.bleepingcomputer.com/feed/",                 icon: "desktopcomputer.trianglebadge.exclamationmark"),
    .init(name: "SecurityWeek",         url: "https://feeds.feedburner.com/securityweek",              icon: "shield.lefthalf.filled"),
    .init(name: "SANS ISC",             url: "https://isc.sans.edu/rssfeed_small.xml",                 icon: "eye.trianglebadge.exclamationmark"),
    .init(name: "Dark Reading",         url: "https://www.darkreading.com/rss.xml",                    icon: "moon.fill"),
    .init(name: "Infosecurity Mag",     url: "https://www.infosecurity-magazine.com/rss/news/",        icon: "magnifyingglass.circle.fill"),
    .init(name: "CSO Online",           url: "https://www.csoonline.com/feed/",                        icon: "person.badge.shield.checkmark.fill"),
    .init(name: "Threatpost",           url: "https://threatpost.com/feed/",                           icon: "ant.fill"),
    .init(name: "CyberScoop",           url: "https://cyberscoop.com/feed/",                           icon: "antenna.radiowaves.left.and.right"),
    .init(name: "iThome",              url: "https://www.ithome.com.tw/rss/security",                  icon: "apple.terminal.fill", utcOffset: 480),
]

// MARK: - Service

struct RSSService: Sendable {

    /// Fetches all feeds concurrently and returns merged, date-sorted articles.
    func fetchAll() async -> [NewsArticle] {
        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in cybersecurityFeeds {
                group.addTask {
                    (try? await fetch(source)) ?? []
                }
            }
            var all: [NewsArticle] = []
            for await batch in group {
                all.append(contentsOf: batch)
            }
            return all.sorted { $0.pubDate > $1.pubDate }
        }
    }

    private func fetch(_ source: RSSFeedSource) async throws -> [NewsArticle] {
        guard let url = URL(string: source.url) else { throw URLError(.badURL) }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        req.setValue("ThreatWatch/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: req)
        return parseXML(data, source: source)
    }

    private func parseXML(_ data: Data, source: RSSFeedSource) -> [NewsArticle] {
        let delegate = RSSXMLDelegate(sourceName: source.name, utcOffset: source.utcOffset)
        let parser   = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.articles
    }
}

// MARK: - XML Delegate (private, stateful, single-use)

private final class RSSXMLDelegate: NSObject, XMLParserDelegate {
    private(set) var articles: [NewsArticle] = []
    private let sourceName:  String
    private let utcOffset:   Int   // minutes

    private var inItem      = false
    private var buf         = ""
    private var itemTitle   = ""
    private var itemLink    = ""
    private var itemDesc    = ""
    private var itemDate    = ""

    init(sourceName: String, utcOffset: Int = 0) {
        self.sourceName = sourceName
        self.utcOffset  = utcOffset
    }

    func parser(_ parser: XMLParser, didStartElement element: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        if element == "item" || element == "entry" {
            inItem = true
            itemTitle = ""; itemLink = ""; itemDesc = ""; itemDate = ""
        }
        // Atom feeds use <link href="..."/> with no text content
        if inItem, (element == "link"), let href = attributes["href"], !href.isEmpty {
            if itemLink.isEmpty { itemLink = href }
        }
        buf = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buf += string
    }

    func parser(_ parser: XMLParser, didEndElement element: String,
                namespaceURI: String?, qualifiedName: String?) {
        guard inItem else { buf = ""; return }
        let val = buf.trimmingCharacters(in: .whitespacesAndNewlines)
        switch element {
        case "title":
            if itemTitle.isEmpty { itemTitle = val }
        case "link":
            // RSS 2.0: link text; Atom: already captured via href attribute
            if itemLink.isEmpty { itemLink = val }
        case "description", "summary":
            if itemDesc.isEmpty { itemDesc = val }
        case "pubDate", "published", "updated", "dc:date":
            if itemDate.isEmpty { itemDate = val }
        case "item", "entry":
            if !itemTitle.isEmpty, !itemLink.isEmpty {
                articles.append(NewsArticle(
                    title:       itemTitle,
                    link:        itemLink,
                    description: itemDesc,
                    pubDate:     parseRFC822(itemDate, utcOffset: utcOffset) ?? Date(),
                    source:      sourceName
                ))
            }
            inItem = false
        default: break
        }
        buf = ""
    }

    private func parseRFC822(_ s: String, utcOffset: Int = 0) -> Date? {
        // 1. ISO 8601 — 處理 +08:00 這類含冒號的時區（Z 格式無法處理）
        let iso = ISO8601DateFormatter()
        for options: ISO8601DateFormatter.Options in [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime],
        ] {
            iso.formatOptions = options
            if let d = iso.date(from: s) { return d }
        }

        // 2. RFC 822 / 常見 RSS 格式（含時區 Z/zzz）
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        for f in ["EEE, dd MMM yyyy HH:mm:ss zzz",
                  "EEE, dd MMM yyyy HH:mm:ss Z",
                  "yyyy-MM-dd'T'HH:mm:ssZ",
                  "yyyy-MM-dd'T'HH:mm:ss.SSSZ"] {
            fmt.dateFormat = f
            if let d = fmt.date(from: s) { return d }
        }

        // 3. 無時區 — 套用來源 utcOffset 換算回 UTC
        for f in ["yyyy-MM-dd'T'HH:mm:ss",
                  "EEE, dd MMM yyyy HH:mm:ss",
                  "yyyy-MM-dd HH:mm:ss",
                  "yyyy-MM-dd HH:mm"] {      // iThome 格式：2026-05-14 16:50
            fmt.dateFormat = f
            if let d = fmt.date(from: s) {
                return d.addingTimeInterval(TimeInterval(-utcOffset * 60))
            }
        }
        return nil
    }
}
