import SwiftUI
import UIKit

struct ScriptStudioView: View {
    let onClose: () -> Void
    let insertText: (String) -> Void
    let readContext: () -> String
    let fullAccess: Bool

    @StateObject private var model = ScriptStudioModel()
    @AppStorage("keyboard.trial.allowNetwork") private var allowNetwork = false

    @State private var editing = false
    @State private var codeTitle = ""
    @State private var codeSource = ""
    @State private var editingID: String?
    @State private var currentScript: KeyboardScript?
    @State private var fieldValues: [String: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 35)
                }
                .buttonStyle(.plain)
                Image(systemName: "curlybraces.square.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.indigo)
                    .frame(width: 34, height: 34)
                    .labGlass(10)
                Text("Script Studio")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                if editing {
                    Button("Cancel") { editing = false }
                        .font(.caption.weight(.medium))
                } else {
                    Button {
                        openEditor(nil)
                    } label: {
                        Label("New JS", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 45)
            .background(.ultraThinMaterial)

            Divider().opacity(0.35)

            if editing {
                editor
            } else if let panel = model.panel {
                panelView(panel)
            } else {
                library
            }

            Divider()
            HStack(spacing: 8) {
                Button {
                    if fullAccess {
                        allowNetwork.toggle()
                    } else {
                        model.status = "Enable Full Access for Keyboard Lab in iPad Settings."
                    }
                } label: {
                    Label(allowNetwork && fullAccess ? "Network On" : "Network Off",
                          systemImage: allowNetwork && fullAccess ? "wifi" : "wifi.slash")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(allowNetwork && fullAccess ? .green : .secondary)

                Spacer(minLength: 2)

                if let script = currentScript, !editing {
                    Button("Code") { openEditor(script) }
                        .font(.caption).buttonStyle(.bordered)
                }

                Button {
                    model.canReadClipboard = fullAccess
                    model.installFromClipboard()
                } label: {
                    Label("Import", systemImage: "doc.on.clipboard")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            HStack(spacing: 7) {
                if model.isLoading {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: fullAccess ? "checkmark.shield" : "exclamationmark.shield")
                        .foregroundStyle(fullAccess ? .green : .orange)
                }
                Text(model.status)
                    .font(.caption2).foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer(minLength: 2)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .onDisappear { model.stop() }
    }

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Label("JavaScript tools", systemImage: "square.grid.2x2")
                    .font(.subheadline.weight(.semibold))
                Text("Scripts run inside the keyboard via JavaScriptCore. Interfaces are native SwiftUI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)],
                          spacing: 12) {
                    ForEach(ScriptLibrary.scripts + model.customScripts) { script in
                        LabAnimatedTile(
                            title: script.title,
                            detail: script.detail,
                            symbol: script.symbol,
                            tint: .indigo
                        ) {
                            run(script)
                        }
                        .contextMenu {
                            Button(script.isBuiltIn ? "Copy as custom" : "Edit") {
                                openEditor(script)
                            }
                            if !script.isBuiltIn {
                                Button(role: .destructive) { model.delete(script) } label: {
                                    Label("Delete script", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
            LabEditableField(id: "studio.scriptTitle",
                             placeholder: "Script title", text: $codeTitle)

            LabEditableField(id: "studio.scriptCode",
                             placeholder: "JavaScript source code",
                             text: $codeSource, multiline: true,
                             minHeight: 115)

            HStack(spacing: 8) {
                Button("Save") {
                    if model.saveCustom(title: codeTitle, source: codeSource, replacing: editingID) {
                        editing = false
                        currentScript = nil
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Save & Run") {
                    if model.saveCustom(title: codeTitle, source: codeSource, replacing: editingID) {
                        editing = false
                        if let saved = model.customScripts.first(where: {
                            $0.id == (editingID ?? "")
                        }) {
                            run(saved)
                        } else if let saved = model.customScripts.last {
                            run(saved)
                        }
                    }
                }
                .buttonStyle(.bordered)

                Spacer()
                Text("\(codeSource.utf8.count) / 50 KB")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            LabHint(text: "Only run code you trust. With Network On, scripts can send visible typing context to remote services.")
            }
            .padding(12)
        }
    }

    private func panelView(_ panel: ScriptPanel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(panel.title)
                            .font(.title3.weight(.semibold))
                        if let message = panel.message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer()
                    Button {
                        model.panel = nil
                        model.status = "Choose a script"
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                    }
                    .accessibilityLabel("Back to scripts")
                }

                ForEach(panel.fields ?? []) { field in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(field.title ?? field.id)
                            .font(.caption.weight(.medium))
                        LabEditableField(
                            id: "studio.field." + field.id,
                            placeholder: field.placeholder ?? "Enter text",
                            text: Binding(
                                get: { fieldValues[field.id] ?? field.value ?? "" },
                                set: { fieldValues[field.id] = $0 }
                            )
                        )
                    }
                }

                ForEach(panel.buttons ?? []) { button in
                    Button {
                        if let insertion = button.insert {
                            insertText(insertion)
                        } else {
                            model.fireAction(button.id, values: fieldValues)
                        }
                    } label: {
                        Label(button.title, systemImage: button.symbol ?? "bolt")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent)
                }

                ForEach(panel.rows ?? []) { row in
                    Button {
                        if let value = row.insert {
                            insertText(value)
                            model.status = "Text inserted"
                        }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(row.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(4)
                                if let detail = row.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            Spacer()
                            Image(systemName: "text.insert").foregroundStyle(.indigo)
                        }
                        .padding(13)
                        .background(Color(uiColor: .tertiarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
    }

    private func openEditor(_ script: KeyboardScript?) {
        editing = true
        editingID = script?.isBuiltIn == false ? script?.id : nil
        codeTitle = script?.title ?? "My Script"
        codeSource = script?.source ?? """
            native.ui({
              title: "Hello",
              message: "A native SwiftUI panel created by JavaScript.",
              fields: [{id: "name", title: "Name", placeholder: "Your name"}],
              buttons: [{id: "greet", title: "Insert greeting", symbol: "heart"}]
            });
            native.onAction = (id, values) => {
              if (id === "greet") native.insert("Hello " + (values.name || "there"));
            };
            """
    }

    private func run(_ script: KeyboardScript) {
        currentScript = script
        fieldValues = [:]
        model.run(
            script,
            readContext: readContext,
            allowNetwork: allowNetwork && fullAccess,
            allowClipboard: fullAccess,
            insert: insertText
        )
    }
}
