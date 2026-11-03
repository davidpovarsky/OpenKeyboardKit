import OpenKeyboardKit

extension KeyboardApp {
    static var trialKeyboard: KeyboardApp {
        .init(
            name: "Keyboard Lab",
            locales: .keyboardKitSupported
        )
    }
}
