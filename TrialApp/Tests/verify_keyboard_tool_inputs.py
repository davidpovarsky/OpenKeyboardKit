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
    "host input is intercepted when tools active": "isEditingTools" in router and
        "if labInput?.intercept(gesture, action: action) == true" in router,
    "backspace, space, and return routed": all(x in router for x in
        ["case .backspace:", "case .space:", "case .primary:", "func returnKey()"]),
    "caret and Unicode character boundaries supported": all(x in router for x in
        ["func moveCaret(", "source.index(source.startIndex", "source.index(before: to)"]),
    "real KeyboardKit handler installed": "services.actionHandler = handler" in controller,
    "Hebrew and English modes switchable": "LabToolHebrewKeyboard" in shell and
        "useHebrewInTools" in shell,
    "native themed tool launcher": all(x in read("LabToolHome.swift") for x in
        ["LabAnimatedTile", "LabEditableField", ".introspect("]),
    "glass UI and Pow effects": all(x in read("LabDesign.swift") for x in
        [".glassEffect(", ".changeEffect(.shine"]),
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
