import SwiftUI
import UIKit

private struct SavedEntry: Codable, Identifiable {
    var id: String
    var text: String
    var created: Date

    init(_ text: String) {
        id = UUID().uuidString
        self.text = text
        created = .now
    }
}

private enum LabSaved {
    static func load(_ key: String) -> [SavedEntry] {
        guard let bytes = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([SavedEntry].self, from: bytes) else {
            return []
        }
        return entries
    }

    static func store(_ entries: [SavedEntry], to key: String) {
        if let data = try? JSONEncoder().encode(Array(entries.prefix(100))) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct LabClipboardPanel: View {
    let insertText: (String) -> Void
    let fullAccess: Bool

    @State private var saved: [SavedEntry] = []
    @State private var status = ""
    private let storeKey = "keyboard.lab.clips.v1"

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            LabHint(text: "Clipboard history is saved only when you tap Save current clipboard. No background surveillance.", icon: "hand.raised")

            LabActionButton(text: "Save current clipboard", icon: "doc.on.clipboard") {
                guard fullAccess else {
                    status = "Allow Full Access in iPadOS Settings."
                    return
                }
                guard let text = UIPasteboard.general.string, !text.isEmpty else {
                    status = "No text available to save."
                    return
                }
                saved.insert(SavedEntry(LabText.clip(text)), at: 0)
                LabSaved.store(saved, to: storeKey)
                status = "Saved locally."
            }

            if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.secondary) }

            ForEach(saved) { item in
                HStack {
                    Button { insertText(item.text) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.text)
                                .lineLimit(3)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.primary)
                            Text(item.created, style: .date)
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Button(role: .destructive) {
                        saved.removeAll { $0.id == item.id }
                        LabSaved.store(saved, to: storeKey)
                    } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                }
                .padding(13)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 13))
            }
            if saved.isEmpty { LabHint(text: "No saved clips yet.") }
        }
        .onAppear { saved = LabSaved.load(storeKey) }
    }
}

struct LabNotepadPanel: View {
    let insertText: (String) -> Void

    @State private var draft = ""
    @State private var saved: [SavedEntry] = []
    private let key = "keyboard.lab.notes.v1"

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            LabHint(text: "Private quick notes stored in the keyboard extension. Tap any note to insert its text.", icon: "note.text")
            TextEditor(text: $draft)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14))

            LabActionButton(text: "Save note", icon: "plus") {
                let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                saved.insert(SavedEntry(LabText.clip(text, limit: 10000)), at: 0)
                LabSaved.store(saved, to: key)
                draft = ""
            }

            ForEach(saved) { note in
                HStack {
                    Button { insertText(note.text) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.text).font(.subheadline)
                                .lineLimit(3)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Text("Tap to insert").font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Button {
                        draft = note.text
                    } label: { Image(systemName: "square.and.pencil") }
                    .buttonStyle(.borderless)
                    Button(role: .destructive) {
                        saved.removeAll { $0.id == note.id }
                        LabSaved.store(saved, to: key)
                    } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                }
                .padding(13)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .onAppear { saved = LabSaved.load(key) }
    }
}

struct LabSnippetsPanel: View {
    let insertText: (String) -> Void

    @State private var draft = ""
    @State private var saved: [SavedEntry] = []
    private let key = "keyboard.lab.snippets.v1"
    private let defaults = [
        ("Thank you", "Thank you very much!"),
        ("Regards", "Kind regards,"),
        ("Hebrew greeting", "שלום וברכה"),
        ("Follow up", "Just following up on our previous message.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabHint(text: "One-tap templates. Create your own without uploading any data.", icon: "text.bubble")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(defaults, id: \.0) { pair in
                    Button { insertText(pair.1) } label: {
                        Label(pair.0, systemImage: "text.insert")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(Color(uiColor: .tertiarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 9) {
                TextField("New snippet", text: $draft)
                    .textInputAutocapitalization(.sentences)
                Button {
                    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    saved.insert(SavedEntry(LabText.clip(text)), at: 0)
                    LabSaved.store(saved, to: key)
                    draft = ""
                } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12))

            ForEach(saved) { item in
                HStack {
                    Button { insertText(item.text) } label: {
                        Text(item.text)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Button(role: .destructive) {
                        saved.removeAll { $0.id == item.id }
                        LabSaved.store(saved, to: key)
                    } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                }
                .padding(12)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear { saved = LabSaved.load(key) }
    }
}

struct LabThemesPanel: View {
    @AppStorage("keyboard.lab.theme") private var selected = LabTheme.classic.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            LabHint(text: "Choose a palette for Keyboard Lab tools, accent controls and the launcher.", icon: "paintpalette")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(LabTheme.allCases) { theme in
                    Button { selected = theme.rawValue } label: {
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(theme.accent.opacity(0.22))
                                .frame(height: 65)
                                .overlay {
                                    HStack {
                                        Circle().fill(theme.accent).frame(width: 24)
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.white.opacity(0.85))
                                            .frame(width: 55, height: 24)
                                    }
                                }
                            HStack {
                                Text(theme.title).font(.subheadline.weight(.medium))
                                Spacer()
                                if selected == theme.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding(11)
                        .background(Color(uiColor: .tertiarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            LabHint(text: "The Apple-style typing keys retain their proven layout and dimensions; themes currently change tool UI colors.")
        }
    }
}

struct LabProfilesPanel: View {
    @AppStorage("keyboard.lab.favorites") private var pinnedIDs = "sefaria,wikipedia,clipboard,textFX,calculator,templates"
    @State private var favorites: Set<String> = []
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            LabHint(text: "Pick up to six favorite tools. They appear as quick-access shortcuts above the keyboard.", icon: "pin")
            ForEach(LabTool.allCases) { tool in
                Button {
                    if favorites.contains(tool.rawValue) {
                        favorites.remove(tool.rawValue)
                    } else if favorites.count < 6 {
                        favorites.insert(tool.rawValue)
                    }
                    saved = false
                } label: {
                    HStack {
                        Image(systemName: tool.symbol)
                            .foregroundStyle(tool.tint)
                            .frame(width: 27)
                        Text(tool.title).foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: favorites.contains(tool.rawValue) ?
                              "checkmark.circle.fill" : "circle")
                            .foregroundStyle(favorites.contains(tool.rawValue) ? .green : .secondary)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            LabActionButton(text: saved ? "Saved!" : "Save favorites", icon: "checkmark") {
                let chosen = LabTool.allCases.filter { favorites.contains($0.rawValue) }
                pinnedIDs = chosen.map(\.rawValue).joined(separator: ",")
                saved = true
            }
        }
        .onAppear { favorites = Set(pinnedIDs.split(separator: ",").map(String.init)) }
    }
}

struct LabLayoutsPanel: View {
    @AppStorage("keyboard.lab.expanded") private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            LabHint(text: "Keyboard layout preferences apply to the extension. iPadOS may limit custom keyboard height.", icon: "keyboard")
            Toggle("Expanded keyboard height", isOn: $expanded)
                .padding(13)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12))
            LabHint(text: "The English QWERTY engine is still provided by OpenKeyboardKit. Hebrew key layouts and autocorrection are a separate engine enhancement, not unlocked by this toggle.")
            LabHint(text: "Use the globe key to choose another system keyboard. Secure fields always use an Apple keyboard.", icon: "globe")
        }
    }
}
