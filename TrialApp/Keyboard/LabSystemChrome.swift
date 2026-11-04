import SwiftUI
import UIKit

/// Native SwiftUI button styles, with a bounded keyboard-safe size.
/// Deliberately not a UIToolbar: keyboard height and key rendering remain
/// entirely owned by the proven OpenKeyboardKit toolbar / key layout.
struct LabGlassCommand: View {
    let title: String
    let symbol: String
    var compact = false
    var prominent = false
    var action: () -> Void

    @ViewBuilder
    private var content: some View {
        if compact {
            Label(title, systemImage: symbol)
                .labelStyle(.iconOnly)
                .font(.system(size: 12, weight: .medium))
                .frame(minWidth: 25, minHeight: 31)
                .contentShape(Rectangle())
        } else {
            Label(title, systemImage: symbol)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 12, weight: .medium))
                .frame(minWidth: 42, minHeight: 31)
                .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            if prominent {
                Button(action: action) { content }
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
                    .accessibilityLabel(title)
            } else {
                Button(action: action) { content }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                    .accessibilityLabel(title)
            }
        } else {
            Button(action: action) { content }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(title)
        }
    }
}

/// A native iPadOS header with genuine SwiftUI Liquid Glass commands.
/// Never nests another keyboard toolbar or alters the key view's measured height.
struct LabGlassHeader: View {
    let title: String
    let subtitle: String
    let symbol: String
    let back: () -> Void
    let close: () -> Void
    var closeTitle = "Keyboard"
    var closeSymbol = "keyboard"
    var closeEnabled = true

    private var controls: some View {
        HStack(spacing: 10) {
            LabGlassCommand(title: "Back", symbol: "chevron.left",
                            compact: true, action: back)

            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.indigo)
                .frame(width: 34, height: 34)
                .background(.indigo.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if closeEnabled {
                LabGlassCommand(title: closeTitle, symbol: closeSymbol,
                                compact: true, action: close)
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 54)
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 11) {
                controls
            }
            .frame(height: 54)
        } else {
            controls
        }
    }
}

/// System UISearchBar is intentionally used as a *display*, not a first responder.
/// The keyboard extension already owns the visible keys. A transparent
/// SwiftUI button changes the LabInputRouter target without summoning iOS's
/// second keyboard. The search bar tracks the Binding as the user types.
private struct LabUIKitSearchDisplay: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeUIView(context: Context) -> UISearchBar {
        let bar = UISearchBar(frame: .zero)
        bar.searchBarStyle = .minimal
        bar.placeholder = placeholder
        bar.autocapitalizationType = .none
        bar.autocorrectionType = .no
        bar.searchTextField.clearButtonMode = .never
        bar.isUserInteractionEnabled = false
        bar.accessibilityElementsHidden = true
        return bar
    }

    func updateUIView(_ bar: UISearchBar, context: Context) {
        if bar.text != text {
            bar.text = text
        }
        if bar.placeholder != placeholder {
            bar.placeholder = placeholder
        }
    }
}

struct LabSystemSearchField: View {
    @EnvironmentObject private var router: LabInputRouter

    let id: String
    @Binding var text: String
    var placeholder = "Search"
    var onSubmit: (() -> Void)? = nil

    private var focused: Bool { router.activeKey == id }

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                LabUIKitSearchDisplay(text: $text, placeholder: placeholder)
                    .frame(height: 44)
                    .allowsHitTesting(false)

                Button {
                    router.focus(id, binding: $text, onReturn: onSubmit)
                } label: {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(placeholder)
                .accessibilityValue(text)
                .accessibilityHint("Tap to edit with the Keyboard Lab keys")
            }
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(focused ? Color.indigo.opacity(0.65) : .clear,
                                  lineWidth: 1.2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .allowsHitTesting(false)
            }

            if !text.isEmpty {
                LabGlassCommand(title: "Clear", symbol: "xmark.circle.fill",
                                compact: true) {
                    text = ""
                    router.focus(id, binding: $text, onReturn: onSubmit)
                }
                .padding(.trailing, 7)
            }
        }
        .frame(height: 46)
    }
}


/// Compact UIKit UIMenu / UIButton, embedded as ONE ordinary control in the
/// existing HStack. It is not a UIToolbar and does not own the keyboard height.
struct LabSystemMenuItem {
    let id: String
    let title: String
    let symbol: String
    let action: () -> Void
}

struct LabSystemMenuButton: UIViewRepresentable {
    let items: [LabSystemMenuItem]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "Quick actions"
        button.showsMenuAsPrimaryAction = true
        button.contentHorizontalAlignment = .center
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        let coordinator = context.coordinator
        coordinator.actions = Dictionary(
            uniqueKeysWithValues: items.map { ($0.id, $0.action) }
        )
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .glass()
        } else {
            config = .bordered()
        }
        config.image = UIImage(systemName: "ellipsis")
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 5, leading: 10, bottom: 5, trailing: 10
        )
        button.configuration = config
        let children = items.map { item in
            UIAction(
                title: item.title,
                image: UIImage(systemName: item.symbol)
            ) { [weak coordinator] _ in
                coordinator?.actions[item.id]?()
            }
        }
        button.menu = UIMenu(title: "Keyboard Lab", children: children)
    }

    final class Coordinator {
        var actions: [String: () -> Void] = [:]
    }
}
