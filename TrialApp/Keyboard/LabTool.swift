import SwiftUI

/// Tool identifiers are stable because they are persisted in user preferences.
enum LabTool: String, CaseIterable, Identifiable, Hashable {
    case emoji, clipboard, notes, translate, dictionary, ai, textFX, calculator
    case conversion, sefaria, wikipedia, templates, handwriting, media
    case themes, profiles, layouts, scripts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emoji: return "Emoji"
        case .clipboard: return "Clipboard"
        case .notes: return "Notepad"
        case .translate: return "Translate"
        case .dictionary: return "Dictionary"
        case .ai: return "AI Tools"
        case .textFX: return "Text FX"
        case .calculator: return "Calculator"
        case .conversion: return "Conversion"
        case .sefaria: return "Sefaria"
        case .wikipedia: return "Wikipedia"
        case .templates: return "Snippets"
        case .handwriting: return "Handwriting"
        case .media: return "Photos & Files"
        case .themes: return "Themes"
        case .profiles: return "Profiles"
        case .layouts: return "Layouts"
        case .scripts: return "Plugins & JS"
        }
    }

    var detail: String {
        switch self {
        case .emoji: return "Insert favorite symbols"
        case .clipboard: return "Save clips with permission"
        case .notes: return "Quick private notes"
        case .translate: return "Live translation & text"
        case .dictionary: return "Word definitions"
        case .ai: return "Smart writing actions"
        case .textFX: return "Fix and transform text"
        case .calculator: return "Math and percentages"
        case .conversion: return "Units and temperatures"
        case .sefaria: return "Jewish texts and sources"
        case .wikipedia: return "Search encyclopedia"
        case .templates: return "One-tap responses"
        case .handwriting: return "Draw with Apple Pencil"
        case .media: return "Pick photos and files"
        case .themes: return "Customize appearance"
        case .profiles: return "Personal shortcuts"
        case .layouts: return "Keyboard behavior"
        case .scripts: return "JavaScriptCore library"
        }
    }

    var symbol: String {
        switch self {
        case .emoji: return "face.smiling"
        case .clipboard: return "doc.on.clipboard"
        case .notes: return "note.text"
        case .translate: return "character.bubble"
        case .dictionary: return "text.book.closed"
        case .ai: return "sparkles"
        case .textFX: return "textformat"
        case .calculator: return "plus.forwardslash.minus"
        case .conversion: return "arrow.left.arrow.right"
        case .sefaria: return "books.vertical"
        case .wikipedia: return "globe.europe.africa"
        case .templates: return "text.bubble"
        case .handwriting: return "pencil.tip.crop.circle"
        case .media: return "photo.on.rectangle.angled"
        case .themes: return "paintpalette"
        case .profiles: return "person.crop.circle"
        case .layouts: return "square.grid.2x2"
        case .scripts: return "puzzlepiece.extension"
        }
    }

    var tint: Color {
        switch self {
        case .emoji, .notes: return Color(red: 0.85, green: 0.59, blue: 0.04)
        case .clipboard, .translate, .wikipedia: return Color(red: 0.12, green: 0.53, blue: 0.88)
        case .dictionary, .media: return Color(red: 0.54, green: 0.40, blue: 0.29)
        case .ai, .scripts: return Color(red: 0.68, green: 0.28, blue: 0.83)
        case .textFX, .handwriting: return Color(red: 0.84, green: 0.29, blue: 0.52)
        case .calculator, .layouts: return Color(red: 0.96, green: 0.49, blue: 0.16)
        case .conversion, .templates: return Color(red: 0.18, green: 0.66, blue: 0.37)
        case .sefaria: return Color(red: 0.20, green: 0.43, blue: 0.69)
        case .themes: return Color(red: 0.59, green: 0.35, blue: 0.79)
        case .profiles: return Color(red: 0.35, green: 0.35, blue: 0.85)
        }
    }

    var bg: Color { tint.opacity(0.105) }

    static let favorites: [LabTool] = [.sefaria, .wikipedia, .clipboard, .textFX, .calculator, .templates]
}

enum LabTheme: String, CaseIterable, Identifiable {
    case classic, lavender, mint, coral, sky

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var accent: Color {
        switch self {
        case .classic: return .indigo
        case .lavender: return Color(red: 0.58, green: 0.38, blue: 0.83)
        case .mint: return Color(red: 0.11, green: 0.62, blue: 0.48)
        case .coral: return Color(red: 0.91, green: 0.36, blue: 0.36)
        case .sky: return Color(red: 0.23, green: 0.54, blue: 0.93)
        }
    }
}

enum LabText {
    static func clip(_ text: String, limit: Int = 5000) -> String {
        String(text.prefix(limit))
    }

    /// Hebrew niqqud and cantillation, excluding ordinary Hebrew characters.
    static func removeNiqqud(_ text: String) -> String {
        String(String.UnicodeScalarView(text.unicodeScalars.filter { scalar in
            let value = scalar.value
            return !((0x0591...0x05C7).contains(value) &&
                     !(0x05BE...0x05BE).contains(value) &&
                     !(0x05C0...0x05C0).contains(value) &&
                     !(0x05C3...0x05C3).contains(value) &&
                     !(0x05C6...0x05C6).contains(value))
        }))
    }

    static func compactWhitespace(_ text: String) -> String {
        text.replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
