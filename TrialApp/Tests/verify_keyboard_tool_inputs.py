#!/usr/bin/env python3
"""Static regression guard for the keyboard-extension tool-input architecture."""
from pathlib import Path

root = Path(__file__).resolve().parents[2]
keyboard = root / "TrialApp" / "Keyboard"
read = lambda n: (keyboard / n).read_text(encoding="utf-8")

shell = read("TrialKeyboardView.swift")
router = read("LabInputRouter.swift")
controller = read("KeyboardViewController.swift")

checks = {
    "keyboard always appears beneath tool mode": "standardKeyboard" in shell and
        "LabInputAccessory()" in shell and "inputRouter.setToolMode" in shell,
    "host typing works while tools are visible":
        "guard isEditingTools, target != nil, activeKey != nil else { return false }" in router and
        "if labInput?.intercept(gesture, action: action) == true" in router,
    "host selection change restores input target": all(x in controller for x in
        ["override func selectionDidChange(", "override func textDidChange(",
         "labInput.activateHost()"]),
    "manual To App is available without closing tools":
        "router.activateHost()" in read("LabDesign.swift"),
    "backspace, space, and return routed": all(x in router for x in
        ["case .backspace:", "case .space:", "case .primary:", "func returnKey()"]),
    "caret and Unicode character boundaries supported": all(x in router for x in
        ["func moveCaret(", "source.index(source.startIndex", "source.index(before: to)"]),
    "real KeyboardKit handler installed": "services.actionHandler = handler" in controller,
    "stable keyboard toolbar restored": all(x in shell for x in
        ["Keyboard.Toolbar {", "HStack(spacing: 8)", "toolButton("]) and
        "LabNativeToolbar" not in shell and
        not (keyboard / "LabNativeChrome.swift").exists(),
    "Hebrew and English modes switchable": "LabToolHebrewKeyboard" in shell and
        "useHebrewInTools" in shell,
    "Hebrew supports host and tool input": all(x in read("LabToolHebrewKeyboard.swift") for x in
        ["router.isHostTarget", "insertHost(value)", "deleteHost()", "returnHost()"]),
    "native themed tool launcher": all(x in read("LabToolHome.swift") for x in
        ["LabAnimatedTile", "LabSystemSearchField", "LabGlassHeader", ".introspect("]),
    "glass UI and Pow effects": all(x in read("LabDesign.swift") for x in
        [".glassEffect(", ".changeEffect(.shine", ".sensoryFeedback(.selection", ".hoverEffect(.lift)"]),
    "glass buttons without nested UIToolbar": all(x in read("LabSystemChrome.swift") for x in
        ["Button(action: action)", ".buttonStyle(.glass)", ".buttonStyle(.glassProminent)",
         "GlassEffectContainer(spacing:", "LabGlassHeader"]) and
        "UIToolbar" not in read("TrialKeyboardView.swift"),
    "keyboard toolbar remains KeyboardKit owned":
        "Keyboard.Toolbar {" in shell and
        "HStack(spacing: 8)" in shell and "LabGlassCommand(" in shell,
    "native UIKit glass menu without UIKit toolbar": all(x in read("LabSystemChrome.swift") for x in
        ["UIButton.Configuration", ".glass()", "UIMenu(title:", "UIAction("]) and
        "LabSystemMenuButton(items: quickMenuItems)" in shell,
    "system search field never takes first responder":
        all(x in read("LabSystemChrome.swift") for x in
            ["UISearchBar(frame:", "bar.isUserInteractionEnabled = false",
             "router.focus(id, binding: $text", ".allowsHitTesting(false)"]),
    "system search integrated in all searches":
        "LabSystemSearchField" in read("LabToolHome.swift") and
        "LabSystemSearchField" in read("LabToolPage.swift") and
        "LabSystemSearchField" in read("LabGIFPanel.swift"),
    "native quick form with functional output": all(x in read("LabQuickFormPanel.swift") for x in
        ["Picker(", "DatePicker(", "Toggle(", "Stepper(", "Slider(",
         "ProgressView(", ".confirmationDialog(", "insertText(brief)"]),
    "new tool enum and preview switch compile syntax": all(
        "\n        case .quickForm:" in read(name)
        and "\\n        case .quickForm:" not in read(name)
        for name in ["LabTool.swift", "LabNativePreviews.swift"]
    ),
    "native GIF previews": all(x in read("LabGIFPanel.swift") for x in
        [".contextMenu {", "preview: {", "Copy GIF", "Copy Source Link"]),
    "system context menu previews": all(x in read("LabNativePreviews.swift") for x in
        ["struct LabToolPreview", "struct LabScriptPreview", "struct LabResultPreview", "struct LabSavedTextPreview"]),
    "native long press menu wiring": all(".contextMenu {" in read(n) and "preview: {" in read(n) for n in
        ["LabToolHome.swift", "ScriptStudioView.swift", "LabToolPage.swift", "LabStoragePanels.swift"]),
}

text_panels = [
    "LabToolHome.swift", "LabToolPage.swift", "LabActionPanels.swift",
    "LabStoragePanels.swift", "LabMediaPanels.swift",
    "LabGIFPanel.swift", "ScriptStudioView.swift",
]
for name in text_panels:
    content = read(name)
    checks[name + " has no broken secondary iOS text controls"] = (
        "TextField(" not in content and "TextEditor(" not in content
        and "LabInlineKeyboard(" not in content
    )

for label, ok in checks.items():
    print(("PASS" if ok else "FAIL"), label)
if not all(checks.values()):
    raise SystemExit(1)
print(f"All {len(checks)} keyboard input and styling guards passed.")
