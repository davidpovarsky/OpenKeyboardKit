import SwiftUI

/// A native SwiftUI Hebrew layout that routes input to a tool field OR
/// to the host UITextDocumentProxy according to the selected target.
struct LabToolHebrewKeyboard: View {
    @ObservedObject var router: LabInputRouter
    let useEnglish: () -> Void
    let openTools: () -> Void
    let returnToTyping: () -> Void
    let insertHost: (String) -> Void
    let deleteHost: () -> Void
    let returnHost: () -> Void

    private func type(_ value: String) {
        if router.isHostTarget { insertHost(value) }
        else { router.insert(value) }
    }

    private func erase() {
        if router.isHostTarget { deleteHost() }
        else { router.deletePrevious() }
    }

    private func submit() {
        if router.isHostTarget { returnHost() }
        else { router.returnKey() }
    }

    @State private var symbols = false
    @AppStorage("keyboard.lab.theme") private var theme = LabTheme.classic.rawValue

    private var rows: [[String]] {
        if symbols {
            return [
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
                ["@", "#", "₪", "%", "&", "*", "-", "+", "(", ")"],
                [".", ",", ":", ";", "!", "?", "/", "'", "״"]
            ]
        }
        return [
            ["פ", "ם", "ן", "ו", "ט", "א", "ר", "ק", "׳", "/"],
            ["ף", "ך", "ל", "ח", "י", "ע", "כ", "ג", "ד", "ש"],
            ["ץ", "ת", "צ", "מ", "נ", "ה", "ב", "ס", "ז"]
        ]
    }

    var body: some View {
        VStack(spacing: 5) {
            LabNativeToolbar(
                title: router.isHostTarget ? "Typing in App" : "Editing Tool",
                leading: [
                    LabToolbarCommand(
                        id: "he.tools", title: "Tools", symbol: "square.grid.2x2",
                        action: openTools
                    ),
                    LabToolbarCommand(
                        id: "he.english", title: "English", symbol: "globe",
                        action: useEnglish
                    )
                ],
                trailing: [
                    LabToolbarCommand(
                        id: "he.app", title: "To App",
                        symbol: "rectangle.and.pencil.and.ellipsis",
                        action: { router.activateHost() }
                    ),
                    LabToolbarCommand(
                        id: "he.done", title: "Keyboard",
                        symbol: "keyboard", action: returnToTyping
                    )
                ]
            )
            .frame(height: 43)

            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 5) {
                    ForEach(rows[index], id: \.self) { char in
                        Button { type(char) } label: {
                            Text(char)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color(uiColor: .tertiarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    if index == 2 {
                        Button { erase() } label: {
                            Image(systemName: "delete.left")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.gray.opacity(0.23),
                                            in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .environment(\.layoutDirection, .rightToLeft)
            }

            HStack(spacing: 5) {
                Button { symbols.toggle() } label: {
                    Text(symbols ? "אבג" : "123").frame(width: 58)
                }
                Button(action: useEnglish) {
                    Image(systemName: "globe").frame(width: 53)
                }
                Button { type(" ") } label: {
                    Text("רווח").frame(maxWidth: .infinity)
                }
                Button { submit() } label: {
                    Image(systemName: "return").frame(width: 74)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)
            .buttonStyle(.plain)
            .frame(height: 43)
            .padding(.horizontal, 7)
            .background {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 7).fill(.gray.opacity(0.17)).frame(width: 65)
                    RoundedRectangle(cornerRadius: 7).fill(.gray.opacity(0.17)).frame(width: 60)
                    RoundedRectangle(cornerRadius: 7).fill(Color(uiColor: .tertiarySystemBackground))
                    RoundedRectangle(cornerRadius: 7).fill(.gray.opacity(0.17)).frame(width: 80)
                }
                .padding(.horizontal, 7)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .background(LabDesign.canvas)
    }
}
