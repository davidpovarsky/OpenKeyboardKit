import SwiftUI

/// A small, fully native search-input keyboard INSIDE the tool workspace.
/// It never requests a second iPadOS keyboard or changes the host text field.
/// Text is collected locally and sent only when the user taps Search.
struct LabInlineKeyboard: View {
    @Binding var text: String
    let submit: () -> Void

    @State private var hebrew = true
    @State private var symbols = false

    private var rows: [[String]] {
        if symbols {
            return [
                Array("1234567890").map(String.init),
                ["@", "#", "$", "%", "&", "*", "-", "+", "(", ")"],
                [".", ",", ":", ";", "!", "?", "/", "'", "\"", "="]
            ]
        }
        if hebrew {
            return [
                ["פ", "ם", "ן", "ו", "ט", "א", "ר", "ק", "׳", "/"],
                ["ש", "ד", "ג", "כ", "ע", "י", "ח", "ל", "ך", "ף"],
                ["ז", "ס", "ב", "ה", "נ", "מ", "צ", "ת", "ץ"]
            ]
        }
        return [
            Array("qwertyuiop").map(String.init),
            Array("asdfghjkl").map(String.init),
            Array("zxcvbnm").map(String.init)
        ]
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 4) {
                    ForEach(rows[index], id: \.self) { key in
                        Button { text += key } label: {
                            Text(key)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 39)
                                .background(Color(uiColor: .tertiarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .environment(\.layoutDirection, hebrew ? .rightToLeft : .leftToRight)
            }

            HStack(spacing: 5) {
                keyButton(symbols ? (hebrew ? "אבג" : "ABC") : "123", symbol: nil) {
                    symbols.toggle()
                }
                keyButton(hebrew ? "EN" : "עב", symbol: "globe") {
                    hebrew.toggle()
                }
                Button { text += " " } label: {
                    Text("space")
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(uiColor: .tertiarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                keyButton("", symbol: "delete.left") {
                    guard !text.isEmpty else { return }
                    text.removeLast()
                }
                keyButton("", symbol: "magnifyingglass") { submit() }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func keyButton(
        _ title: String,
        symbol: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 16, weight: .medium))
                } else {
                    Text(title).font(.system(size: 14, weight: .medium))
                }
            }
            .frame(width: 51, height: 40)
            .foregroundStyle(.primary)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}
