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
    "focus-aware routing allows host typing during tool display":
        "guard isEditingTools, target != nil, activeKey != nil else { return false }" in router and
        "if labInput?.intercept(gesture, action: action) == true" in router,
    "external host selection returns focus to host": all(x in controller for x in
        ["override func selectionDidChange(", "override func textDidChange(",
         "labInput.activateHost()"]),
    "direct host target switch without closing tools":
        "router.activateHost()" in read("LabDesign.swift") and
        "inputRouter.activateHost()" in read("TrialKeyboardView.swift"),
    "native UIKit system toolbar and search controls": all(x in read("LabNativeChrome.swift") for x in
        ["UIToolbar", "UIBarButtonItem(", "UISearchBar", "searchBarShouldBeginEditing", "return false"]),
    "UIKit toolbar on tool and script navigation": all("LabNativeToolbar" in read(n) for n in
        ["TrialKeyboardView.swift", "LabToolHome.swift", "LabToolPage.swift", "ScriptStudioView.swift",
         "LabToolHebrewKeyboard.swift"]),
    "backspace, space, and return routed": all(x in router for x in
        ["case .backspace:", "case .space:", "case .primary:", "func returnKey()"]),
    "caret and Unicode character boundaries supported": all(x in router for x in
        ["func moveCaret(", "source.index(source.startIndex", "source.index(before: to)"]),
    "real KeyboardKit handler installed": "services.actionHandler = handler" in controller,
    "Hebrew keys can write to host or tool": all(x in read("LabToolHebrewKeyboard.swift") for x in
        ["router.isHostTarget", "insertHost(value)", "deleteHost()", "returnHost()"]),
    "native themed tool launcher": all(x in read("LabToolHome.swift") for x in
        ["LabAnimatedTile", "LabNativeToolbar", "LabNativeSearchBar", ".introspect("]),
    "glass UI and Pow effects": all(x in read("LabDesign.swift") for x in
        [".glassEffect(", ".changeEffect(.shine", ".sensoryFeedback(.selection", ".hoverEffect(.lift)"]),
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
