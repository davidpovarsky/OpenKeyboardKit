# Keyboard Lab v0.11.0 — Measured Keyboard Height and Visible Actions

This experimental iOS/iPadOS application includes a **real system keyboard extension** based on the MIT-licensed [OpenKeyboardKit](https://github.com/valomedia/OpenKeyboardKit). The host app and extension are implemented in Swift and SwiftUI; JavaScriptCore powers user scripts. No web-based UI is embedded.

## Install

1. Download the **unsigned IPA** from this repository's GitHub Release.
2. Re-sign using SideStore/AltStore (or sign via a development profile). **Keep and sign TrialKeyboardExtension.appex**.
3. Settings > General > Keyboard > Keyboards > Add New Keyboard > Keyboard Lab.
4. In Notes, long-press the globe icon and select Keyboard Lab. The host app includes an embedded-extension check; it does not prove that iPadOS registered it successfully.
5. For permitted network and clipboard features, allow Full Access in iPadOS Settings. Independently enable Network On inside Script Studio.

## Approved Keyboard Layout v0.11.0

This is a separate prerelease; the v0.9.0/v0.10.0 releases are untouched.

The always-visible KeyboardKit toolbar has six roles:
Tools (one tap), the selected manifest tool, native search/command input,
Run (manifest icon), Grow/Shrink (one tap), and native More. An ephemeral
word-suggestion strip appears above, never instead of, the command
field. The on-device UITextChecker and local dictionaries are refreshed
directly after each host character/space/backspace event as well as UIKit
selection/text callbacks; this improves reliability but is NOT Apple's
proprietary QuickType engine.

The extension height is calculated from actual SwiftUI intrinsic
KeyboardKit key/toolbar/result height using a PreferenceKey, rather than
an arbitrary proportion of scene height. The large mode changes each
KeyboardLayout.Item's true height, without adding empty padding or
Spacer. Only full workspace modes continue to request a larger canvas,
with their real tool content consuming it.

Browse all 20 tools in a spacious workspace replacing the keys.
Tap the search field and the keyboard returns below the filtering grid.
Script Studio and individual tool interfaces retain native SwiftUI
fields and tool-specific UI. The current tool's command manifest,
icon and action are synchronized when opening a tool tile.

The Layouts / Settings screen now operates on the same saved keys as
the toolbar: larger keys, Hebrew layout, offline word suggestions, and
explicit optional network access. Full Access can only be granted in
system Settings. Existing custom scripts and JS input routing are kept.

Suggested device acceptance checks:
1. Landscape: normal keyboard should NOT show an unused large top band.
2. Grow/Shrink: keycaps actually grow; top blank padding must not.
3. Type hel in English or של in Hebrew in Notes with host focus:
   a suggestion row should appear above the unchanged command bar.
4. Select autocomplete suggestion: only the partial word is replaced,
   never text elsewhere in the document.
5. Open Tools: full grid, Favorites, search, native preview; tapping
   search shows the same keyboard below it.
6. Script Studio + Sefaria: focus switches between internal fields
   and host; native.input() receives the command field contents.
7. Portrait/landscape rotation and Split View; stable key anchoring.
8. Full Access/network gates must remain opt-in.

## Adaptive KeyboardKit Toolbar (v0.10.0)

This version replaces multiple always-visible controls with ONE 48pt
KeyboardKit-owned toolbar above the existing keys.

- **Default:** one manifest-driven command chooser, native search field,
  action button, and ellipsis menu. There is no extra status line and no
  separate Quick Actions strip. The compact keyboard height is selected
  by default, with the old large size available from the menu.
- **Typing into a host app:** if the current word has suggestions, the
  center becomes a row of up to three local completions. The command search
  is always one tap away (magnifying glass). Typing into the command field
  never sends host text to any service.
- **Offline completions:** uses Apple's UITextChecker for whichever
  supported language is available, with a small fallback set for English
  and Hebrew. These are word completions, not Apple QuickType prediction,
  grammar correction, or an AI text model. The engine sends no data over
  the network. Selecting a suggestion replaces only the exact partial word
  immediately before the host caret after checking the current context;
  it never auto-inserts or transmits text.
- **Tool Library:** takes over the keyboard's area instead of crowding a
  grid above visible keys. Tool filtering uses the shared command/search
  row; tapping a tool field restores the regular keyboard automatically.
- **Results:** the existing script/results panel appears above the
  toolbar, with a modest additional height request only while results
  are visible. It may expand to a full workspace by explicit action.
- **More (ellipsis):** Keyboard, Tools, Scripts, Hebrew/English, keyboard
  size, From Cursor, Type in App, and Command Input. The menu uses SwiftUI
  controls and does not insert a second UIToolbar inside the extension.
- **Compatibility:** iOS 17+ with real Glass buttons on supported systems.
  The iPad's letter layout remains managed by KeyboardKit and is not
  remade when suggestions appear.

Physical iPadOS landscape, split-view, hosted text fields, keyboard
height, and Hebrew completion behavior still require device testing.

## Universal Smart Command Bar (v0.9.0)

- Persistent SF Symbol command picker and system search field above KeyboardKit
  keys in host typing and tool workspace modes.
- Redundant action menus were removed from the older Keyboard.Toolbar.
  Navigation, language and script buttons remain in the original HStack.
  Extra cursor-navigation controls display only while a tool field needs them.
- Choose any of 20 tools or built-in/custom JavaScript. The right button comes
  from each manifest: title, icon and required input.
- Explicit input is read using native.input() in JavaScriptCore; native.context()
  remains the separate host document context. Legacy saved scripts still work.
- Only running a command (Run / Return) executes scripts or network requests;
  choosing an item in the native Menu performs no remote work.
- HTTPS requires Full Access plus the explicit Network On switch. From cursor
  transfers context into the command field only at the user's request.
- Native inline results and Insert buttons, script-controlled SwiftUI form
  inputs/actions and an optional results-only workspace mode are included.
- Tapping any internal input in results-only mode restores the key view.
- Hebrew and English now share the same KeyboardKit rendering engine. A Hebrew
  alphabetic character layout is mapped onto standard keyboard items, leaving
  system modifiers and sizing in KeyboardKit. Exact Apple Hebrew key spacing
  must still be visually verified on an iPad.
- Presentation height no longer depends on internal focus. The original
  Keyboard.Toolbar and HStack remain in charge of key layout.

### Custom script manifest

Add the following as the FIRST line of JS source, or use Script Studio's
native Command Bar Manifest editor:

    // @keyboard-manifest {"input":{"placeholder":"Type a query","required":true},"action":{"title":"Search","symbol":"magnifyingglass"},"result":"inlineList","permissions":["network"]}

Then read the text using:

    const query = native.input();
    native.ui({title:"Results",rows:[{title:query,detail:"Preview",insert:query}]});

Result styles: inlineList, inlineText, workspace. Permitted declared
permissions: network, clipboard. The manifest cannot grant those
permissions or bypass iOS limits. The host context remains separate.

## Native iPadOS controls (v0.8.0)

Based on v0.7.1, confirmed working on the user's iPad. We deliberately
do not nest a second UIToolbar in OpenKeyboardKit's keyboard toolbar.

- The stable Keyboard.Toolbar / HStack layout remains unchanged; each command
  is now a native SwiftUI Glass button on iOS 26+, with a bordered fallback on
  iOS 17-25. Fixed height protects keyboard key space.
- A small UIKit UIButton.Configuration.glass() quick actions button with a genuine
  UIMenu opens Wikipedia, Sefaria, Calculator, Clipboard, and Quick Brief.
  It is embedded as an individual control in the existing HStack, not a UIToolbar.
- Tool headers use native GlassEffectContainer with grouped Liquid Glass
  commands instead of custom translucent toolbar backgrounds.
- Script Studio shows its own Glass header without a duplicated outer header,
  reserving more usable space for scripts and forms.
- The launcher, Sefaria, Wikipedia, dictionary, and GIF searches display a
  genuine UISearchBar. A transparent hit target activates a LabInputRouter
  Binding while UISearchBar itself is noninteractive and cannot become
  first responder. Only the existing extension keyboard accepts text.
- Adds an insertable Quick Brief tool with native segmented Picker, Menu,
  DatePicker, Toggle, Stepper, Slider, ProgressView, confirmationDialog and
  a live result preview. Advanced buttons use glassEffectID in a
  GlassEffectContainer.
- Adds system context-menu preview for GIF cards and explicit Copy GIF and
  Copy Source Link actions.
- Existing native previews, Pow animations, hosted focus routing, languages,
  scripts and tool features remain in place.

Keyboard extensions cannot guarantee presentation of every full-screen system
picker or share sheet. Such components remain experimental. The complete build
must be checked on an actual iPad before replacing the stable version.

## Stability hotfix v0.7.1

The v0.7.0 UI was reported to display a large blank translucent keyboard area on iPadOS 27.
This release restores the SwiftUI keyboard toolbar from the last user-verified v0.6.1
build and removes the experimental UIKit UIToolbar from the keyboard UI. The exact
runtime root cause is not proven without device logs.

While tools are open, characters go to a selected internal field; with no internal
field active they go through the host textDocumentProxy. The To App control releases
tool focus without closing the tool. A host selection change is also handled on
a best-effort basis; iPadOS does not expose other applications' complete focus state.

The new UIKit toolbars and UISearchBar experiment remains isolated in
feature/native-toolbar-focus, not included in this release.

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
