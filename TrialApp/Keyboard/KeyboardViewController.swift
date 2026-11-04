import OpenKeyboardKit
import SwiftUI
import UIKit

final class KeyboardViewController: KeyboardInputViewController {
    private var heightConstraint: NSLayoutConstraint?
    private var expanded = false
    private var resultsVisible = false
    // Presentation height is independent of the active internal input field.
    private var workspaceVisible = false
    private var lastRequestedHeight: CGFloat = 0
    private var measuredContentHeight: CGFloat?
    private let expansionKey = "keyboard.lab.v011.largeKeys"
    private let labInput = LabInputRouter()
    private let completions = LabLocalCompletions()

    private func refreshSuggestions() {
        guard labInput.isHostTarget else {
            completions.reset()
            return
        }
        let isHebrew = UserDefaults.standard.bool(forKey: "keyboard.lab.hebrew.enabled")
        completions.refresh(
            contextBefore: textDocumentProxy.documentContextBeforeInput ?? "",
            hebrew: isHebrew
        )
    }

    private func applyCompletion(_ value: String) {
        // Never delete host text based on stale suggestions or tool focus.
        let fragment = completions.prefix
        guard labInput.isHostTarget, fragment.count >= 2,
              value.lowercased().hasPrefix(fragment.lowercased()),
              (textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(fragment),
              (textDocumentProxy.selectedText ?? "").isEmpty else { return }
        for _ in fragment {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(value)
        refreshSuggestions()
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // The system decides which text fields can load third-party keyboards.
        // We use a normal keyboard extension so the same extension is available
        // through the globe key in other apps.
        expanded = UserDefaults.standard.object(forKey: expansionKey) as? Bool ?? false
        setup(for: .trialKeyboard) { _ in }

        // Keep the existing KeyboardKit behavior outside tool mode.
        let handler = LabRoutedActionHandler(controller: self)
        handler.labInput = labInput
        // UIKit's textDidChange is not called after every key release in all
        // host apps. Refresh the local suggestion strip after actual actions.
        handler.hostTextDidEdit = { [weak self] in
            self?.refreshSuggestions()
        }
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
        refreshSuggestions()
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
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        // A workspace is deliberately large: it contains cards, forms or
        // script results instead of a full-sized keyboard.
        if workspaceVisible {
            let portion: CGFloat = isPad ? 0.76 : 0.69
            return min(isPad ? 810 : 590, availableHeight * portion)
        }

        // Prefer SwiftUI's measurement of the *actual* KeyboardKit keys,
        // the adaptive toolbar, and (if present) inline suggestions/results.
        // Never use a fixed percentage here: that caused a huge empty band
        // above the keys in landscape and when another app hosted the view.
        if let measured = measuredContentHeight, measured.isFinite, measured >= 140 {
            return min(availableHeight * 0.9, ceil(measured) + 6)
        }

        // Stable initial estimate until the first intrinsic measurement.
        // The next SwiftUI layout pass replaces this guess with measured size.
        let layout = LabSizedKeyboardLayout.make(
            for: state.keyboardContext,
            hebrew: UserDefaults.standard.bool(forKey: "keyboard.lab.hebrew.enabled"),
            largeKeys: expanded
        )
        let toolbarHeight: CGFloat = 48
        return min(availableHeight * 0.9, CGFloat(layout.totalHeight) + toolbarHeight + 12)
    }

    private func contentHeightDidMeasure(_ height: CGFloat) {
        let upper = availableWindowHeight() * 0.9
        guard height.isFinite, height >= 140, height < upper else { return }
        let rounded = ceil(height)
        if let previous = measuredContentHeight, abs(previous - rounded) <= 1 {
            return
        }
        measuredContentHeight = rounded
        updateHeight()
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
        refreshSuggestions()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if labInput.isEditingTools && !labInput.isHostTarget {
            labInput.activateHost()
        }
        refreshSuggestions()
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] controller in
            TrialKeyboardView(
                services: controller.services,
                state: controller.state,
                insertText: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshSuggestions()
                    }
                },
                deleteHost: { [weak self] in
                    self?.textDocumentProxy.deleteBackward()
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshSuggestions()
                    }
                },
                readContext: { [weak self] in
                    self?.textDocumentProxy.documentContextBeforeInput ?? ""
                },
                fullAccess: self?.hasFullAccess ?? false,
                inputRouter: self?.labInput ?? LabInputRouter(),
                completions: self?.completions ?? LabLocalCompletions(),
                applyCompletion: { [weak self] value in
                    self?.applyCompletion(value)
                },
                refreshSuggestions: { [weak self] in
                    self?.refreshSuggestions()
                },
                setExpanded: { [weak self] newValue in
                    guard let self else { return }
                    self.expanded = newValue
                    UserDefaults.standard.set(newValue, forKey: self.expansionKey)
                    self.updateHeight()
                },
                setWorkspaceVisible: { [weak self] newValue in
                    guard let self else { return }
                    self.workspaceVisible = newValue
                    self.updateHeight()
                },
                setResultsVisible: { [weak self] newValue in
                    guard let self else { return }
                    self.resultsVisible = newValue
                    self.updateHeight()
                },
                measuredContentHeight: { [weak self] measured in
                    // Defers height-constraint updates until after SwiftUI
                    // preference propagation, avoiding layout mutation loops.
                    DispatchQueue.main.async { [weak self] in
                        self?.contentHeightDidMeasure(measured)
                    }
                }
            )
        }
    }
}
