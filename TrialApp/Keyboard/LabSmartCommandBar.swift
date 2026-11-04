import SwiftUI
import JavaScriptCore
import UIKit

private struct LabCommandResult: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let insertion: String?
}

/// A single extension-owned input line above the existing KeyboardKit keys.
/// Choosing a command changes its manifest; only an explicit Run performs
/// network or JavaScript work. No system UITextField becomes first responder.
struct LabSmartCommandBar: View {
    @EnvironmentObject private var router: LabInputRouter
    @StateObject private var lookup = LabLookup()
    @StateObject private var scriptRunner = ScriptStudioModel()

    @AppStorage("keyboard.trial.allowNetwork") private var allowNetwork = false
    @AppStorage("keyboard.lab.command.selected.v1") private var selection = "tool:sefaria"
    @AppStorage("keyboard.lab.command.recents.v1") private var recentIDs = ""

    @State private var query = ""
    @State private var notice = ""
    @State private var outputVisible = false
    @State private var localResults: [LabCommandResult] = []
    @State private var fieldValues: [String: String] = [:]
    @State private var showsCommandInput = false
    @AppStorage("keyboard.lab.autocomplete.enabled")
    private var suggestionsEnabled = true
    @ObservedObject var completions: LabLocalCompletions

    let insertText: (String) -> Void
    let readContext: () -> String
    let fullAccess: Bool
    let isKeyboardVisible: Bool
    let setKeyboardVisible: (Bool) -> Void
    let openTool: (LabTool) -> Void
    let scriptReloadToken: Int
    @Binding var toolSearch: String
    let isToolsOpen: Bool
    let isTypingScreen: Bool
    let isLargeKeyboard: Bool
    let activeWorkspaceTool: LabTool?
    let isHebrew: Bool
    let switchLanguage: () -> Void
    let openLibrary: () -> Void
    let returnToTyping: () -> Void
    let openScripts: () -> Void
    let changeHeight: () -> Void
    let applyCompletion: (String) -> Void
    let setResultsVisible: (Bool) -> Void
    let keyboardView: (AnyView) -> AnyView

    private let inputID = "command.bar.input"

    private var selectedTool: LabTool? {
        guard selection.hasPrefix("tool:") else { return nil }
        return LabTool(rawValue: String(selection.dropFirst(5)))
    }

    private var availableScripts: [KeyboardScript] {
        ScriptLibrary.scripts + scriptRunner.customScripts
    }

    private var selectedScript: KeyboardScript? {
        guard selection.hasPrefix("script:") else { return nil }
        let id = String(selection.dropFirst(7))
        return availableScripts.first { $0.id == id }
    }

    private var activeManifest: LabCommandManifest {
        if let selectedScript { return selectedScript.commandManifest }
        switch selectedTool {
        case .sefaria:
            return .defaults(for: "sefaria-search", title: "Sefaria")
        case .wikipedia:
            return .defaults(for: "wikipedia", title: "Wikipedia")
        case .dictionary:
            return .init(input: .init(placeholder: "Search English definitions"),
                         action: .init(title: "Search", symbol: "magnifyingglass"),
                         permissions: ["network"])
        case .calculator:
            return .init(input: .init(placeholder: "12 * (8 + 2)"),
                         action: .init(title: "Calculate", symbol: "equal"))
        case .textFX:
            return .init(input: .init(placeholder: "Text to clean"),
                         action: .init(title: "Clean", symbol: "textformat"))
        default:
            return .init(input: .init(placeholder: "Open selected tool", required: false),
                         action: .init(title: "Open", symbol: "arrow.up.right.square"),
                         result: .workspace)
        }
    }

    private var title: String {
        selectedScript?.title ?? selectedTool?.title ?? "Sefaria"
    }

    private var symbol: String {
        selectedScript?.symbol ?? selectedTool?.symbol ?? "books.vertical"
    }

    private var loading: Bool { lookup.loading || scriptRunner.isLoading }

    private var hasResultContent: Bool {
        !localResults.isEmpty || !lookup.results.isEmpty
            || scriptRunner.panel != nil
    }

