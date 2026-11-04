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
    "stable KeyboardKit toolbar owns the one adaptive command row":
        all(x in shell for x in
            ["Keyboard.Toolbar {", "toolbar", "standardKeyboard(toolbar: toolbar)"])
        and "LabNativeToolbar" not in shell
        and not (keyboard / "LabNativeChrome.swift").exists(),
    "Hebrew and English use one KeyboardKit key renderer":
        "LabHebrewLayout.make(for: keyboardContext)" in shell and
        "KeyboardView(" in shell and "useHebrew.toggle()" in shell and
        "LabToolHebrewKeyboard(" not in shell,
    "Hebrew has the mapped Apple-style rows and protected special keys":
        all(x in read("LabHebrewLayout.swift") for x in
            ['["/", "׳", "ק", "ר", "א"', '["ש", "ד", "ג", "כ"', '["ז", "ס", "ב", "ה"',
             "KeyboardLayout.standard(for: context)", ".character(glyphs[offset])"]),
    "tool launcher shares adaptive search rather than adding another":
        all(x in read("LabToolHome.swift") for x in
            ["LabAnimatedTile", "@Binding var search", ".introspect("])
        and "LabSystemSearchField" not in read("LabToolHome.swift"),
    "glass UI and Pow effects": all(x in read("LabDesign.swift") for x in
        [".glassEffect(", ".changeEffect(.shine", ".sensoryFeedback(.selection", ".hoverEffect(.lift)"]),
    "glass buttons without nested UIToolbar": all(x in read("LabSystemChrome.swift") for x in
        ["Button(action: action)", ".buttonStyle(.glass)", ".buttonStyle(.glassProminent)",
         "GlassEffectContainer(spacing:", "LabGlassHeader"]) and
        "UIToolbar" not in read("TrialKeyboardView.swift"),
    "single native toolbar with no extra keyboard action row":
        "Keyboard.Toolbar {" in shell and
        "keyboardView(AnyView(commandToolbar))" in read("LabSmartCommandBar.swift")
        and "private var commandToolbar" in read("LabSmartCommandBar.swift")
        and "toolButton(" not in shell,
    "system menu support retained without duplicating chooser":
        all(x in read("LabSystemChrome.swift") for x in
            ["UIButton.Configuration", ".glass()", "UIMenu(title:", "UIAction("]) and
        "LabSystemMenuButton(items: quickMenuItems)" not in shell and
        "Menu {" in read("LabSmartCommandBar.swift"),
    "system search field never takes first responder":
        all(x in read("LabSystemChrome.swift") for x in
            ["UISearchBar(frame:", "bar.isUserInteractionEnabled = false",
             "router.focus(id, binding: $text", ".allowsHitTesting(false)"]),
    "system search shared for tool browsing":
        "LabSystemSearchField" in read("LabSmartCommandBar.swift") and
        "id: \"launcher.search\"" in read("LabSmartCommandBar.swift") and
        "LabSystemSearchField" in read("LabToolPage.swift")
        and "LabSystemSearchField" in read("LabGIFPanel.swift"),
    "Script Studio has only one visible toolbar header":
        "if tool != .scripts {" in read("LabToolPage.swift")
        and "LabGlassHeader(" in read("ScriptStudioView.swift"),
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
    "adaptive command row persists inside standard key toolbar":
        all(x in shell for x in
            ["LabSmartCommandBar(", "standardKeyboard(toolbar: toolbar)",
             "Keyboard.Toolbar {", "setWorkspaceVisible("])
        and "keyboardView(AnyView(commandToolbar))" in read("LabSmartCommandBar.swift"),
    "native command chooser includes tools and scripts": all(x in read("LabSmartCommandBar.swift") for x in
        ["Menu {", "ForEach(LabTool.allCases)", "ForEach(availableScripts)",
         "ScriptLibrary.scripts + scriptRunner.customScripts", "recentIDs"]),
    "command field uses existing input router": all(x in read("LabSmartCommandBar.swift") for x in
        ['LabSystemSearchField(', 'id: inputID', 'router.focus(inputID, binding: $query',
         'router.activateHost()', 'onSubmit: run']),
    "command results remain inside keyboard": all(x in read("LabSmartCommandBar.swift") for x in
        ["private var resultPanel:", "resultRow(", "LabEditableField(",
         "scriptRunner.fireAction(", "insertText(insertion)"]),
    "command bar supports results-only workspace": all(x in read("TrialKeyboardView.swift") for x in
        ["setWorkspaceVisible: (Bool) -> Void", "showsKeys = true",
         "setResultsVisible: (Bool) -> Void", "if !visible {"]) and
        "setKeyboardVisible(!isKeyboardVisible)" in read("LabSmartCommandBar.swift"),
    "keyboard controller wires suggestions refresh when language changes":
        "refreshSuggestions: { [weak self] in" in controller
        and "refreshSuggestions: () -> Void" in shell
        and "refreshSuggestions()" in shell,
    "offline native word suggestions without network":
        all(x in read("LabLocalCompletions.swift") for x in
            ["UITextChecker()", "completions(forPartialWordRange:",
             "fallbackEnglish", "fallbackHebrew", "static func partialWord("])
        and "URLSession" not in read("LabLocalCompletions.swift"),
    "suggestions replace current word safely in host":
        all(x in controller for x in
            ["private func applyCompletion(", "labInput.isHostTarget",
             '(textDocumentProxy.selectedText ?? \"\").isEmpty",
             "textDocumentProxy.deleteBackward()",
             "textDocumentProxy.insertText(value)"]),
    "adaptive toolbar switches predictions and search":
        all(x in read("LabSmartCommandBar.swift") for x in
            ["private var showPredictions", "ForEach(completions.suggestions",
             "applyCompletion(suggestion)", "showsCommandInput = true"]),
    "compact keyboard defaults on and workspace hides keys":
        'private var expanded = false' in controller
        and 'private var expanded = false' in shell or '@AppStorage("keyboard.lab.v010.expanded") private var expanded = false' in shell
        and 'showsKeys = false' in shell
        and 'onChange(of: inputRouter.activeKey)' in shell,
    "height no longer jumps when typing into command field":
        "if workspaceVisible {" in controller and
        "if labInput.isEditingTools {" not in controller,
    "script editor exposes manifest settings natively":
        all(x in read("ScriptStudioView.swift") for x in [
            "Command Bar Manifest", "commandActionSymbol", "commandPlaceholder",
            "commandToolSymbol", "commandNeedsNetwork", "commandResultStyle",
            "manifest: manifest"
        ]),
    "command results honor inlineText style":
        "if selectedScript?.commandManifest.result == .inlineText" in read("LabSmartCommandBar.swift"),
    "manifest parser supports old scripts and custom actions":
        all(x in read("LabCommandManifest.swift") for x in
            ["struct LabCommandManifest: Codable", "static func defaults(",
             "static func parse(from source:", "func validated()", "decodeIfPresent"]),
    "JavaScriptCore receives explicit command input separately from host":
        all(x in read("ScriptRuntime.swift") for x in
            ["func input() -> String", "channel.commandInput", "return __keyboardNative.input();",
             "input: String = \"\""]) and
        "native.input() || native.context()" in read("ScriptLibrary.swift"),
    "permission errors override stale JavaScript status":
        "if !notice.isEmpty { return notice }" in read("LabSmartCommandBar.swift"),
    "network access is explicit and gated at run":
        "if manifest.permissions.contains(\"network\") && (!fullAccess || !allowNetwork)" in read("LabSmartCommandBar.swift")
        and "allowNetwork: allowNetwork && fullAccess" in read("LabSmartCommandBar.swift"),
    "no script is executed by selecting a menu item":
        "private func select(_ id:" in read("LabSmartCommandBar.swift")
        and "private func run()" in read("LabSmartCommandBar.swift")
        and "scriptRunner.run(" in read("LabSmartCommandBar.swift"),
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
