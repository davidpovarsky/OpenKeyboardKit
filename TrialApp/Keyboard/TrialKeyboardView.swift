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
    let setExpanded: (Bool) -> Void
    let setWorkspaceVisible: (Bool) -> Void

    @EnvironmentObject private var keyboardContext: KeyboardContext
    @State private var screen: LabScreen = .typing
    @AppStorage("keyboard.lab.hebrew.enabled") private var useHebrew = false
    @State private var showsKeys = true
    @State private var scriptReloadToken = 0
    @AppStorage("keyboard.lab.expanded") private var expanded = true
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue

    var body: some View {
        VStack(spacing: 0) {
            if screen == .typing {
                if showsKeys {
                    if expanded {
                        LabQuickAccess(open: openTool, showAll: openLibrary)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                Group {
                    switch screen {
                    case .typing:
                        EmptyView()
                    case .tools:
                        LabToolHome(onSelect: openTool, onClose: returnToTyping)
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

                LabInputAccessory()
            }

            // This command bar is OUTSIDE Keyboard.Toolbar so it cannot
            // change KeyboardKit's intrinsic key layout or input view host.
            LabSmartCommandBar(
                insertText: insertText,
                readContext: readContext,
                fullAccess: fullAccess,
                isKeyboardVisible: showsKeys,
                setKeyboardVisible: updateKeyVisibility,
                openTool: openTool,
                scriptReloadToken: scriptReloadToken
            )
            .fixedSize(horizontal: false, vertical: true)

            // Keep key rendering bottom-pinned. A full workspace hides keys
            // intentionally and restores them on focus of any internal field.
            if showsKeys {
                standardKeyboard
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(LabDesign.canvas)
        .environmentObject(inputRouter)
        .onAppear {
            inputRouter.setToolMode(true)
            setExpanded(expanded)
            setWorkspaceVisible(screen != .typing || !showsKeys)
        }
        .onChange(of: screen) { newValue in
            inputRouter.setToolMode(true)
            setWorkspaceVisible(newValue != .typing || !showsKeys)
            if newValue != .detail(.scripts) {
                scriptReloadToken += 1
            }
        }
        .onChange(of: showsKeys) { visible in
            setWorkspaceVisible(screen != .typing || !visible)
        }
        .onChange(of: inputRouter.activeKey) { active in
            if active != nil && !showsKeys {
                showsKeys = true
            }
        }
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
    }

    private func returnToTyping() {
        inputRouter.unfocus()
        showsKeys = true
        screen = .typing
    }

    private func openTool(_ tool: LabTool) {
        inputRouter.unfocus()
        expanded = true
        screen = .detail(tool)
    }

    private func changeHeight() {
        if !showsKeys { showsKeys = true }
        expanded.toggle()
        setExpanded(expanded)
    }

    private var quickMenuItems: [LabSystemMenuItem] {
        [
            .init(id: "wiki", title: "Wikipedia", symbol: "globe.europe.africa",
                  action: { openTool(.wikipedia) }),
            .init(id: "sefaria", title: "Sefaria", symbol: "books.vertical",
                  action: { openTool(.sefaria) }),
            .init(id: "calculator", title: "Calculator",
                  symbol: "plus.forwardslash.minus",
                  action: { openTool(.calculator) }),
            .init(id: "clipboard", title: "Clipboard", symbol: "doc.on.clipboard",
                  action: { openTool(.clipboard) }),
            .init(id: "brief", title: "Quick Brief", symbol: "slider.horizontal.3",
                  action: { openTool(.quickForm) })
        ]
    }

    private var standardKeyboard: some View {
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
                    HStack(spacing: 8) {
                        toolButton(
                            screen == .typing ? "Tools" : "Keyboard",
                            symbol: screen == .typing ? "square.grid.2x2" : "keyboard"
                        ) {
                            if screen == .typing { openLibrary() }
                            else { returnToTyping() }
                        }
                        Spacer(minLength: 4)
                        if screen != .typing {
                            toolButton(useHebrew ? "English" : "עברית", symbol: "globe") {
                                useHebrew.toggle()
                            }
                            toolButton("Tools", symbol: "square.grid.2x2") {
                                openLibrary()
                            }
                        } else {
                            LabSystemMenuButton(items: quickMenuItems)
                                .frame(width: 43, height: 34)
                                .accessibilityLabel("Quick actions menu")
                            toolButton(useHebrew ? "EN" : "עברית", symbol: "globe") {
                                useHebrew.toggle()
                            }
                        }
                        toolButton("Scripts", symbol: "curlybraces.square") {
                            openTool(.scripts)
                        }
                        Spacer(minLength: 4)
                        if screen == .typing {
                            toolButton(
                                expanded ? "Compact" : "Expand",
                                symbol: expanded ?
                                    "arrow.down.right.and.arrow.up.left" :
                                    "arrow.up.left.and.arrow.down.right"
                            ) {
                                changeHeight()
                            }
                        } else {
                            toolButton("Done", symbol: "checkmark.circle") {
                                inputRouter.unfocus()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                }
            }
        )
    }

    private func toolButton(_ title: String, symbol: String,
                            action: @escaping () -> Void) -> some View {
        // Preserve the proven Keyboard.Toolbar / HStack layout from v0.7.1.
        // Only the button style is upgraded, not the toolbar ownership.
        LabGlassCommand(title: title, symbol: symbol,
                        compact: UIDevice.current.userInterfaceIdiom != .pad,
                        action: action)
    }
}
