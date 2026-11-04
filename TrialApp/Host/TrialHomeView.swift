import SwiftUI
import UIKit

private struct ShowcaseTool: Identifiable {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    var id: String { title }
}

struct TrialHomeView: View {
    @State private var sampleText = ""
    @State private var activeTool: ShowcaseTool?
    @State private var showSetup = false

    private let tools: [ShowcaseTool] = [
        .init(title: "Sefaria", subtitle: "Find original sources", symbol: "books.vertical", tint: .indigo),
        .init(title: "Wikipedia", subtitle: "Live encyclopedia", symbol: "globe.europe.africa", tint: .blue),
        .init(title: "Translate", subtitle: "Hebrew and English", symbol: "character.bubble", tint: .cyan),
        .init(title: "Clipboard", subtitle: "Saved snippets", symbol: "doc.on.clipboard", tint: .teal),
        .init(title: "Text FX", subtitle: "Clean and transform", symbol: "textformat", tint: .pink),
        .init(title: "Dictionary", subtitle: "Word definitions", symbol: "text.book.closed", tint: .brown),
        .init(title: "Calculator", subtitle: "Quick calculations", symbol: "plus.forwardslash.minus", tint: .orange),
        .init(title: "Conversion", subtitle: "Numbers and units", symbol: "arrow.left.arrow.right", tint: .green),
        .init(title: "Notepad", subtitle: "Local notes", symbol: "note.text", tint: .yellow),
        .init(title: "Handwriting", subtitle: "Apple Pencil canvas", symbol: "pencil.tip", tint: .red),
        .init(title: "Photos & Files", subtitle: "Apple system pickers", symbol: "photo.on.rectangle", tint: .blue),
        .init(title: "Script Studio", subtitle: "Native UI and JSCore", symbol: "curlybraces.square", tint: .purple)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    setupCard
                    toolsSection
                    typingDemo
                    privacyNote
                }
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
                .padding(22)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Keyboard Lab")
            .tint(.indigo)
            .sheet(item: $activeTool) { tool in
                NavigationStack {
                    VStack(spacing: 15) {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(tool.tint)
                        Text(tool.title).font(.title2.weight(.semibold))
                        Text(tool.subtitle).font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Open the Keyboard Lab keyboard in a text field, then choose Tools → \(tool.title).")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 25)
                        Spacer()
                    }
                    .padding(.top, 35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemGroupedBackground))
                    .navigationTitle(tool.title)
                    .toolbar {
                        Button("Done") { activeTool = nil }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: "keyboard")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 90, height: 90)
                .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 21))
            VStack(alignment: .leading, spacing: 7) {
                Text("More than a keyboard.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Native SwiftUI tools. Your shortcuts. Your workflows.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Keyboard Lab · 0.4")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.72))
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(23)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.indigo, Color(red: 0.35, green: 0.27, blue: 0.77)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("System keyboard setup", systemImage: "checkmark.shield")
                    .font(.headline)
                Spacer()
                Label(keyboardExtensionIsEmbedded ? "Embedded" : "Not found",
                      systemImage: keyboardExtensionIsEmbedded ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(keyboardExtensionIsEmbedded ? .green : .orange)
            }

            Text("1. Settings → General → Keyboard → Keyboards → Add New Keyboard → Keyboard Lab.")
            Text("2. Open Notes, tap a text field, then long-press 🌐 and select Keyboard Lab.")
            Text("3. To use live search, allow Full Access under this keyboard in Settings, then enable Network On in Script Studio.")

            Text("When installing via SideStore, keep the embedded keyboard extension. iPadOS may refuse third-party keyboards in password fields or apps that opt out.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18))
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explore tools").font(.title2.weight(.semibold))
                    Text("Tap for details; launch the tool from the keyboard.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 175, maximum: 320), spacing: 12)],
                      spacing: 12) {
                ForEach(tools) { tool in
                    Button { activeTool = tool } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tool.symbol)
                                .font(.system(size: 27, weight: .light))
                                .foregroundStyle(tool.tint)
                                .frame(height: 34)
                            Text(tool.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(tool.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 105)
                        .padding(11)
                        .background(tool.tint.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var typingDemo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Try the keyboard", systemImage: "pencil")
                .font(.title3.weight(.semibold))
            Text("Tap below. Switch to Keyboard Lab using the globe key, then try Tools and JS.")
                .font(.subheadline).foregroundStyle(.secondary)
            TextEditor(text: $sampleText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 170)
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 17))
        }
    }

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Privacy and limits", systemImage: "hand.raised")
                .font(.headline)
            Text("Saved clips, snippets and notes are stored locally. Clipboard capture is manual. Live tools only request the network when you grant Full Access and explicitly enable network features. Some pickers and system interfaces may be unavailable inside keyboard extensions.")
                .font(.footnote).foregroundStyle(.secondary)
            Link("Open source repository", destination:
                    URL(string: "https://github.com/davidpovarsky/OpenKeyboardKit")!)
                .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 17))
    }

    private var keyboardExtensionIsEmbedded: Bool {
        guard let plugIns = Bundle.main.builtInPlugInsURL else { return false }
        return FileManager.default.fileExists(
            atPath: plugIns.appendingPathComponent("TrialKeyboardExtension.appex").path
        )
    }
}
