# Keyboard Lab v0.7.0 — Native UIKit Toolbars and Focus Routing

This experimental iOS/iPadOS application includes a **real system keyboard extension** based on the MIT-licensed [OpenKeyboardKit](https://github.com/valomedia/OpenKeyboardKit). The host app and extension are implemented in Swift and SwiftUI; JavaScriptCore powers user scripts. No web-based UI is embedded.

## Install

1. Download the **unsigned IPA** from this repository's GitHub Release.
2. Re-sign using SideStore/AltStore (or sign via a development profile). **Keep and sign TrialKeyboardExtension.appex**.
3. Settings > General > Keyboard > Keyboards > Add New Keyboard > Keyboard Lab.
4. In Notes, long-press the globe icon and select Keyboard Lab. The host app includes an embedded-extension check; it does not prove that iPadOS registered it successfully.
5. For permitted network and clipboard features, allow Full Access in iPadOS Settings. Independently enable Network On inside Script Studio.

## Interface

The keyboard extension switches between three native modes:
- **Typing**: standard OpenKeyboardKit keys pinned to the bottom, responsive toolbar, optional quick-access shortcuts above the keys.
- **Tool launcher**: Liquid Glass tool navigation, SF Symbols, Pow animations and SwiftUI Introspect scroll behavior, with responsive pastel cards and a routed search field.
- **Tool detail**: a native SwiftUI workspace displayed **above the persistent input keyboard**, not a separate app. Tool fields route typing into their own bindings instead of the host document.

Expanded and compact keyboard heights are requested through Auto Layout; actual size is controlled by iPadOS. The extra space in typing mode is above the keys, never beneath them. Tool mode requests additional height where supported and always reserves the bottom area for keys. Tool inputs have caret navigation and backspace/space/return handling. Optional native Hebrew keys switch with the English OpenKeyboardKit layout in tool mode.

## System-native interaction polish (v0.6.1)

- Built with **Xcode 27** and a minimum **iOS 17 deployment target**. Genuine SwiftUI Liquid Glass renders on iPadOS 26+, including iPadOS 27.
- Native `contextMenu(menuItems:preview:)` shows long-press tool previews with Open/Toggle Favorite actions. Short tapping still opens immediately.
- Script library long press shows a readable source excerpt and Run/Edit/Delete actions.
- Search results long press shows an expanded preview with Insert/Copy; saved clips, notes and snippets provide a local text preview and context-specific actions.
- Tool cards use iPad pointer hover lift and SwiftUI sensory-feedback triggers where the device supports haptics.
- Context previews are **system overlays** managed by iPadOS. The keyboard extension cannot control whether the overlay can transcend its allotted input view, so test in Notes on the actual iPad.
- Previews are built entirely in SwiftUI and do not transmit text or execute a script merely by previewing.

## System controls and input focus (v0.7.0)

- The top chrome, keyboard control row, and Script Studio navigation are real UIKit UIToolbar with UIBarButtonItem actions, presented with the operating system's appearance.
- Tool, Wikipedia, Sefaria, Dictionary, and GIF search fields use UISearchBar. searchBarShouldBeginEditing deliberately declines becoming first responder; tapping them selects an extension-owned input binding for the already-visible keyboard.
- **Host by default** while browsing tools: if no extension field is active, KeyboardKit sends keys to the host UITextDocumentProxy exactly as it does in typing mode. Tapping any internal field switches key delivery to the extension field. To App switches explicitly back to the host without closing tools.
- UIInputViewController selection/text change callbacks provide best-effort automatic restoration of host focus when the user moves the caret in the host app.
- Hebrew tool keys likewise deliver to host via the text proxy when no internal field is selected.
- **iPadOS limitation**: iOS does not provide a universal, reliable API for observing the precise first responder of a separate host app from a third-party keyboard extension. For hosts that do not issue selection change callbacks, To App provides a predictable fallback.
- The extension does not request a second keyboard and does not control the actual host's focus. Use native keyboard input field tests in Notes, ChatGPT, and other host apps to confirm expected routing.

## Working tools

| Tool | Local/network | Notes |
| --- | --- | --- |
| Sefaria search | Network | POST /api/search-wrapper; Hebrew lemmatizer |
| Wikipedia | Network | MediaWiki OpenSearch, chooses Hebrew/English |
| Dictionary | Network | Free English Dictionary API; native Hebrew/English search keypad |
| GIF Gallery | Network | Wikimedia Commons GIFs, copies original GIF data when requested |
| Translator | Network | Experimental public MyMemory API, explicit consent |
| Text FX | Local | Hebrew niqqud, whitespace, HTML, Markdown, case and more |
| Calculator | Local | JavaScriptCore arithmetic, no network |
| Conversion | Local | Length, mass, temperature, and time |
| Emoji | Local | Curated native emoji picker |
| Clipboard | Local | Manual save; no background monitoring |
| Notepad | Local | Saved in extension UserDefaults |
| Snippets | Local | Custom and built-in snippets |
| Handwriting | Local | Native PencilKit drawing; copy rendered image |
| Photos & files | System | Native PhotosPicker and fileImporter |
| Themes | Local | Pastel accent palette for tools |
| Profiles | Local | Choose quick-access shortcuts |
| Layouts | Local | Expansion preference and keyboard instructions |
| Script Studio | Local + optional network | JSCore editor, saved plugins, HTTPS GET/POST bridge, native data-driven forms |

## Script Studio API

Scripts run inside the keyboard extension. They are stored in its local UserDefaults; the host app does not automatically share that store.

```js
native.ui({
  title: "Hello",
  message: "SwiftUI renders this from JS data",
  fields: [{id: "name", title: "Name", placeholder: "Name"}],
  buttons: [{id: "send", title: "Insert greeting", symbol: "heart"}]
});
native.onAction = (id, values) => {
  if (id === "send") native.insert("Hello, " + values.name);
};
native.context(); // May return up to 500 characters before cursor
native.log("Status");
native.insert("Text");
native.copy("Copied"); // Full Access required
native.fetch("https://example.org", (error, body) => {});
native.request({
  url: "https://www.sefaria.org/api/search-wrapper",
  method: "POST",
  body: JSON.stringify({query:"שלום", type:"text", field:"naive_lemmatizer", size:5})
}, (error, body) => {});
```

The script engine supports only HTTPS GET/POST, with explicit network opt-in. Request bodies are limited to 100 KB and responses to 2 MB. Scripts execute synchronously in a JSContext; untrusted code can hang the keyboard. This is experimental, not a hardened script marketplace.

## Platform boundaries and known issues

- Third-party keyboards are not available in secure password fields or in host apps which exclude them. Users must activate the keyboard in Settings.
- Re-signing through SideStore may require separately provisioning and retaining the embedded .appex. Registration in other host apps cannot be verified by a CI build.
- iPadOS may reserve a bottom system keyboard strip outside the extension's drawable region.
- The standard typing engine is English QWERTY. Hebrew text can be inserted by tools, but **Hebrew typing, predictions and Hebrew autocorrect are not yet implemented**.
- Speech recognition directly in a keyboard extension is not permitted because microphone access is restricted; dictation is not included.
- Remote generative AI is not configured as operational. GIF gallery is implemented using Wikimedia Commons with static previews; selected GIF data is copied to the clipboard on request.
- Images copied through the clipboard can only be pasted into host applications that accept them. File pickers cannot attach arbitrary documents to other apps.
- Tool fields use LabEditableField with a shared LabInputRouter, rather than a TextField/TextEditor that cannot summon a secondary iPadOS keyboard inside the extension. In tool mode, the existing keyboard remains visible and its characters edit extension-owned state. An optional Hebrew layout is available for tool inputs.
- External APIs (Sefaria, Wikipedia, DictionaryAPI, MyMemory) may change or become unavailable. Only explicit searches send queries.
- App Group synchronization with the host application has not yet been configured and may require new signing entitlements.
- A full native UI cannot bypass iPadOS sandboxing, privacy permissions, or extension resource limits.

## Build

The GitHub workflow builds using an Intel-hosted macOS runner and Xcode 16.4 (proven toolchain for this fork), generates Xcode targets via XcodeGen, runs Release compilation, validates the embedded keyboard extension's Info.plist and Full Access request, assembles an **unsigned** .ipa, and uploads it to Releases. An upgrade test for Xcode 27 is planned after confirming tooling availability and migration compatibility.


## v0.6 UI and input architecture

- `LabInputRouter` owns active field routing, Unicode-character-aware insertion/deletion, caret position and return behavior; it isolates the host `UITextDocumentProxy` from tool input.
- `LabRoutedActionHandler` is a standard KeyboardKit handler subclass. It intercepts character, space, delete and return in tool mode, but preserves normal host typing behavior elsewhere.
- `TrialKeyboardView` mounts the same keyboard below every tool and Script Studio. The workspace changes above it and can request a taller keyboard-extension window when the system permits.
- `LabEditableField` is a native SwiftUI input surface that is owned by the extension. Tapping it selects a binding for the persistent keyboard; it is not a second system `UITextField`.
- `LabToolHebrewKeyboard` supports Hebrew and symbols in tool mode, with English as the default underlying OpenKeyboardKit layout.
- Modern visuals use Apple SwiftUI Liquid Glass on iPadOS 26+, with a native material fallback, SF Symbols, the MIT-licensed Pow animation library (pinned to the upstream Swift 6 compatibility fix), and MIT SwiftUI Introspect for predictable scrolling.
- The release workflow runs `TrialApp/Tests/verify_keyboard_tool_inputs.py` to catch regressions where a tool switches back to non-functional internal `TextField` or `TextEditor` controls.

### On-device acceptance test

1. Open Keyboard Lab in Notes; in **Tools**, tap search and type **Wikipedia** or **ספריא** using the keyboard shown at the bottom.
2. Open **Sefaria**, tap its search field, type Hebrew (use the Hebrew switch) and tap Search. A result should insert into the original Notes text field when explicitly selected.
3. Open **Script Studio**, choose a form-based script, tap a field, type using the same keyboard, and submit it. No keystrokes should accidentally enter Notes until the script calls `native.insert`.
4. Check Text FX, translator input, notes, snippets, conversion, JS editor and GIF search. The input keyboard should remain visible in every tool.
5. Return to normal keyboard typing and confirm the keys enter text into Notes as before. Test both landscape and portrait.

Build success does **not** prove these interaction steps on the physical iPad. iPadOS controls extension availability and may clamp the requested height.
