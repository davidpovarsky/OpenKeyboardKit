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
            } else if tool == .gif {
                LabGIFPanel(fullAccess: fullAccess, networkAllowed: allowNetwork)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if [.wikipedia, .sefaria, .dictionary].contains(tool) {
                LabSearchPanel(
                    tool: tool,
                    fullAccess: fullAccess,
                    networkAllowed: allowNetwork,
                    readContext: readContext,
                    insertText: insertText
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            EmptyView()
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
        case .handwriting, .scripts, .gif:
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
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text(query.isEmpty ? "Type a word to search..." : query)
                    .foregroundStyle(query.isEmpty ? .secondary : .primary)
                    .font(.system(size: 15))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 29, alignment: .leading)
                if !query.isEmpty {
                    Button {
                        query = ""
                        model.cancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 45)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 13)
            .padding(.top, 8)

            HStack(spacing: 10) {
                Button("From cursor") {
                    let text = readContext()
                    query = String((text.components(separatedBy: .newlines).last ?? text).suffix(100))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .buttonStyle(.bordered)

                Button("Paste") {
                    if fullAccess { query = UIPasteboard.general.string ?? "" }
                }
                .buttonStyle(.bordered)
                .disabled(!fullAccess)

                Button("Search", action: runSearch)
                    .buttonStyle(.borderedProminent)
                    .disabled(!ready || query.isEmpty)

                if model.loading { ProgressView().controlSize(.small) }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 13)
            .font(.caption)

            if !ready {
                Text("Enable Full Access and Network On in Script Studio for live results.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 13)
            }
            if !model.notice.isEmpty {
                Text(model.notice)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
            }

            ScrollView {
                LazyVStack(spacing: 9) {
                    ForEach(model.results) { result in
                        Button { insertText(result.insertion) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(result.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                if !result.summary.isEmpty {
                                    Text(result.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                }
                                Label("Insert", systemImage: "text.insert")
                                    .font(.caption2)
                                    .foregroundStyle(.indigo)
                            }
                            .padding(11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .tertiarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                    }
                    if model.results.isEmpty && !model.loading {
                        Text("Enter a query on the keyboard below, then tap Search.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 13)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            LabInlineKeyboard(text: $query, submit: runSearch)
                .fixedSize(horizontal: false, vertical: true)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .onDisappear { model.cancel() }
    }

    private func runSearch() {
        model.search(query, in: tool, authorized: ready)
    }
}
