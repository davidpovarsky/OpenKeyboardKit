import SwiftUI
import UIKit

struct LabToolPage: View {
    let tool: LabTool
    let close: () -> Void
    let returnToKeyboard: () -> Void
    let insertText: (String) -> Void
    let readContext: () -> String
    let fullAccess: Bool

    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue
    @AppStorage("keyboard.trial.allowNetwork") private var allowNetwork = false

    private var accent: Color { LabTheme(rawValue: themeName)?.accent ?? .indigo }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Button(action: close) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 38)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to tools")

                Image(systemName: tool.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tool.tint)
                    .frame(width: 37, height: 38)
                    .background(tool.bg, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.title).font(.headline)
                    Text(tool.detail).font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: returnToKeyboard) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 18))
                        .frame(width: 37, height: 38)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Return to keyboard")
            }
            .padding(.horizontal, 13)
            .frame(height: 64)

            Divider()

            if tool == .scripts {
                ScriptStudioView(
                    onClose: close,
                    insertText: insertText,
                    readContext: readContext,
                    fullAccess: fullAccess
                )
            } else if tool == .handwriting {
                LabHandwritingPanel(insertText: insertText, fullAccess: fullAccess)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        content
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .tint(accent)
    }

    @ViewBuilder
    private var content: some View {
        switch tool {
        case .wikipedia, .sefaria, .dictionary:
            LabSearchPanel(tool: tool, fullAccess: fullAccess,
                           networkAllowed: allowNetwork,
                           readContext: readContext, insertText: insertText)
        case .textFX, .ai:
            LabTextToolsPanel(isSmart: tool == .ai, readContext: readContext,
                              insertText: insertText, fullAccess: fullAccess)
        case .calculator:
            LabCalculatorPanel(insertText: insertText)
        case .conversion:
            LabConversionPanel(insertText: insertText)
        case .emoji:
            LabEmojiPanel(insertText: insertText)
        case .clipboard:
            LabClipboardPanel(insertText: insertText, fullAccess: fullAccess)
        case .notes:
            LabNotepadPanel(insertText: insertText)
        case .templates:
            LabSnippetsPanel(insertText: insertText)
        case .translate:
            LabTranslatePanel(readContext: readContext, insertText: insertText,
                              fullAccess: fullAccess, networkAllowed: allowNetwork)
        case .media:
            LabMediaPanel(insertText: insertText, fullAccess: fullAccess)
        case .themes:
            LabThemesPanel()
        case .profiles:
            LabProfilesPanel()
        case .layouts:
            LabLayoutsPanel()
        case .handwriting, .scripts:
            EmptyView()
        }
    }
}

struct LabHint: View {
    let text: String
    var icon: String = "info.circle"
    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 13))
    }
}

struct LabActionButton: View {
    let text: String
    var icon = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(text, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40)
        }
        .buttonStyle(.borderedProminent)
    }
}

struct LabSearchPanel: View {
    let tool: LabTool
    let fullAccess: Bool
    let networkAllowed: Bool
    let readContext: () -> String
    let insertText: (String) -> Void

    @StateObject private var model = LabLookup()
    @State private var query = ""

    private var ready: Bool { fullAccess && networkAllowed }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabHint(text: tool == .sefaria
                    ? "Search Torah, Mishnah, Talmud and commentaries with Sefaria's official API."
                    : tool == .wikipedia
                      ? "Search the Hebrew or English Wikipedia live."
                      : "Look up English definitions using the free dictionary API.",
                    icon: "magnifyingglass")

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Enter a word or phrase", text: $query)
                    .font(.subheadline)
                    .submitLabel(.search)
                    .onSubmit(runSearch)
                    .textInputAutocapitalization(.never)
                Button("Paste") {
                    if ready { query = UIPasteboard.general.string ?? "" }
                }
                .font(.caption)
                .disabled(!ready)
            }
            .padding(11)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 9) {
                Button("From cursor") {
                    let context = readContext()
                    query = String((context.components(separatedBy: .newlines).last ?? context).suffix(100))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .buttonStyle(.bordered)

                Button("Search", action: runSearch)
                    .buttonStyle(.borderedProminent)
                    .disabled(!ready || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if model.loading { ProgressView().controlSize(.small) }
            }

            if !ready {
                LabHint(text: "Enable Full Access in iPad Settings and Network On in the Script Studio to use live services.", icon: "wifi.slash")
            }
            if !model.notice.isEmpty {
                Text(model.notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(model.results) { result in
                Button { insertText(result.insertion) } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(result.title).font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        if !result.summary.isEmpty {
                            Text(result.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                        }
                        Label("Insert into text field", systemImage: "text.insert")
                            .font(.caption2)
                            .foregroundStyle(.indigo)
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .tertiarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear { model.cancel() }
    }

    private func runSearch() {
        model.search(query, in: tool, authorized: ready)
    }
}
