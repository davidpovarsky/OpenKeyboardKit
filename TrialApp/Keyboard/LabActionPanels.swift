import SwiftUI
import JavaScriptCore
import UIKit

struct LabTextToolsPanel: View {
    let isSmart: Bool
    let readContext: () -> String
    let insertText: (String) -> Void
    let fullAccess: Bool

    @State private var text = ""
    @State private var output = ""
    @State private var selectedAction = ""
    private let actions = ["Remove niqqud", "Clean spaces", "Uppercase", "Lowercase",
                           "Trim lines", "Strip HTML", "Remove Markdown",
                           "Word count", "Quote", "Make bullets"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabHint(text: isSmart
                    ? "On-device writing helpers. Generative AI requires an optional configured provider; no text is uploaded here."
                    : "Transform text entirely on your iPad. Nothing is uploaded.",
                    icon: isSmart ? "sparkles" : "textformat")

            TextEditor(text: $text)
                .font(.system(size: 14))
                .frame(minHeight: 90)
                .padding(7)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 13))

            HStack {
                Button("From cursor") { text = LabText.clip(readContext()) }
                    .buttonStyle(.bordered)
                Button("Paste") {
                    if fullAccess { text = LabText.clip(UIPasteboard.general.string ?? "") }
                }
                .disabled(!fullAccess)
                .buttonStyle(.bordered)
                Spacer()
                Text("\(text.count) characters")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 9)], spacing: 9) {
                ForEach(actions, id: \.self) { item in
                    Button(item) { transform(item) }
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(item == selectedAction ? Color.indigo.opacity(0.16) :
                                    Color(uiColor: .tertiarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 10))
                        .buttonStyle(.plain)
                }
            }

            if !selectedAction.isEmpty {
                Text(selectedAction)
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Text(output)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(13)
                    .background(Color(uiColor: .tertiarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 13))
                LabActionButton(text: "Insert result", icon: "text.insert") {
                    insertText(output)
                }
            }
        }
    }

    private func transform(_ option: String) {
        selectedAction = option
        switch option {
        case "Remove niqqud": output = LabText.removeNiqqud(text)
        case "Clean spaces": output = LabText.compactWhitespace(text)
        case "Uppercase": output = text.uppercased()
        case "Lowercase": output = text.lowercased()
        case "Trim lines":
            output = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
        case "Strip HTML":
            output = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        case "Remove Markdown":
            output = text.replacingOccurrences(of: "[#*_~`]", with: "", options: .regularExpression)
        case "Word count":
            let count = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            output = "\(count) words / \(text.count) characters"
        case "Quote":
            output = text.components(separatedBy: .newlines).map { "> " + $0 }.joined(separator: "\n")
        case "Make bullets":
            output = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
                .map { "• " + $0 }.joined(separator: "\n")
        default: output = text
        }
    }
}

struct LabCalculatorPanel: View {
    let insertText: (String) -> Void

    @State private var expression = ""
    @State private var result = "0"

