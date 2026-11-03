import SwiftUI
import UIKit

struct ScriptStudioView: View {
    let onClose: () -> Void
    let insertText: (String) -> Void
    let readContext: () -> String
    let fullAccess: Bool

    @StateObject private var model = ScriptStudioModel()
    @AppStorage("keyboard.trial.allowNetwork") private var allowNetwork = false
    @State private var showCode = false
    @State private var lastScript: KeyboardScript?

    private let background = Color(uiColor: .secondarySystemBackground)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onClose) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 38, height: 36)
                }
                .accessibilityLabel("חזור למקלדת")

                Image(systemName: "curlybraces.square.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                Text("Script Studio")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("JSCore")
                    .font(.caption2.monospaced().weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }
            .padding(.horizontal, 14)
            .frame(height: 48)

            Divider()

            if showCode, let script = lastScript {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("חזור לתוצאות") { showCode = false }
                            .buttonStyle(.bordered)
                        Text(script.source)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .padding(14)
                }
            } else if let panel = model.panel {
                panelView(panel)
            } else {
                library
            }

            Divider()
            HStack(spacing: 10) {
                Button {
                    if fullAccess {
                        allowNetwork.toggle()
                    } else {
                        model.status = "הגדרות > מקלדות > Keyboard Trial > אפשר גישה מלאה"
                    }
                } label: {
                    Label(allowNetwork && fullAccess ? "Network On" : "Network Off", systemImage: allowNetwork && fullAccess ? "wifi" : "wifi.slash")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(allowNetwork && fullAccess ? .green : .secondary)
                .accessibilityLabel("הפעל או כבה גישת רשת לסקריפטים")

                Spacer(minLength: 4)

                if lastScript != nil {
                    Button(showCode ? "תוצאות" : "קוד") { showCode.toggle() }
                        .font(.caption.weight(.medium))
                        .buttonStyle(.bordered)
                }

                Button {
                    model.canReadClipboard = fullAccess
                    model.installFromClipboard()
                } label: {
                    Label("ייבא JS", systemImage: "doc.on.clipboard")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            HStack(spacing: 7) {
                if model.isLoading {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: fullAccess ? "checkmark.shield" : "exclamationmark.shield")
                        .foregroundStyle(fullAccess ? .green : .orange)
                }
                Text(model.status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 10)
        }
        .background(background)
    }

    private var library: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                ForEach(ScriptLibrary.scripts + model.customScripts) { script in
                    Button {
                        run(script)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Image(systemName: script.symbol)
                                .font(.title2)
                                .foregroundStyle(.indigo)
                            Text(script.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(script.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if !script.isBuiltIn {
                            Button(role: .destructive) { model.delete(script) } label: {
                                Label("מחק סקריפט", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(14)
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
                        model.status = "בחר סקריפט"
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                    }
                    .accessibilityLabel("חזור לספריית הסקריפטים")
                }
                .padding(.bottom, 4)

                ForEach(panel.rows ?? []) { row in
                    Button {
                        if let value = row.insert {
                            insertText(value)
                            model.status = "הטקסט הוכנס"
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
                            Image(systemName: "text.insert")
                                .foregroundStyle(.indigo)
                        }
                        .padding(14)
                        .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func run(_ script: KeyboardScript) {
        lastScript = script
        showCode = false
        model.run(
            script,
            readContext: readContext,
            allowNetwork: allowNetwork && fullAccess,
            allowClipboard: fullAccess,
            insert: insertText
        )
    }
}
