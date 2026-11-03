# Keyboard Lab v0.2 — iPad keyboard experiment

A fork of OpenKeyboardKit with an installable iPad keyboard extension, dynamic height, Full Access request, native SwiftUI Script Studio, and JavaScriptCore scripts.

Features:
- System-wide keyboard after enabling it in iPadOS Settings. It cannot appear in restricted password fields, certain phone inputs, or apps that opt out.
- Full Access is REQUESTED in the extension plist; the user must enable it manually.
- Expand/collapse height button requests different heights, subject to iOS.
- Scripts toolbar button opens a fully native SwiftUI screen inside the keyboard.
- JSCore runs built-in scripts and user-imported scripts copied from the clipboard.
- HTTP networking is HTTPS GET only via URLSession, opt-in under Network On, requiring Full Access. Arbitrary HTTPS hostnames are supported.
- Script examples include Wikipedia search, Sefaria text lookup, JSON formatter, date insertion, and native SwiftUI widgets.
- Script bridge supports native.ui(data), native.log(message), native.insert(text), native.copy(text), native.context(), and native.fetch(url, callback).
- Imported scripts stored in keyboard extension UserDefaults, not shared with the main app.

Security notes:
Full Access does NOT bypass the sandbox, authorize access to passwords, other apps, arbitrary documents, photos, microphone or location. Separate system pickers/authorization are needed for applicable device features. The keyboard may see some local text context via the standard textDocumentProxy, and trusted scripts may send it to remote hosts if network access is enabled. Only import scripts you understand. Network responses are capped to 2MB to protect extension memory.

Build:
GitHub Actions macOS Intel runner invokes xcodegen and xcodebuild, validates the embedded TrialKeyboardExtension.appex, and creates a re-signable TrialKeyboard-unsigned.ipa. No signing certificate or Apple ID secret is included.


## v0.2.1: Bottom docking and system keyboard diagnostics

- SwiftUI layout: the original-size OpenKeyboardKit key rows and toolbar are pinned to the **bottom** of the keyboard extension with a flexible spacer above them. Expanded height must not stretch the keys or move them upward.
- Expansion state is persisted and the keyboard height request is based on scene coordinate-space height, not the extension's feedback-prone window height. Rotation, Stage Manager, and Split View still require on-device testing.
- The host app now checks whether the embedded `TrialKeyboardExtension.appex` is present **after installation** and explains how to activate the keyboard from iPadOS Settings.
- This check cannot determine whether iPadOS registered the extension successfully or whether SideStore signed the extension correctly. To test the third-party keyboard, manually enable it via Settings → General → Keyboard → Keyboards, then long-press the globe key in Notes. Re-add it after updating if missing.
- Apple blocks third-party keyboards in secure/password and phone-pad fields and may allow apps to opt out of keyboard extensions. This cannot be overridden.
- Keep the .appex included when re-signing the unsigned IPA using SideStore/AltStore.
