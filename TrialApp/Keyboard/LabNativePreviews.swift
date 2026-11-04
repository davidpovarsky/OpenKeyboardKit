import SwiftUI

/// System-owned long-press preview for a native Keyboard Lab tool.
/// Only static details are shown: no network work is triggered by previewing.
struct LabToolPreview: View {
    let tool: LabTool
    let isFavorite: Bool

    private var needsNetwork: Bool {
        switch tool {
        case .sefaria, .wikipedia, .dictionary, .translate, .gif:
            return true
        default:
            return false
        }
    }

    private var explanatoryText: String {
        switch tool {
        case .sefaria: return "Search Jewish sources and insert selected references and passages."
        case .wikipedia: return "Look up articles without leaving the app you're writing in."
        case .dictionary: return "Search definitions and insert selected meanings."
        case .translate: return "Translate selected text after explicitly allowing a network request."
        case .gif: return "Browse public GIFs and copy a selection to the clipboard."
        case .clipboard: return "Save text manually, then reuse it from your private collection."
        case .notes: return "Keep private drafts inside the keyboard and insert them later."
        case .templates: return "Insert reusable messages in a single tap."
        case .calculator: return "Work out an expression locally and insert the result."
        case .conversion: return "Convert measurements, temperature, and time locally."
        case .textFX: return "Clean text, remove Hebrew diacritics, or change formatting."
        case .ai: return "Local text helpers; generative AI is not configured yet."
        case .emoji: return "Select symbols and emojis without opening another app."
        case .handwriting: return "Draw with Apple Pencil and explicitly copy the image."
        case .media: return "Open native Apple pickers for selected photos or files."
        case .themes: return "Choose a palette for the tool interface."
        case .profiles: return "Pick up to six favorites for quick access."
        case .layouts: return "Adjust the keyboard's expanded layout preferences."
        case .scripts: return "Manage JavaScriptCore scripts and native SwiftUI forms."
        case .quickForm: return "Build a status brief with native SwiftUI controls and insert it directly."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 29, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tool.tint)
                    .frame(width: 64, height: 64)
                    .background(tool.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 19))

                Spacer(minLength: 12)

                if isFavorite {
                    Label("Favorite", systemImage: "star.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(tool.tint)
                }
            }

            Text(tool.title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(explanatoryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Label(
                needsNetwork ? "Online tool · Network permission required" : "Native Keyboard Lab tool",
                systemImage: needsNetwork ? "wifi" : "keyboard"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(19)
        .frame(width: 294, alignment: .leading)
        .background(
            LinearGradient(
                colors: [tool.tint.opacity(0.095), Color(uiColor: .secondarySystemBackground)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}

struct LabScriptPreview: View {
    let script: KeyboardScript

    private var excerpt: String {
        let trimmed = script.source.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(250))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 9) {
                Image(systemName: script.symbol)
                    .font(.title2)
                    .foregroundStyle(.indigo)
                    .frame(width: 38, height: 38)
                    .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(script.title).font(.headline)
                    Text(script.isBuiltIn ? "Built-in script" : "Custom script")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text(script.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Text(excerpt)
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(9)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(11)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(17)
        .frame(width: 307, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 19))
    }
}

struct LabResultPreview: View {
    let result: LabSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Result preview", systemImage: "text.magnifyingglass")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(result.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if !result.summary.isEmpty {
                Text(result.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(12)
            }
            Label("Choose Insert to add this text", systemImage: "text.insert")
                .font(.caption2)
                .foregroundStyle(.indigo)
        }
        .padding(17)
        .frame(width: 302, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 18))
    }
}


struct LabSavedTextPreview: View {
    let title: String
    let text: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.indigo)
            Divider()
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(12)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Label("Tap Insert or choose an action", systemImage: "hand.tap")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(17)
        .frame(width: 290, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 18))
    }
}
