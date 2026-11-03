import OpenKeyboardKit
import SwiftUI
import UIKit

final class KeyboardViewController: KeyboardInputViewController {
    private var heightConstraint: NSLayoutConstraint?
    private var expanded = true
    private var lastRequestedHeight: CGFloat = 0
    private let expansionKey = "keyboard.lab.expanded"

    override func viewDidLoad() {
        super.viewDidLoad()

        // The system decides which text fields can load third-party keyboards.
        // We use a normal keyboard extension so the same extension is available
        // through the globe key in other apps.
        expanded = UserDefaults.standard.object(forKey: expansionKey) as? Bool ?? true
        setup(for: .trialKeyboard) { _ in }

        // One explicit height constraint, adjustable without rebuilding keys.
        let constraint = view.heightAnchor.constraint(equalToConstant: requestedHeight())
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
        heightConstraint = constraint
        lastRequestedHeight = constraint.constant
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeight()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Window dimensions also change in Split View and Stage Manager.
        // The threshold below prevents keyboard-layout feedback loops.
        updateHeight()
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        // The transition size may describe the extension, not host window.
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateHeight()
        })
    }

    private func availableWindowHeight() -> CGFloat {
        if let window = view.window {
            let height = window.bounds.height
            if height > 200 { return height }
            if let scene = window.windowScene {
                let sceneHeight = scene.coordinateSpace.bounds.height
                if sceneHeight > 200 { return sceneHeight }
            }
        }
        return max(UIScreen.main.bounds.height, 400)
    }

    private func requestedHeight() -> CGFloat {
        let availableHeight = availableWindowHeight()
        if UIDevice.current.userInterfaceIdiom == .pad {
            return expanded
                ? min(620, max(340, availableHeight * 0.57))
                : min(375, max(270, availableHeight * 0.34))
        }
        return expanded
            ? min(470, max(315, availableHeight * 0.52))
            : min(305, max(245, availableHeight * 0.33))
    }

    private func updateHeight() {
        let target = requestedHeight()
        guard abs(lastRequestedHeight - target) > 2 else { return }
        lastRequestedHeight = target
        heightConstraint?.constant = target
        // SwiftUI bottom-anchors the intrinsic-height keyboard separately.
        view.setNeedsLayout()
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
                    guard let self else { return }
                    self.expanded = newValue
                    UserDefaults.standard.set(newValue, forKey: self.expansionKey)
                    self.updateHeight()
                }
            )
        }
    }
}
