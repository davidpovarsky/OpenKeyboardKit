import SwiftUI
import Pow

enum LabDesign {
    static let canvas = Color(uiColor: .secondarySystemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemBackground)
    static let mint = Color(red: 0.13, green: 0.66, blue: 0.49)
    static let stroke = Color.primary.opacity(0.07)
    static func accent(_ selected: String) -> Color {
        LabTheme(rawValue: selected)?.accent ?? mint
    }
}

private struct LabGlassSurface: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
        } else {
            content.background(.regularMaterial,
                               in: RoundedRectangle(cornerRadius: radius))
        }
    }
}

extension View {
    func labGlass(_ radius: CGFloat = 16) -> some View {
        modifier(LabGlassSurface(radius: radius))
    }
}

struct LabSectionHeading: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(LabDesign.mint)
                .frame(width: 37, height: 37)
                .background(.indigo.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}

/// This is an extension-owned editable surface, NOT an iOS first-responder UITextField.
/// The keyboard at the bottom uses LabInputRouter to edit its Binding.
struct LabEditableField: View {
    @EnvironmentObject private var router: LabInputRouter

    let id: String
    let placeholder: String
    @Binding var text: String
    var multiline = false
    var minHeight: CGFloat = 42
    var submit: (() -> Void)? = nil

    private var active: Bool { router.activeKey == id }

    var body: some View {
        Button {
            router.focus(id, binding: $text, multiline: multiline, onReturn: submit)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                if multiline {
                    Text(placeholder)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 5) {
                    if text.isEmpty {
                        Text(multiline ? "Tap to type…" : placeholder)
                            .foregroundStyle(.secondary)
                            .lineLimit(multiline ? 2 : 1)
                    } else {
                        let offset = active ? min(router.caret, text.count) : text.count
                        let before = String(text.prefix(offset))
                        let after = String(text.dropFirst(offset))
                        (Text(before) +
                         Text(active ? "│" : "").foregroundColor(.indigo) +
                         Text(after))
                            .foregroundStyle(.primary)
                            .lineLimit(multiline ? 5 : 1)
                    }
                    Spacer(minLength: 0)
                    if active && !multiline {
                        Image(systemName: "character.cursor.ibeam")
                            .foregroundStyle(LabDesign.mint)
                            .font(.caption2)
                    }
                }
                .font(.system(size: multiline ? 13 : 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .padding(.horizontal, 13)
            .padding(.vertical, multiline ? 10 : 0)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(LabDesign.card))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(active ? LabDesign.mint.opacity(0.85) :
                              Color.primary.opacity(0.06), lineWidth: active ? 1.5 : 0.7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(placeholder)
        .accessibilityValue(text)
        .onDisappear { if active { router.unfocus() } }
    }
}

struct LabInputAccessory: View {
    @EnvironmentObject private var router: LabInputRouter

    var body: some View {
        HStack(spacing: 8) {
            Label(router.activeKey == nil ? "Tap a field to type" : "Editing tool field",
                  systemImage: router.activeKey == nil ? "hand.tap" : "character.cursor.ibeam")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            Button { router.moveCaret(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 28, height: 28)
            }
            Button { router.moveCaret(1) } label: {
                Image(systemName: "chevron.right").frame(width: 28, height: 28)
            }
            Button { router.unfocus() } label: {
                Image(systemName: "checkmark.circle").frame(width: 30, height: 28)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 15)
        .frame(height: 36)
        .background(.regularMaterial)
    }
}

struct LabAnimatedTile: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    @State private var selectionCount = 0

    var body: some View {
        Button {
            selectionCount += 1
            action()
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .top) {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(tint)
                        .frame(width: 41, height: 41)
                        .background(tint.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 13))
                    Spacer(minLength: 3)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
            .padding(14)
            .background(LabDesign.card, in: RoundedRectangle(cornerRadius: 19))
            .overlay {
                RoundedRectangle(cornerRadius: 19)
                    .strokeBorder(LabDesign.stroke, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 19))
            .changeEffect(.shine, value: selectionCount)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .sensoryFeedback(.selection, trigger: selectionCount)
    }
}
