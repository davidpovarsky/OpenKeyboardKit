import OpenKeyboardKit
import SwiftUI
import UIKit

final class KeyboardViewController: KeyboardInputViewController {
    private var heightConstraint: NSLayoutConstraint?
    private var expanded = true
    private var previousHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(for: .trialKeyboard) { _ in }
        let constraint = view.heightAnchor.constraint(equalToConstant: desiredHeight())
        constraint.priority = .defaultHigh
        constraint.isActive = true
        heightConstraint = constraint
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeight()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateHeight(availableHeight: size.height)
        })
    }

    private func desiredHeight(availableHeight: CGFloat = 0) -> CGFloat {
        let screenHeight: CGFloat
        if availableHeight > 400 {
            screenHeight = availableHeight
        } else if let window = view.window {
            screenHeight = max(window.bounds.height, 400)
        } else {
            screenHeight = max(UIScreen.main.bounds.height, 400)
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            return expanded
                ? min(620, max(340, screenHeight * 0.57))
                : min(375, max(270, screenHeight * 0.34))
        } else {
            return expanded
                ? min(470, max(315, screenHeight * 0.52))
                : min(305, max(245, screenHeight * 0.33))
        }
    }

    private func updateHeight(availableHeight: CGFloat = 0) {
        let target = desiredHeight(availableHeight: availableHeight)
        guard abs(previousHeight - target) > 2 else { return }
        previousHeight = target
        heightConstraint?.constant = target
        UIView.performWithoutAnimation { view.layoutIfNeeded() }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] controller in
            TrialKeyboardView(
                services: controller.services,
                state: controller.state,
                insertText: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                readContext: { [weak self] in
                    self?.textDocumentProxy.documentContextBeforeInput ?? ""
                },
                fullAccess: self?.hasFullAccess ?? false,
                setExpanded: { [weak self] newValue in
                    self?.expanded = newValue
                    self?.updateHeight()
                }
            )
        }
    }
}
