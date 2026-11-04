import OpenKeyboardKit
import SwiftUI

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

    @EnvironmentObject private var keyboardContext: KeyboardContext
    @State private var screen: LabScreen = .typing
    @State private var useHebrewInTools = false
    @AppStorage("keyboard.lab.expanded") private var expanded = true
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue

    var body: some View {
        VStack(spacing: 0) {
            if screen == .typing {
                if expanded {
                    LabQuickAccess(open: openTool, showAll: openLibrary)
                    Spacer(minLength: 0)
                } else {
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

            // Always keep real input keys under the tool workspace.
            // Standard OpenKeyboardKit is retained for English and host typing.
            // Hebrew is a native extension-owned layout, also routed to tool fields.
            if screen != .typing && useHebrewInTools {
                LabToolHebrewKeyboard(
                    router: inputRouter,
                    useEnglish: { useHebrewInTools = false },
                    openTools: openLibrary,
                    returnToTyping: returnToTyping,
                    insertHost: insertText,
                    deleteHost: deleteHost,
                    returnHost: { insertText("\n") }
                )
                .fixedSize(horizontal: false, vertical: true)
            } else {
                standardKeyboard
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(LabDesign.canvas)
        .environmentObject(inputRouter)
        .onAppear {
            inputRouter.setToolMode(screen != .typing)
            setExpanded(expanded)
        }
        .onChange(of: screen) { newValue in
            let toolsActive = newValue != .typing
            inputRouter.setToolMode(toolsActive)
            setExpanded(expanded) // Recompute height for typing vs tool modes
        }
    }

    private func openLibrary() {
        inputRouter.unfocus()
        screen = .tools
    }

    private func returnToTyping() {
        inputRouter.unfocus()
        screen = .typing
    }

    private func openTool(_ tool: LabTool) {
        inputRouter.unfocus()
        expanded = true
        screen = .detail(tool)
    }

    private func changeHeight() {
        expanded.toggle()
        setExpanded(expanded)
    }

    private var toolbarLeading: [LabToolbarCommand] {
        if screen == .typing {
            return [
                .init(id: "kb.tools", title: "Tools",
                      symbol: "square.grid.2x2", action: openLibrary),
                .init(id: "kb.wikipedia", title: "Search",
                      symbol: "magnifyingglass", action: { openTool(.wikipedia) })
            ]
        }
        return [
            .init(id: "kb.back", title: "Keyboard",
                  symbol: "keyboard", action: returnToTyping),
            .init(id: "kb.alltools", title: "Tools",
                  symbol: "square.grid.2x2", action: openLibrary),
            .init(id: "kb.hebrew", title: "עברית",
                  symbol: "globe", action: { useHebrewInTools = true })
        ]
    }

    private var toolbarTrailing: [LabToolbarCommand] {
        if screen == .typing {
            return [
                .init(id: "kb.scripts", title: "Scripts",
                      symbol: "curlybraces.square", action: { openTool(.scripts) }),
                .init(id: "kb.expand", title: expanded ? "Compact" : "Expand",
                      symbol: expanded ?
                        "arrow.down.right.and.arrow.up.left" :
                        "arrow.up.left.and.arrow.down.right",
                      action: changeHeight)
            ]
        }
        return [
            .init(id: "kb.scripts", title: "Scripts",
                  symbol: "curlybraces.square", action: { openTool(.scripts) }),
            .init(id: "kb.host", title: "To App",
                  symbol: "rectangle.and.pencil.and.ellipsis",
                  style: .done, action: { inputRouter.activateHost() })
        ]
    }

    private var standardKeyboard: some View {
        KeyboardView(
            layout: KeyboardLayout.standard(for: keyboardContext),
            state: state,
            services: services,
            buttonContent: { $0.view },
            buttonView: { $0.view },
            collapsedView: { $0.view },
            emojiKeyboard: { $0.view },
            toolbar: { _ in
                Keyboard.Toolbar {
                    LabNativeToolbar(
                        leading: toolbarLeading,
                        trailing: toolbarTrailing
                    )
                    .frame(height: 46)
                }
            }
        )
    }
}
