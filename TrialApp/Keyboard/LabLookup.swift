import Foundation
import SwiftUI

struct LabSearchResult: Identifiable {
    let id: String
    let title: String
    let summary: String
    let insertion: String
}

@MainActor
final class LabLookup: ObservableObject {
    @Published var results: [LabSearchResult] = []
    @Published var notice = ""
    @Published var loading = false

    private var task: Task<Void, Never>?

    func cancel() {
        task?.cancel()
        loading = false
    }

    func search(_ text: String, in tool: LabTool, authorized: Bool) {
        task?.cancel()
        results = []

        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { notice = "Type or paste a search term."; return }
        guard authorized else {
            notice = "Full Access + Network On are required for live searches."
            return
        }

        loading = true
        notice = "Searching..."
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let matches: [LabSearchResult]
                switch tool {
                case .sefaria:
                    matches = try await Self.searchSefaria(query)
                case .dictionary:
                    matches = try await Self.dictionary(query)
                default:
                    matches = try await Self.searchWiki(query)
                }
                try Task.checkCancellation()
                self.results = matches
                self.notice = matches.isEmpty ? "No matching results." : "\(matches.count) results"
            } catch is CancellationError {
                return
            } catch {
                self.notice = "Search failed: \(error.localizedDescription)"
            }
            self.loading = false
        }
    }

    private static func request(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let res = response as? HTTPURLResponse, (200...299).contains(res.statusCode) else {
            throw NSError(domain: "KeyboardLab", code: 2, userInfo: [NSLocalizedDescriptionKey: "The service returned an error."])
        }
        guard data.count < 2_000_000 else {
            throw NSError(domain: "KeyboardLab", code: 3, userInfo: [NSLocalizedDescriptionKey: "Response is too large."])
        }
        return data
    }

    private static func searchWiki(_ text: String) async throws -> [LabSearchResult] {
        let lang = text.unicodeScalars.contains(where: { (0x0590...0x05FF).contains($0.value) }) ? "he" : "en"
        var parts = URLComponents(string: "https://\(lang).wikipedia.org/w/api.php")!
        parts.queryItems = [
            .init(name: "action", value: "opensearch"),
            .init(name: "format", value: "json"),
            .init(name: "limit", value: "12"),
            .init(name: "search", value: text)
        ]
        var request = URLRequest(url: parts.url!)
        request.timeoutInterval = 15
        let data = try await self.request(request)
        guard let array = try JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 3,
              let names = array[1] as? [String] else { return [] }
        let descriptions = array[2] as? [String] ?? []
        return names.enumerated().map { i, name in
            LabSearchResult(
                id: "wiki-\(i)",
                title: name,
                summary: i < descriptions.count ? descriptions[i] : "",
                insertion: name
            )
        }
    }

    private static func searchSefaria(_ text: String) async throws -> [LabSearchResult] {
        guard let url = URL(string: "https://www.sefaria.org/api/search-wrapper") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": text,
            "type": "text",
            "field": "naive_lemmatizer",
            "size": 12
        ])
        let data = try await self.request(request)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hitsObject = root["hits"] as? [String: Any],
              let hits = hitsObject["hits"] as? [[String: Any]] else { return [] }

        return hits.enumerated().map { index, entry in
            let source = entry["_source"] as? [String: Any] ?? [:]
            let ref = (source["ref"] as? String)
                ?? (source["heRef"] as? String)
                ?? (entry["_id"] as? String)
                ?? "Sefaria result \(index + 1)"
            let textField = (source["content"] as? String) ?? (source["text"] as? String) ?? ""
            let summary = textField
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            return LabSearchResult(id: "se-\(index)", title: ref,
                                   summary: String(summary.prefix(280)),
                                   insertion: summary.isEmpty ? ref : "\(ref): \(summary)")
        }
    }

    private static func dictionary(_ text: String) async throws -> [LabSearchResult] {
        let query = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(query)") else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let data = try await self.request(request)
        let payload = try JSONSerialization.jsonObject(with: data)
        guard let words = payload as? [[String: Any]] else { return [] }
        var matches: [LabSearchResult] = []
        for word in words {
            let name = word["word"] as? String ?? text
            let meanings = word["meanings"] as? [[String: Any]] ?? []
            for meaning in meanings.prefix(3) {
                let kind = meaning["partOfSpeech"] as? String ?? "Definition"
                let definitions = meaning["definitions"] as? [[String: Any]] ?? []
                for definition in definitions.prefix(3) {
                    let detail = definition["definition"] as? String ?? ""
                    matches.append(.init(id: "dict-\(matches.count)", title: "\(name) · \(kind)",
                                         summary: detail, insertion: detail))
                }
            }
        }
        return matches
    }
}
