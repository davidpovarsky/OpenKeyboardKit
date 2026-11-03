import SwiftUI

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
                            Text("Enable Keyboard Lab in Settings → General → Keyboard → Keyboards → Add New Keyboard. Long-press the globe key in Notes, Safari or another editable text field.")
                            Text("iPadOS restricts third-party keyboards in password fields, certain phone inputs and apps that opt out.")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Full Access", systemImage: "checkmark.shield")
                                .font(.headline)
                            Text("To enable network-powered JavaScript tools, open Settings → General → Keyboard → Keyboards → Keyboard Trial and enable Allow Full Access.")
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
}
