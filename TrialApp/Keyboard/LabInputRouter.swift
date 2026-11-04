import SwiftUI
import OpenKeyboardKit

/// Input inside the keyboard extension is independent of the host text proxy.
final class LabInputRouter: ObservableObject {
    @Published private(set) var activeKey: String?
    @Published private(set) var caret = 0
    @Published private(set) var isEditingTools = false

    private var target: Binding<String>?
    private var onReturn: (() -> Void)?
    private var multiline = false

    func setToolMode(_ enabled: Bool) {
        isEditingTools = enabled
        if !enabled { unfocus() }
    }

    func focus(_ key: String, binding: Binding<String>, multiline: Bool = false,
               onReturn: (() -> Void)? = nil) {
        if activeKey != key { caret = binding.wrappedValue.count }
        else { caret = min(caret, binding.wrappedValue.count) }
        target = binding
        self.multiline = multiline
        self.onReturn = onReturn
        activeKey = key
    }

    func unfocus() {
        target = nil
        activeKey = nil
        onReturn = nil
        multiline = false
        caret = 0
    }

    func insert(_ value: String) {
        guard isEditingTools, let target else { return }
        var source = target.wrappedValue
        let at = source.index(source.startIndex, offsetBy: min(caret, source.count))
        source.insert(contentsOf: value, at: at)
        target.wrappedValue = source
        caret = min(source.count, caret + value.count)
    }

    func deletePrevious() {
        guard isEditingTools, let target else { return }
        var source = target.wrappedValue
        guard caret > 0, !source.isEmpty else { return }
        let to = source.index(source.startIndex, offsetBy: min(caret, source.count))
        source.removeSubrange(source.index(before: to)..<to)
        target.wrappedValue = source
        caret -= 1
    }

    func moveCaret(_ delta: Int) {
        guard let target else { return }
        caret = max(0, min(target.wrappedValue.count, caret + delta))
    }

    func returnKey() {
        guard isEditingTools else { return }
        if let onReturn { onReturn() }
        else if multiline { insert("\n") }
    }

    /// Returns true when the host should not receive the key.
    func intercept(_ gesture: Keyboard.Gesture, action: KeyboardAction) -> Bool {
        guard isEditingTools else { return false }
        let trigger = gesture == .release || gesture == .repeatPress
        switch action {
        case .character(let char), .text(let char):
            if trigger { insert(char) }
            return true
        case .urlDomain:
            if trigger { insert(".com") }
            return true
        case .space:
            if gesture == .release { insert(" ") }
            return true
        case .backspace:
            if trigger { deletePrevious() }
            return true
        case .primary:
            if gesture == .release { returnKey() }
            return true
        case .moveCursorBackward:
            if trigger { moveCaret(-1) }
            return true
        case .moveCursorForward:
            if trigger { moveCaret(1) }
            return true
        case .tab:
            if trigger { insert("\t") }
            return true
        case .emoji:
            return true
        case .nextKeyboard, .nextLocale, .dismissKeyboard, .keyboardType, .shift, .capsLock:
            return false
        default:
            return true
        }
    }
}

/// A standard KeyboardKit action handler with a routing boundary.
final class LabRoutedActionHandler: KeyboardAction.StandardActionHandler {
    weak var labInput: LabInputRouter?

    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction) {
        if labInput?.intercept(gesture, action: action) == true { return }
        super.handle(gesture, on: action)
    }

    override func handle(_ action: KeyboardAction) {
        if labInput?.intercept(.release, action: action) == true { return }
        super.handle(action)
    }
}
