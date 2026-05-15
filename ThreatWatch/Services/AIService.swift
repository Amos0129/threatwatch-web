//
//  AIService.swift
//  ThreatWatch
//
//  Supports: Claude (Anthropic) · ChatGPT (OpenAI) · Gemini (Google)
//            Groq · xAI (Grok) · Mistral
//

import Foundation

struct AIService: Sendable {

    // MARK: - Public

    func batchAnalyze(articles: [NewsArticle], apiKey: String,
                      provider: AIProvider, modelID: String) async throws -> [String: [String]] {
        guard !articles.isEmpty else { return [:] }

        let numberedList = articles.enumerated().map { i, a in
            """
            [\(i + 1)]
            URL: \(a.link)
            標題: \(a.title)
            內容: \(String(a.cleanDescription.prefix(600)))
            """
        }.joined(separator: "\n\n")

        let prompt = """
        請用繁體中文說明以下 \(articles.count) 篇新聞在講什麼，讓一般人也能看懂。

        \(numberedList)

        針對每篇文章，提供兩項內容：
        第一項：一句話說明這篇文章的重點（20字以內）
        第二項：詳細說明這篇文章在講什麼，根據文章內容完整說明，不要省略，用自然的方式描述即可

        請嚴格以下列 JSON 格式回傳，不要有任何其他文字：
        {
          "results": [
            {
              "url": "<原文URL>",
              "keyPoints": [
                "一句話重點",
                "詳細說明..."
              ]
            }
          ]
        }
        """

        let responseText: String
        switch provider {
        case .claude:
            responseText = try await callClaude(prompt: prompt, apiKey: apiKey, modelID: modelID)
        case .gemini:
            responseText = try await callGemini(prompt: prompt, apiKey: apiKey, modelID: modelID)
        case .openAI, .groq, .xai, .mistral:
            responseText = try await callOpenAICompatible(
                prompt: prompt, apiKey: apiKey, modelID: modelID,
                baseURL: provider.baseURL
            )
        }

        return parseResults(from: responseText)
    }

    // MARK: - Translate (fallback when Apple Translation fails)

    func translateTexts(_ texts: [String], apiKey: String,
                        provider: AIProvider, modelID: String) async throws -> [String: String] {
        guard !texts.isEmpty else { return [:] }

        let numbered = texts.enumerated().map { i, t in "[\(i + 1)] \(t)" }.joined(separator: "\n")
        let prompt = """
        將以下英文資安新聞標題翻譯成繁體中文。
        保留 CVE 編號、產品名稱、公司名稱等專有名詞不翻譯。
        以 JSON 陣列格式回傳（與輸入順序相同，長度相同），不要加其他說明：

        \(numbered)

        回傳格式範例：["中文標題一","中文標題二"]
        """

        let responseText: String
        switch provider {
        case .claude:
            responseText = try await callClaude(prompt: prompt, apiKey: apiKey, modelID: modelID)
        case .gemini:
            responseText = try await callGemini(prompt: prompt, apiKey: apiKey, modelID: modelID)
        case .openAI, .groq, .xai, .mistral:
            responseText = try await callOpenAICompatible(
                prompt: prompt, apiKey: apiKey, modelID: modelID, baseURL: provider.baseURL)
        }

        // Extract JSON array from response
        var clean = responseText
        if let s = clean.range(of: "```json\n") { clean = String(clean[s.upperBound...]) }
        else if let s = clean.range(of: "```\n") { clean = String(clean[s.upperBound...]) }
        if let e = clean.range(of: "\n```") { clean = String(clean[..<e.lowerBound]) }
        if let s = clean.range(of: "["), let e = clean.range(of: "]", options: .backwards) {
            clean = String(clean[s.lowerBound..<e.upperBound])
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data        = clean.data(using: .utf8),
              let translated  = try? JSONDecoder().decode([String].self, from: data),
              translated.count == texts.count
        else { return [:] }

        return Dictionary(uniqueKeysWithValues: zip(texts, translated))
    }

    // MARK: - Claude (Anthropic)

    private func callClaude(prompt: String, apiKey: String, modelID: String) async throws -> String {
        struct Payload: Encodable {
            let model: String
            let max_tokens: Int
            let messages: [[String: String]]
        }
        struct Response: Decodable {
            struct Content: Decodable { let text: String }
            let content: [Content]
        }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONEncoder().encode(
            Payload(model: modelID, max_tokens: 4096,
                    messages: [["role": "user", "content": prompt]])
        )

        let (data, _) = try await fetch(req, apiKey: apiKey)
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.content.first?.text ?? ""
    }

    // MARK: - OpenAI-compatible (OpenAI / Groq / xAI / Mistral)

    private func callOpenAICompatible(prompt: String, apiKey: String,
                                      modelID: String, baseURL: String) async throws -> String {
        struct Message: Encodable { let role: String; let content: String }
        struct Payload: Encodable { let model: String; let messages: [Message]; let max_tokens: Int }
        struct Response: Decodable {
            struct Choice: Decodable {
                struct Msg: Decodable { let content: String }
                let message: Msg
            }
            let choices: [Choice]
        }

        var req = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONEncoder().encode(
            Payload(model: modelID,
                    messages: [.init(role: "user", content: prompt)],
                    max_tokens: 4096)
        )

        let (data, _) = try await fetch(req, apiKey: apiKey)
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    // MARK: - Gemini (Google)

    private func callGemini(prompt: String, apiKey: String, modelID: String) async throws -> String {
        struct Part: Codable    { let text: String }
        struct Content: Codable { let parts: [Part] }
        struct Payload: Encodable { let contents: [Content] }
        struct Response: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable { let parts: [Part] }
                let content: Content
            }
            let candidates: [Candidate]
        }

        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(modelID):generateContent?key=\(apiKey)"
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONEncoder().encode(
            Payload(contents: [.init(parts: [.init(text: prompt)])])
        )

        let (data, _) = try await fetch(req, apiKey: apiKey)
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.candidates.first?.content.parts.first?.text ?? ""
    }

    // MARK: - Shared fetch + error handling

    private func fetch(_ req: URLRequest, apiKey: String) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AIError.unknown }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIError.apiError(http.statusCode, body)
        }
        return (data, http)
    }

    // MARK: - Parse JSON results

    private func parseResults(from text: String) -> [String: [String]] {
        var clean = text
        if let s = clean.range(of: "```json\n") { clean = String(clean[s.upperBound...]) }
        else if let s = clean.range(of: "```\n") { clean = String(clean[s.upperBound...]) }
        if let e = clean.range(of: "\n```") { clean = String(clean[..<e.lowerBound]) }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        struct Item:    Decodable { let url: String; let keyPoints: [String] }
        struct Wrapper: Decodable { let results: [Item] }

        guard let data    = clean.data(using: .utf8),
              let wrapper = try? JSONDecoder().decode(Wrapper.self, from: data)
        else { return [:] }

        return Dictionary(uniqueKeysWithValues: wrapper.results.map { ($0.url, $0.keyPoints) })
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case unknown
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .unknown:              return "未知錯誤"
        case .apiError(let c, let m): return "HTTP \(c)：\(m.prefix(120))"
        }
    }
}

// MARK: - Provider base URLs

private extension AIProvider {
    var baseURL: String {
        switch self {
        case .openAI:  return "https://api.openai.com/v1"
        case .groq:    return "https://api.groq.com/openai/v1"
        case .xai:     return "https://api.x.ai/v1"
        case .mistral: return "https://api.mistral.ai/v1"
        default:       return ""
        }
    }
}
