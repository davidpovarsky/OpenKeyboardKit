import OpenKeyboardKit
import SwiftUI

/// Each mode is rendered in SwiftUI inside the *same* system keyboard extension.
/// No WebViews, app switches, or embedded browser interfaces are used.
private enum LabScreen {
    case typing
    case tools
    case detail(LabTool)
}

struct TrialKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let insertText: (String) -> Void
    let readContext: () -> String
    let fullAccess: Bool
    let setExpanded: (Bool) -> Void

    @EnvironmentObject private var keyboardContext: KeyboardContext
    @State private var screen: LabScreen = .typing
    @AppStorage("keyboard.lab.expanded") private var expanded = true
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue

    var body: some View {
        VStack(spacing: 0) {
            switch screen {
            case .typing:
                if expanded {
                    LabQuickAccess(
                        open: openTool,
                        showAll: { screen = .tools }
                    )
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                }

                // The actual typing keys remain pinned to the physical bottom
                // of the extension; flexible tool area belongs ABOVE them.
                standardKeyboard
                    .fixedSize(horizontal: false, vertical: true)

            case .tools:
                LabToolHome(
                    onSelect: openTool,
                    onClose: { screen = .typing }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .detail(let tool):
                LabToolPage(
                    tool: tool,
                    close: { screen = .tools },
                    returnToKeyboard: { screen = .typing },
                    insertText: insertText,
                    readContext: readContext,
                    fullAccess: fullAccess
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color(uiColor: .secondarySystemBackground))
        .onAppear { setExpanded(expanded) }
    }

    private func openTool(_ tool: LabTool) {
        expanded = true
        setExpanded(true)
        screen = .detail(tool)
    }

    private func changeHeight() {
        expanded.toggle()
        setExpanded(expanded)
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
                    HStack(spacing: 10) {
                        toolButton("Tools", symbol: "square.grid.2x2") {
                            expanded = true
                            setExpanded(true)
                            screen = .tools
                        }
                        Spacer(minLength: 6)
                        toolButton("Search", symbol: "magnifyingglass") {
                            openTool(.wikipedia)
                        }
                        toolButton("Sefaria", symbol: "books.vertical") {
                            openTool(.sefaria)
                        }
                        toolButton("JS", symbol: "curlybraces.square") {
                            openTool(.scripts)
                        }
                        Spacer(minLength: 6)
                        toolButton(expanded ? "Compact" : "Expand",
                                   symbol: expanded ?
                                     "arrow.down.right.and.arrow.up.left" :
                                     "arrow.up.left.and.arrow.down.right") {
                            changeHeight()
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                }
            }
        )
    }

    private func toolButton(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .medium))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.primary)
                .padding(.vertical, 7)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