    private var currentNotice: String {
        // Preflight permission and input errors are always more important
        // than stale script-model status from an earlier command.
        if !notice.isEmpty { return notice }
        if selectedScript != nil {
            return scriptRunner.status
        }
        if [.sefaria, .wikipedia, .dictionary].contains(selectedTool) {
            return lookup.notice
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            if outputVisible {
                resultPanel
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if showPredictions {
                predictionStrip
            }
            // The command row is the single real KeyboardKit toolbar.
            // When the user intentionally expands results instead of keys,
            // the same toolbar remains accessible as a standalone row.
            if isKeyboardVisible {
                keyboardView(AnyView(commandToolbar))
            } else {
                commandToolbar
                    .background(.thinMaterial)
            }
        }
        .onAppear {
            scriptRunner.reloadCustomScripts()
            if selectedTool == nil && selectedScript == nil {
                selection = "tool:sefaria"
            }
        }
        .onChange(of: query) { newValue in
            if newValue.count > activeManifest.input.maxLength {
                query = String(newValue.prefix(activeManifest.input.maxLength))
            }
        }
        .onChange(of: outputVisible) { visible in
            setResultsVisible(visible)
        }
        .onChange(of: activeWorkspaceTool) { tool in
            // When a tile opens Sefaria, Wikipedia, etc., the command bar
            // must not continue displaying the previously selected tool.
            guard let tool else { return }
            let id = "tool:" + tool.rawValue
            if selection != id {
                selection = id
                outputVisible = false
                localResults = []
                lookup.cancel()
                notice = ""
            }
        }
        .onChange(of: scriptReloadToken) { _ in
            scriptRunner.reloadCustomScripts()
            if selectedTool == nil && selectedScript == nil {
                selection = "tool:sefaria"
            }
        }
    }

    private var showPredictions: Bool {
        suggestionsEnabled && isTypingScreen && isKeyboardVisible &&
        router.isHostTarget && !outputVisible && !completions.suggestions.isEmpty
    }

    /// Predictions are an ephemeral row, never a replacement for the query.
    /// They consume real measured content height ONLY while suggestions exist.
    private var predictionStrip: some View {
        HStack(spacing: 6) {
            Text(isHebrew ? "השלמות" : "Suggestions")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize()
            ForEach(completions.suggestions, id: \.self) { suggestion in
                Button {
                    applyCompletion(suggestion)
                } label: {
                    Text(suggestion)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 27)
                }
                .buttonStyle(.bordered)
                .tint(.indigo)
                .accessibilityLabel("Insert suggestion " + suggestion)
            }
        }
        .padding(.horizontal, 7)
        .frame(height: 35)
        .transition(.opacity)
    }

