import OpenKeyboardKit
import SwiftUI

final class KeyboardViewController: KeyboardInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup(for: .trialKeyboard) { _ in }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { controller in
            TrialKeyboardView(
                services: controller.services,
                state: controller.state,
                insertText: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                }
            )
        }
    }
}
