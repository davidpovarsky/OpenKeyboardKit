import Foundation

/// Declarative, versioned metadata used to render the universal command bar.
/// Existing saved scripts do not require a manifest; all fields have defaults.
struct LabCommandManifest: Codable, Equatable {
    struct Input: Codable, Equatable {
        var placeholder: String
        var required: Bool = true
        var maxLength: Int = 4000

        init(placeholder: String, required: Bool = true, maxLength: Int = 4000) {
            self.placeholder = placeholder
            self.required = required
            self.maxLength = maxLength
        }

        private enum CodingKeys: String, CodingKey {
            case placeholder, required, maxLength
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            placeholder = try values.decodeIfPresent(String.self, forKey: .placeholder)
                ?? "Enter text"
            required = try values.decodeIfPresent(Bool.self, forKey: .required) ?? true
            maxLength = try values.decodeIfPresent(Int.self, forKey: .maxLength) ?? 4000
        }
    }

    struct Action: Codable, Equatable {
        var title: String
        var symbol: String

        init(title: String, symbol: String) {
            self.title = title
            self.symbol = symbol
        }

        private enum CodingKeys: String, CodingKey {
            case title, symbol
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            title = try values.decodeIfPresent(String.self, forKey: .title) ?? "Run"
            symbol = try values.decodeIfPresent(String.self, forKey: .symbol) ?? "play.fill"
        }
    }

    enum ResultStyle: String, Codable, CaseIterable {
        case inlineList
        case inlineText
        case workspace
    }

    var input: Input
    var action: Action
    var result: ResultStyle = .inlineList
    var permissions: [String] = []

    init(input: Input, action: Action, result: ResultStyle = .inlineList,
         permissions: [String] = []) {
        self.input = input
        self.action = action
        self.result = result
        self.permissions = permissions
    }

    private enum CodingKeys: String, CodingKey {
        case input, action, result, permissions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        input = try values.decodeIfPresent(Input.self, forKey: .input)
            ?? .init(placeholder: "Enter text", required: false)
        action = try values.decodeIfPresent(Action.self, forKey: .action)
            ?? .init(title: "Run", symbol: "play.fill")
        result = try values.decodeIfPresent(ResultStyle.self, forKey: .result)
            ?? .inlineList
        permissions = try values.decodeIfPresent([String].self, forKey: .permissions) ?? []
    }

    static func defaults(for id: String, title: String) -> Self {
        switch id {
        case "wikipedia":
            return .init(input: .init(placeholder: "Search Wikipedia"),
                         action: .init(title: "Search", symbol: "magnifyingglass"),
                         permissions: ["network"])
        case "sefaria", "sefaria-search":
            return .init(input: .init(placeholder: "חפש מקור או ביטוי בספריא"),
                         action: .init(title: "חפש", symbol: "magnifyingglass"),
                         permissions: ["network"])
        case "json":
            return .init(input: .init(placeholder: "Paste JSON to format"),
                         action: .init(title: "Format", symbol: "curlybraces"))
        case "date":
            return .init(input: .init(placeholder: "No input needed", required: false),
                         action: .init(title: "Insert date", symbol: "calendar"))
        case "demo":
            return .init(input: .init(placeholder: "Optional name", required: false),
                         action: .init(title: "Run", symbol: "play.fill"),
                         result: .workspace)
        default:
            return .init(input: .init(placeholder: "Input for " + title,
                                      required: false),
                         action: .init(title: "Run", symbol: "play.fill"))
        }
    }

    /// Author-written JS can opt into a command bar UI using:
    /// // @keyboard-manifest {"input":{...},"action":{...},"result":"inlineList"}
    /// The editor keeps the directive in source, so import/export remain simple.
    static func parse(from source: String) -> Self? {
        for line in source.components(separatedBy: .newlines).prefix(12) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let marker = "// @keyboard-manifest "
            guard trimmed.hasPrefix(marker) else { continue }
            guard let data = String(trimmed.dropFirst(marker.count)).data(using: .utf8),
                  data.count <= 4096 else { return nil }
            return try? JSONDecoder().decode(Self.self, from: data)
        }
        return nil
    }

    func validated() -> Self {
        var copy = self
        copy.input.placeholder = String(input.placeholder.prefix(120))
        copy.input.maxLength = min(max(input.maxLength, 1), 4000)
        copy.action.title = String(action.title.prefix(32))
        copy.action.symbol = action.symbol.isEmpty ? "play.fill"
            : String(action.symbol.prefix(80))
        copy.permissions = permissions.filter { ["network", "clipboard"].contains($0) }
        return copy
    }
}

extension KeyboardScript {
    var commandManifest: LabCommandManifest {
        (manifest ?? .defaults(for: id, title: title)).validated()
    }
}
