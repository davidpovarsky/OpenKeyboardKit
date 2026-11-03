import OpenKeyboardKit
import SwiftUI

struct TrialKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let insertText: (String) -> Void

    @EnvironmentObject private var keyboardContext: KeyboardContext

    var body: some View {
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
                    HStack(spacing: 16) {
                        toolButton("שלום", symbol: "textformat") {
                            insertText("שלום")
                        }
                        Spacer(minLength: 10)
                        toolButton("—", symbol: "minus") {
                            insertText("—")
                        }
                        Spacer(minLength: 10)
                        toolButton("©", symbol: "c.circle") {
                            insertText("©")
                        }
                    }
                    .padding(.horizontal, 16)
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
                .labelStyle(.titleAndIcon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.vertical, 7)
                .padding(.horizontal, 9)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
