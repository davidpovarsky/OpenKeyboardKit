import SwiftUI
import UIKit

/// Actual UIKit UIBarButtonItems. UIKit owns the toolbar's interaction,
/// focus effects and (iPadOS 26+) Liquid Glass presentation.
struct LabToolbarCommand {
    let id: String
    let title: String
    let symbol: String
    var style: UIBarButtonItem.Style = .plain
    let action: () -> Void
}

struct LabNativeToolbar: UIViewRepresentable {
    var title: String?
    var leading: [LabToolbarCommand] = []
    var trailing: [LabToolbarCommand] = []

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIToolbar {
        let bar = UIToolbar(frame: .zero)
        bar.isTranslucent = true
        // Do not customize its background: iPadOS owns glass grouping.
        bar.tintColor = .label
        return bar
    }

    func updateUIView(_ bar: UIToolbar, context: Context) {
        var items = [UIBarButtonItem]()
        func button(_ command: LabToolbarCommand) -> UIBarButtonItem {
            let action = UIAction { [weak coordinator = context.coordinator] _ in
                coordinator?.actions[command.id]?()
            }
            let button = UIBarButtonItem(
                title: command.title,
                image: UIImage(systemName: command.symbol),
                primaryAction: action,
                menu: nil
            )
            button.style = command.style
            button.accessibilityLabel = command.title
            return button
        }
        context.coordinator.actions = Dictionary(
            uniqueKeysWithValues: (leading + trailing).map { ($0.id, $0.action) }
        )
        items += leading.map(button)
        items.append(UIBarButtonItem(systemItem: .flexibleSpace))
        if let title, !title.isEmpty {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 15, weight: .semibold)
            label.textColor = .label
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.lineBreakMode = .byTruncatingTail
            items.append(UIBarButtonItem(customView: label))
            items.append(UIBarButtonItem(systemItem: .flexibleSpace))
        }
        items += trailing.map(button)
        bar.setItems(items, animated: false)
    }

    final class Coordinator {
        var actions: [String: () -> Void] = [:]
    }
}

/// A system UISearchBar, adapted for the extension's own existing keyboard.
/// The search field deliberately refuses first responder to avoid asking iOS
/// to display a second keyboard inside our custom keyboard extension.
struct LabNativeSearchBar: UIViewRepresentable {
    @EnvironmentObject private var input: LabInputRouter
    let id: String
    @Binding var text: String
    var placeholder = "Search"
    var onSubmit: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UISearchBar {
        let bar = UISearchBar(frame: .zero)
        bar.delegate = context.coordinator
        bar.searchBarStyle = .minimal
        bar.autocapitalizationType = .none
        bar.placeholder = placeholder
        bar.searchTextField.clearButtonMode = .always
        bar.accessibilityLabel = placeholder

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tap.cancelsTouchesInView = false
        bar.addGestureRecognizer(tap)
        return bar
    }

    func updateUIView(_ bar: UISearchBar, context: Context) {
        context.coordinator.parent = self
        if bar.text != text { bar.text = text }
        if bar.placeholder != placeholder { bar.placeholder = placeholder }
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        var parent: LabNativeSearchBar

        init(parent: LabNativeSearchBar) { self.parent = parent }

        @objc func handleTap() { focus() }

        private func focus() {
            parent.input.focus(
                parent.id, binding: parent.$text,
                onReturn: parent.onSubmit
            )
        }

        func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
            focus()
            return false
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
            focus()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            parent.onSubmit?()
        }
    }
}
