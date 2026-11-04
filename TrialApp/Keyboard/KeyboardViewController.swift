import OpenKeyboardKit
import SwiftUI
import UIKit

final class KeyboardViewController: KeyboardInputViewController {
    private var heightConstraint: NSLayoutConstraint?
    private var expanded = true
    private var lastRequestedHeight: CGFloat = 0
    private let expansionKey = "keyboard.lab.expanded"
    private let labInput = LabInputRouter()

    override func viewDidLoad() {
        super.viewDidLoad()

        // The system decides which text fields can load third-party keyboards.
        // We use a normal keyboard extension so the same extension is available
        // through the globe key in other apps.
        expanded = UserDefaults.standard.object(forKey: expansionKey) as? Bool ?? true
        setup(for: .trialKeyboard) { _ in }

        // Keep the existing KeyboardKit behavior outside tool mode.
        let handler = LabRoutedActionHandler(controller: self)
        handler.labInput = labInput
        services.actionHandler = handler

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
        // IMPORTANT: A keyboard extension can live in a window whose height
        // equals the keyboard height we requested. Using window.bounds.height
        // here feeds the constraint back into itself and collapses expansion.
        // Scene coordinate space is independent of our keyboard constraint.
        if let sceneHeight = view.window?.windowScene?.coordinateSpace.bounds.height,
           sceneHeight > 300 {
            return sceneHeight
        }
        // Screen height is a stable fallback; iPadOS will clamp the extension
        // if Split View or another host cannot accommodate our requested size.
        return max(UIScreen.main.bounds.height, 400)
    }

    private func requestedHeight() -> CGFloat {
        let availableHeight = availableWindowHeight()
        if UIDevice.current.userInterfaceIdiom == .pad {
            if labInput.isEditingTools {
                return min(800, max(570, availableHeight * 0.76))
            }
            return expanded
                ? min(620, max(340, availableHeight * 0.57))
                : min(375, max(270, availableHeight * 0.34))
        }
        if labInput.isEditingTools {
            return min(590, max(385, availableHeight * 0.68))
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

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        if labInput.isEditingTools && !labInput.isHostTarget {
            labInput.activateHost()
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if labInput.isEditingTools && !labInput.isHostTarget {
            labInput.activateHost()
        }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] controller in
            TrialKeyboardView(
                services: controller.services,
                state: controller.state,
                insertText: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                deleteHost: { [weak self] in
                    self?.textDocumentProxy.deleteBackward()
                },
                readContext: { [weak self] in
                    self?.textDocumentProxy.documentContextBeforeInput ?? ""
                },
                fullAccess: self?.hasFullAccess ?? false,
                inputRouter: self?.labInput ?? LabInputRouter(),
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