    private let keys = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "−"],
        ["C", "0", ".", "+"],
        ["(", ")", "%", "="]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabHint(text: "A real on-device calculator powered by JavaScriptCore. No network requests.", icon: "plus.forwardslash.minus")

            VStack(alignment: .trailing, spacing: 4) {
                Text(expression.isEmpty ? "0" : expression)
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(result)
                    .font(.system(size: 34, weight: .light, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 15))

            ForEach(keys, id: \.self) { row in
                HStack(spacing: 9) {
                    ForEach(row, id: \.self) { key in
                        Button { press(key) } label: {
                            Text(key)
                                .font(.system(size: 21, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(key == "=" ? Color.indigo : Color(uiColor: .tertiarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 13))
                                .foregroundStyle(key == "=" ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            LabActionButton(text: "Insert answer", icon: "text.insert") { insertText(result) }
        }
    }

    private func press(_ key: String) {
        switch key {
        case "C": expression = ""; result = "0"
        case "=":
            let normalized = expression
                .replacingOccurrences(of: "×", with: "*")
                .replacingOccurrences(of: "÷", with: "/")
                .replacingOccurrences(of: "−", with: "-")
                .replacingOccurrences(of: "%", with: "/100")
            guard normalized.rangeOfCharacter(
                from: CharacterSet(charactersIn: "0123456789.+-*/() ").inverted
            ) == nil, normalized.count <= 80, !normalized.isEmpty else {
                result = "Invalid expression"
                return
            }
            let ctx = JSContext()
            ctx?.exceptionHandler = { _, _ in }
            if let value = ctx?.evaluateScript("(" + normalized + ")"),
               let number = value.toNumber() as? NSNumber,
               number.doubleValue.isFinite {
                result = String(format: "%.9g", number.doubleValue)
            } else {
                result = "Invalid expression"
            }
        default:
            expression += key
        }
    }
}

struct LabConversionPanel: View {
    let insertText: (String) -> Void

    private let options: [(String, String, String, Double, Double)] = [
        ("Centimeters → Inches", "cm", "in", 0.3937007874, 0),
        ("Inches → Centimeters", "in", "cm", 2.54, 0),
        ("Kilometers → Miles", "km", "mi", 0.6213711922, 0),
        ("Miles → Kilometers", "mi", "km", 1.609344, 0),
        ("Kilograms → Pounds", "kg", "lb", 2.2046226218, 0),
        ("Pounds → Kilograms", "lb", "kg", 0.45359237, 0),
        ("Celsius → Fahrenheit", "°C", "°F", 1.8, 32),
        ("Fahrenheit → Celsius", "°F", "°C", 0.5555555556, -17.7777777778),
        ("Minutes → Hours", "min", "hr", 0.0166666667, 0),
        ("Hours → Minutes", "hr", "min", 60, 0)
    ]
    @State private var selected = 0
    @State private var amount = "1"

    private var answer: String {
        guard let value = Double(amount) else { return "—" }
        let choice = options[selected]
        return String(format: "%.6g", value * choice.3 + choice.4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            LabHint(text: "Unit conversions calculated locally with transparent formulas.", icon: "arrow.left.arrow.right")
            Picker("Conversion", selection: $selected) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index].0).tag(index)
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12))

            HStack {
                TextField("Value", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                Text(options[selected].1).foregroundStyle(.secondary)
            }
            .padding(13)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 7) {
                Text("RESULT").font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(answer) \(options[selected].2)")
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .minimumScaleFactor(0.5)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 13))

            LabActionButton(text: "Insert result", icon: "text.insert") {
                insertText(answer)
            }
        }
    }
}

struct LabEmojiPanel: View {
    let insertText: (String) -> Void

    private let groups: [(String, String)] = [
        ("Faces", "😀😃😄😁😆😅😂🤣😊😇🙂🙃😉😍🥰😘😎🤩🥳🤔🫡😐😶🙄😴😭😢😱😤🤯"),
        ("People", "👋🤝👏🙌👍👎👌✌️🤞🫶💪🙏👀👤👨👩👧👦👶👵👴"),
        ("Nature", "🌸🌻🌷🌹🌳🌲🍀🍃🌿🐕🐈🐇🦋🐝🐢🌍☀️🌙⭐️🌈"),
        ("Objects", "📚📖📕✏️📝💻📱⌨️📷🎨🎬🎵🔑📅🕯️💡🔎🎁"),
        ("Symbols", "❤️💙💚💜🩷🤍🖤💛✨✅❌⚠️❗️❓🔔📌➡️⬅️⬆️⬇️")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabHint(text: "Tap an emoji to insert it directly into the current app.", icon: "face.smiling")
            ForEach(groups, id: \.0) { group in
                Text(group.0).font(.subheadline.weight(.semibold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 43), spacing: 8)], spacing: 9) {
                    ForEach(group.1.map(String.init), id: \.self) { character in
                        Button { insertText(character) } label: {
                            Text(character).font(.system(size: 27))
                                .frame(maxWidth: .infinity)
                                .frame(height: 41)
                                .background(Color(uiColor: .tertiarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
