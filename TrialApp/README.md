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
