import SwiftUI
import Foundation

struct TrialHomeView: View {
    @State private var sampleText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(spacing: 15) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Keyboard Lab")
                                .font(.largeTitle.bold())
                            Text("Native SwiftUI · JavaScriptCore · OpenKeyboardKit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("System-wide keyboard", systemImage: "globe")
                                .font(.headline)
                            Text("After installing the IPA, open Settings → General → Keyboard → Keyboards → Add New Keyboard and choose Keyboard Lab. In Notes, LONG-PRESS the globe key to select it. iPadOS may remember a different keyboard for each app.")
                            Text("iPadOS restricts third-party keyboards in password fields, certain phone inputs and apps that opt out.")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(
                                keyboardExtensionIsEmbedded
                                    ? "Keyboard extension is embedded"
                                    : "Keyboard extension is missing",
                                systemImage: keyboardExtensionIsEmbedded
                                    ? "checkmark.circle.fill"
                                    : "exclamationmark.triangle.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(keyboardExtensionIsEmbedded ? .green : .orange)
                            Text("Bundle: com.goldypov.keyboardtrial.extension")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text("If it works here but is absent from Notes, check Settings → General → Keyboard → Keyboards. Remove and add Keyboard Lab again after an update. If it is still absent, make sure SideStore signed the embedded .appex as well as the app.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("This check confirms the extension exists inside the installed app, not that iPadOS has enabled or registered it.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Full Access", systemImage: "checkmark.shield")
                                .font(.headline)
                            Text("To enable network-powered JavaScript tools, open Settings → General → Keyboard → Keyboards → Keyboard Lab → Allow Full Access.")
                            Text("The app cannot grant Full Access itself. Keyboard code with network access may transmit entered text, so only run scripts you trust.")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Script Studio", systemImage: "curlybraces.square")
                                .font(.headline)
                            Text("Tap Scripts in the keyboard toolbar to run native SwiftUI panels powered by JavaScriptCore. Built-in tools: Wikipedia, Sefaria, JSON formatting, current date, and UI widgets.")
                            Text("Copy custom JS, then use Import JS from inside the keyboard. Scripts are saved locally in the keyboard extension.")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Try typing")
                            .font(.headline)
                        TextEditor(text: $sampleText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                    }
                }
                .padding(24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Keyboard Lab")
        }
        .tint(.indigo)
    }

    /// This verifies IPA packaging after the device re-signs the application.
    /// System keyboard activation cannot be queried by another app.
    private var keyboardExtensionIsEmbedded: Bool {
        guard let plugIns = Bundle.main.builtInPlugInsURL else { return false }
        let extensionURL = plugIns.appendingPathComponent(
            "TrialKeyboardExtension.appex",
            isDirectory: true
        )
        return FileManager.default.fileExists(atPath: extensionURL.path)
    }
}
