# Keyboard Trial for iPad (unsigned IPA)

This is a minimal installable host app and keyboard extension built against the open-source OpenKeyboardKit library in this fork.

- Host app: `TrialApp/Host`
- Keyboard extension: `TrialApp/Keyboard`
- Xcode project generator: `TrialKeyboard.yml`
- GitHub Actions IPA builder: `.github/workflows/trial-keyboard-ipa.yml`
- Supports iOS/iPadOS 17+ and includes a basic English keyboard with three sample toolbar actions.
- No Full Access permission is requested.

This build intentionally **does not yet include** Hebrew keyboard layouts, AI tools, external network access, a scripting engine or polished iPad-specific layout changes. Its purpose is to assess the default open-source engine's visual quality, responsiveness and iPad behavior before further work.

The GitHub Actions workflow builds an **unsigned** IPA. Installers such as SideStore may re-sign the app and embedded extension with the user's Apple ID; installation depends on the installer's capabilities and Apple's provisioning restrictions.

Under `LICENSE`, OpenKeyboardKit is licensed MIT. Keep the original license notice.