    private var commandToolbar: some View {
        HStack(spacing: 5) {
            // Tools and size MUST remain one-tap actions, not buried in More.
            compactAction("Tools", symbol: "square.grid.2x2") {
                if isToolsOpen { returnToTyping() } else { openLibrary() }
            }
            .accessibilityLabel(isToolsOpen ? "Back to keyboard" : "Open all tools")

            chooser

            if isToolsOpen {
                LabSystemSearchField(
                    id: "launcher.search",
                    text: $toolSearch,
                    placeholder: "Search all tools"
                )
                .frame(maxWidth: .infinity, minHeight: 40)
            } else {
                LabSystemSearchField(
                    id: inputID,
                    text: $query,
                    placeholder: activeManifest.input.placeholder,
                    onSubmit: run
                )
                .frame(maxWidth: .infinity, minHeight: 40)
            }

            if isToolsOpen {
                compactAction("Done", symbol: "checkmark", action: returnToTyping)
            } else {
                LabGlassCommand(
                    title: activeManifest.action.title,
                    symbol: activeManifest.action.symbol,
                    compact: true, prominent: true, action: run
                )
                .disabled(loading || (activeManifest.input.required &&
                    query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                .accessibilityHint("Run " + title + " with the command input")
            }

            compactAction(
                isLargeKeyboard ? "Compact" : "Larger",
                symbol: isLargeKeyboard
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right",
                action: changeHeight
            )
            .accessibilityLabel(isLargeKeyboard
                ? "Reduce keyboard key size" : "Enlarge keyboard keys")

            Menu {
                Section("Navigate") {
                    Button(action: openScripts) {
                        Label("Script Studio", systemImage: "curlybraces.square")
                    }
                    Button(action: switchLanguage) {
                        Label(isHebrew ? "English" : "עברית", systemImage: "globe")
                    }
                    Button {
                        openTool(.layouts)
                    } label: {
                        Label("Keyboard Settings", systemImage: "gearshape")
                    }
                    if !isTypingScreen {
                        Button(action: returnToTyping) {
                            Label("Back to keyboard", systemImage: "keyboard")
                        }
                    }
                    Button {
                        setKeyboardVisible(!isKeyboardVisible)
                    } label: {
                        Label(isKeyboardVisible ? "Expand results" : "Show keys",
                              systemImage: isKeyboardVisible
                                ? "arrow.up.left.and.arrow.down.right" : "keyboard")
                    }
                    .disabled(isKeyboardVisible && !outputVisible)
                }

                Section("Input") {
                    Button {
                        let before = readContext()
                        query = String(before.suffix(activeManifest.input.maxLength))
                        showsCommandInput = true
                        router.focus(inputID, binding: $query, onReturn: run)
                        setKeyboardVisible(true)
                    } label: {
                        Label("From cursor", systemImage: "text.cursor")
                    }

                    Button {
                        router.activateHost()
                        showsCommandInput = false
                    } label: {
                        Label("Type in App", systemImage: "arrow.up.right.square")
                    }
                }

                Section("Typing") {
                    Toggle("Word completions", isOn: $suggestionsEnabled)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .medium))
                    .frame(minWidth: 34, minHeight: 35)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("More keyboard actions")
        }
        // Match the system keyboard's logical left-to-right control order
        // even while a Hebrew key layout is selected.
        .environment(\.layoutDirection, .leftToRight)
        .frame(height: 48)
        .padding(.horizontal, 6)
        .onChange(of: router.activeKey) { active in
            if active == inputID { showsCommandInput = true }
            else if active == nil { showsCommandInput = false }
        }
    }

    private func compactAction(_ title: String, symbol: String,
                               action: @escaping () -> Void) -> some View {
        LabGlassCommand(title: title, symbol: symbol,
                        compact: true, action: action)
    }

    private var chooser: some View {
        Menu {
            if !recentIDs.isEmpty {
                Section("Recent") {
                    ForEach(recentIDs.split(separator: "|").map(String.init), id: \.self) { id in
                        recentButton(id)
                    }
                }
            }

            Section("Tools") {
                ForEach(LabTool.allCases) { tool in
                    Button {
                        select("tool:" + tool.rawValue)
                    } label: {
                        Label(tool.title, systemImage: tool.symbol)
                    }
                }
            }

            Section("JavaScript") {
                ForEach(availableScripts) { script in
                    Button {
                        select("script:" + script.id)
                    } label: {
                        Label(script.title, systemImage: script.symbol)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 23)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .frame(maxWidth: 85)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .padding(.horizontal, 7)
            .frame(height: 40)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .accessibilityLabel("Choose tool or script")
    }

    @ViewBuilder
    private func recentButton(_ id: String) -> some View {
        if let tool = LabTool(rawValue: String(id.dropFirst(5))),
           id.hasPrefix("tool:") {
            Button {
                select(id)
            } label: {
                Label(tool.title, systemImage: tool.symbol)
            }
        } else if id.hasPrefix("script:"),
                  let script = availableScripts.first(where: { $0.id == String(id.dropFirst(7)) }) {
            Button {
                select(id)
            } label: {
                Label(script.title, systemImage: script.symbol)
            }
        }
    }

    private func select(_ id: String) {
        guard selection != id else {
            router.focus(inputID, binding: $query, onReturn: run)
            setKeyboardVisible(true)
            return
        }
        lookup.cancel()
        lookup.results = []
        lookup.notice = ""
        scriptRunner.stop()
        selection = id
        outputVisible = false
        localResults = []
        notice = ""
        fieldValues = [:]
        remember(id)
        router.focus(inputID, binding: $query, onReturn: run)
        setKeyboardVisible(true)
    }

    private func remember(_ id: String) {
        var ids = recentIDs.split(separator: "|").map(String.init)
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        recentIDs = ids.prefix(5).joined(separator: "|")
    }

    private func run() {
        let manifest = activeManifest
        let input = String(query.prefix(manifest.input.maxLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !manifest.input.required || !input.isEmpty else {
            notice = "Enter text before running."
            outputVisible = true
            return
        }

        remember(selection)
        localResults = []
        lookup.cancel()
        scriptRunner.stop()
        fieldValues = [:]
        notice = ""
        outputVisible = true

        if manifest.permissions.contains("network") && (!fullAccess || !allowNetwork) {
            notice = "Enable Full Access and Network On in Script Studio."
            return
        }

        if let selectedScript {
            scriptRunner.run(
                selectedScript, readContext: readContext,
                allowNetwork: allowNetwork && fullAccess,
                allowClipboard: fullAccess,
                insert: insertText, input: input
            )
            if manifest.result == .workspace {
                setKeyboardVisible(false)
            }
            return
        }

        guard let selectedTool else { return }
        switch selectedTool {
        case .sefaria, .wikipedia, .dictionary:
            lookup.search(input, in: selectedTool, authorized: fullAccess && allowNetwork)
        case .calculator:
            calculate(input)
        case .textFX:
            let cleaned = LabText.compactWhitespace(LabText.removeNiqqud(input))
            localResults = [.init(title: "Clean text", detail: cleaned, insertion: cleaned)]
            notice = "Processed locally."
        default:
            outputVisible = false
            openTool(selectedTool)
        }
    }

    private func calculate(_ input: String) {
        let normalized = input.replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
        guard !normalized.isEmpty, normalized.count <= 80,
              normalized.rangeOfCharacter(
                from: CharacterSet(charactersIn: "0123456789.+-*/()% ").inverted
              ) == nil else {
            notice = "Enter an arithmetic expression (numbers and + − × ÷)."
            return
        }
        let js = JSContext()
        js?.exceptionHandler = { _, _ in }
        guard let value = js?.evaluateScript("(" + normalized + ")"),
              let number = value.toNumber() as? NSNumber,
              number.doubleValue.isFinite else {
            notice = "Invalid arithmetic expression."
            return
        }
        let result = String(format: "%.9g", number.doubleValue)
        localResults = [.init(title: "Result", detail: result, insertion: result)]
        notice = "Calculated on this device."
    }

    private var resultPanel: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(.indigo)
                Text(title + " · Results")
                    .font(.system(size: 12, weight: .semibold))
                if loading {
                    ProgressView().controlSize(.mini)
                }
                Spacer()
                Button {
                    setKeyboardVisible(false)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .disabled(!isKeyboardVisible)

                Button {
                    outputVisible = false
                    setKeyboardVisible(true)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .buttonStyle(.plain)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 7) {
                    if selectedScript != nil, let panel = scriptRunner.panel {
                        if let message = panel.message, !message.isEmpty {
                            Text(message).font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(panel.fields ?? []) { field in
                            LabEditableField(
                                id: "command.field." + field.id,
                                placeholder: field.placeholder ?? field.title ?? field.id,
                                text: Binding(
                                    get: { fieldValues[field.id] ?? field.value ?? "" },
                                    set: { fieldValues[field.id] = $0 }
                                )
                            )
                        }
                        ForEach(panel.buttons ?? []) { button in
                            Button {
                                if let value = button.insert { insertText(value) }
                                else { scriptRunner.fireAction(button.id, values: fieldValues) }
                            } label: {
                                Label(button.title, systemImage: button.symbol ?? "bolt")
                            }
                            .buttonStyle(.bordered)
                        }
                        if selectedScript?.commandManifest.result == .inlineText {
                            ForEach(panel.rows ?? []) { item in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.title)
                                        .font(.caption.weight(.semibold))
                                    Text(item.insert ?? item.detail ?? "")
                                        .font(.system(size: 12))
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let insertion = item.insert {
                                        Button {
                                            router.activateHost()
                                            insertText(insertion)
                                        } label: {
                                            Label("Insert", systemImage: "text.insert")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .padding(9)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .tertiarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 11))
                            }
                        } else {
                            ForEach(panel.rows ?? []) { item in
                                resultRow(title: item.title,
                                          detail: item.detail ?? "",
                                          insertion: item.insert)
                            }
                        }
                    }

                    if selectedScript == nil {
                        ForEach(lookup.results) { item in
                            resultRow(title: item.title,
                                      detail: item.summary, insertion: item.insertion)
                        }
                        ForEach(localResults) { item in
                            resultRow(title: item.title,
                                      detail: item.detail, insertion: item.insertion)
                        }
                    }

                    if !currentNotice.isEmpty {
                        Text(currentNotice)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if !hasResultContent && !loading {
                        Text("No results yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: isKeyboardVisible ? 138 : .infinity)
        }
        .padding(11)
        .background(Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 9)
    }

    private func resultRow(title: String, detail: String, insertion: String?) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 3)
            if let insertion, !insertion.isEmpty {
                Button {
                    router.activateHost()
                    insertText(insertion)
                } label: {
                    Image(systemName: "text.insert")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Insert result into the host application")
            }
        }
        .padding(8)
        .background(Color(uiColor: .tertiarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 10))
    }
}
