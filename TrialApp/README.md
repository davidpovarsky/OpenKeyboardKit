# Keyboard Lab v0.4 — Native iPad Keyboard Toolkit

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
- **Tool launcher**: adaptive pastel tool cards, search and keyboard-return control.
- **Tool detail**: full-height SwiftUI workspace rendered inside the keyboard, not a separate app.

Expanded and compact keyboard heights are requested through Auto Layout; actual size is controlled by iPadOS. The extra space in typing mode is above the keys, never beneath them.

## Working tools

| Tool | Local/network | Notes |
| --- | --- | --- |
| Sefaria search | Network | POST /api/search-wrapper; Hebrew lemmatizer |
| Wikipedia | Network | MediaWiki OpenSearch, chooses Hebrew/English |
| Dictionary | Network | Free English Dictionary API |
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
- GIF search and remote generative AI providers are not configured or represented as operational.
- Images copied through the clipboard can only be pasted into host applications that accept them. File pickers cannot attach arbitrary documents to other apps.
- TextField/TextEditor in a custom keyboard extension may behave differently between host apps; verify on the intended iPad.
- External APIs (Sefaria, Wikipedia, DictionaryAPI, MyMemory) may change or become unavailable. Only explicit searches send queries.
- App Group synchronization with the host application has not yet been configured and may require new signing entitlements.
- A full native UI cannot bypass iPadOS sandboxing, privacy permissions, or extension resource limits.

## Build

The GitHub workflow builds using an Intel-hosted macOS runner and Xcode 16.4 (proven toolchain for this fork), generates Xcode targets via XcodeGen, runs Release compilation, validates the embedded keyboard extension's Info.plist and Full Access request, assembles an **unsigned** .ipa, and uploads it to Releases. An upgrade test for Xcode 27 is planned after confirming tooling availability and migration compatibility.
