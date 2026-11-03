import OpenKeyboardKit
import SwiftUI

struct TrialKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let insertText: (String) -> Void
    let readContext: () -> String
    let fullAccess: Bool
    let setExpanded: (Bool) -> Void

    @EnvironmentObject private var keyboardContext: KeyboardContext
    @State private var showScripts = false
    @State private var expanded = true

    var body: some View {
        Group {
            if showScripts {
                ScriptStudioView(
                    onClose: { showScripts = false },
                    insertText: insertText,
                    readContext: readContext,
                    fullAccess: fullAccess
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                                toolButton("Scripts", symbol: "curlybraces.square") {
                                    showScripts = true
                                    setExpanded(true)
                                    expanded = true
                                }
                                Spacer(minLength: 6)
                                toolButton("שלום", symbol: "textformat") { insertText("שלום") }
                                toolButton("©", symbol: "c.circle") { insertText("©") }
                                Spacer(minLength: 6)
                                toolButton(expanded ? "קטן" : "גדול", symbol: expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
                                    expanded.toggle()
                                    setExpanded(expanded)
                                }
                            }
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                        }
                    }
                )
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func toolButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .medium))
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
