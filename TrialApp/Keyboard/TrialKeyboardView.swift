import OpenKeyboardKit
import SwiftUI
import UIKit

/// One persistent keyboard, with changing native SwiftUI workspaces ABOVE it.
/// In particular, tool UI never replaces the actual keyboard.
private enum LabScreen: Equatable {
    case typing
    case tools
    case detail(LabTool)
}

struct TrialKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let insertText: (String) -> Void
    let deleteHost: () -> Void
    let readContext: () -> String
    let fullAccess: Bool
    @ObservedObject var inputRouter: LabInputRouter
    @ObservedObject var completions: LabLocalCompletions
    let applyCompletion: (String) -> Void
    let refreshSuggestions: () -> Void
    let setExpanded: (Bool) -> Void
    let setWorkspaceVisible: (Bool) -> Void
    let setResultsVisible: (Bool) -> Void

    @EnvironmentObject private var keyboardContext: KeyboardContext
    @State private var screen: LabScreen = .typing
    @AppStorage("keyboard.lab.hebrew.enabled") private var useHebrew = false
    @State private var showsKeys = true
    @State private var scriptReloadToken = 0
    @State private var isResultsShowing = false
    @State private var toolSearch = ""
    @AppStorage("keyboard.lab.v010.expanded") private var expanded = false
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue

    var body: some View {
        VStack(spacing: 0) {
            if screen != .typing {
                Group {
                    switch screen {
                    case .typing:
                        EmptyView()
                    case .tools:
                        LabToolHome(
                            onSelect: openTool,
                            onClose: returnToTyping,
                            search: $toolSearch
                        )
                    case .detail(let tool):
                        LabToolPage(
                            tool: tool,
                            close: openLibrary,
                            returnToKeyboard: returnToTyping,
                            insertText: insertText,
                            readContext: readContext,
                            fullAccess: fullAccess
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if inputRouter.activeKey != nil &&
                   inputRouter.activeKey != "command.bar.input" &&
                   inputRouter.activeKey != "launcher.search" {
                    LabInputAccessory()
                }
            }

            LabSmartCommandBar(
                completions: completions,
                insertText: insertText,
                readContext: readContext,
                fullAccess: fullAccess,
                isKeyboardVisible: showsKeys,
                setKeyboardVisible: updateKeyVisibility,
                openTool: openTool,
                scriptReloadToken: scriptReloadToken,
                toolSearch: $toolSearch,
                isToolsOpen: screen == .tools,
                isHebrew: useHebrew,
                switchLanguage: { useHebrew.toggle() },
                openLibrary: openLibrary,
                returnToTyping: returnToTyping,
                openScripts: { openTool(.scripts) },
                changeHeight: changeHeight,
                applyCompletion: applyCompletion,
                setResultsVisible: { visible in
                    isResultsShowing = visible
                    setPresentationHeight()
                },
                keyboardView: { toolbar in
                    AnyView(
                        standardKeyboard(toolbar: toolbar)
                            .fixedSize(horizontal: false, vertical: true)
                    )
                }
            )
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(LabDesign.canvas)
        .environmentObject(inputRouter)
        .onAppear {
            inputRouter.setToolMode(true)
            setExpanded(expanded)
            setPresentationHeight()
        }
        .onChange(of: screen) { newValue in
            inputRouter.setToolMode(true)
            setPresentationHeight()
            if newValue != .detail(.scripts) {
                scriptReloadToken += 1
            }
        }
        .onChange(of: showsKeys) { visible in
            setPresentationHeight()
        }
        .onChange(of: useHebrew) { _ in
            refreshSuggestions()
        }
        .onChange(of: inputRouter.activeKey) { active in
            if active != nil && !showsKeys {
                showsKeys = true
            }
        }
    }

    private func setPresentationHeight() {
        setWorkspaceVisible(screen != .typing || !showsKeys)
        setResultsVisible(isResultsShowing && showsKeys)
    }


    private func updateKeyVisibility(_ visible: Bool) {
        if visible == showsKeys { return }
        if !visible {
            inputRouter.activateHost()
        }
        withAnimation(.smooth(duration: 0.2)) {
            showsKeys = visible
        }
    }

    private func openLibrary() {
        inputRouter.unfocus()
        screen = .tools
        // Open full workspace instead of squeezing cards above keys.
        showsKeys = false
    }

    private func returnToTyping() {
        inputRouter.unfocus()
        showsKeys = true
        screen = .typing
    }

    private func openTool(_ tool: LabTool) {
        inputRouter.unfocus()
        screen = .detail(tool)
        // Tool pages can use the entire extension until an input is selected.
        showsKeys = false
    }

    private func changeHeight() {
        if !showsKeys { showsKeys = true }
        expanded.toggle()
        setExpanded(expanded)
    }

    private func standardKeyboard(toolbar: AnyView) -> some View {
        KeyboardView(
            layout: useHebrew
                ? LabHebrewLayout.make(for: keyboardContext)
                : KeyboardLayout.standard(for: keyboardContext),
            state: state,
            services: services,
            buttonContent: { $0.view },
            buttonView: { $0.view },
            collapsedView: { $0.view },
            emojiKeyboard: { $0.view },
            toolbar: { _ in
                Keyboard.Toolbar {
                    toolbar
                }
            }
        )
    }

}
