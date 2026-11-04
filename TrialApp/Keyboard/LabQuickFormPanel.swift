import SwiftUI
import UIKit

/// A useful output-oriented tool built entirely with native iPadOS controls.
/// It produces a reusable status brief rather than merely demonstrating UI.
struct LabQuickFormPanel: View {
    let insertText: (String) -> Void
    let fullAccess: Bool

    @State private var subject = ""
    @State private var status = 0
    @State private var priority = 1
    @State private var count = 1
    @State private var progress = 0.25
    @State private var includeDate = true
    @State private var dueDate = Date()
    @State private var advanced = false
    @State private var showClearConfirmation = false
    @State private var notice = ""
    @Namespace private var glassNamespace

    private let statuses = ["Planned", "In progress", "Done"]
    private let priorities = ["Low", "Normal", "High", "Urgent"]

    private var brief: String {
        let name = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        var lines = [name.isEmpty ? "Project update" : name]
        lines.append("Status: \(statuses[status])")
        lines.append("Priority: \(priorities[priority])")
        if includeDate {
            lines.append("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
        }
        if advanced {
            lines.append("Items: \(count)")
            lines.append("Progress: \(Int(progress * 100))%")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabSectionHeading(
                title: "Quick Brief",
                subtitle: "A polished form that inserts a ready-to-send status",
                icon: "slider.horizontal.3"
            )

            LabEditableField(
                id: "quickbrief.subject", placeholder: "Project or subject",
                text: $subject
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Status").font(.caption.weight(.semibold))
                Picker("Status", selection: $status) {
                    ForEach(statuses.indices, id: \.self) {
                        Text(statuses[$0]).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: status)
            }

            HStack(spacing: 14) {
                Menu {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities.indices, id: \.self) {
                            Text(priorities[$0]).tag($0)
                        }
                    }
                } label: {
                    Label("Priority: \(priorities[priority])",
                          systemImage: "flag")
                        .font(.subheadline)
                }

                Spacer(minLength: 0)

                Toggle("Include due date", isOn: $includeDate)
                    .font(.caption)
                    .fixedSize()
            }
            .padding(11)
            .background(LabDesign.card,
                        in: RoundedRectangle(cornerRadius: 13))

            if includeDate {
                DatePicker("Due date", selection: $dueDate,
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(10)
                    .background(LabDesign.card,
                                in: RoundedRectangle(cornerRadius: 13))
            }

            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.smooth(duration: 0.25)) {
                                advanced.toggle()
                            }
                        } label: {
                            Label(advanced ? "Less" : "More options",
                                  systemImage: advanced ? "minus.circle" : "plus.circle")
                        }
                        .buttonStyle(.glass)
                        .glassEffectID("options", in: glassNamespace)

                        Spacer()

                        if advanced {
                            Button {
                                showClearConfirmation = true
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.glass)
                            .glassEffectID("reset", in: glassNamespace)
                        }
                    }
                }
            } else {
                HStack {
                    Button(advanced ? "Less" : "More options") {
                        withAnimation { advanced.toggle() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    if advanced {
                        Button("Reset") { showClearConfirmation = true }
                            .buttonStyle(.bordered)
                    }
                }
            }

            if advanced {
                VStack(alignment: .leading, spacing: 12) {
                    Stepper("Number of items: \(count)", value: $count,
                            in: 1...99)
                    Divider()
                    HStack {
                        Text("Progress")
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $progress, in: 0...1, step: 0.05)
                    ProgressView(value: progress)
                        .tint(.indigo)
                }
                .padding(14)
                .background(LabDesign.card,
                            in: RoundedRectangle(cornerRadius: 15))
            }

            GroupBox("Preview") {
                Text(brief)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.vertical, 6)
            }

            HStack(spacing: 10) {
                LabGlassCommand(
                    title: "Insert brief", symbol: "text.insert",
                    prominent: true
                ) {
                    insertText(brief)
                    notice = "Inserted in the host text field."
                }
                LabGlassCommand(title: "Copy", symbol: "doc.on.doc") {
                    guard fullAccess else {
                        notice = "Enable Full Access to copy to the clipboard."
                        return
                    }
                    UIPasteboard.general.string = brief
                    notice = "Copied to clipboard."
                }
            }

            if !notice.isEmpty {
                Label(notice, systemImage: "checkmark.circle")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .confirmationDialog(
            "Clear this brief?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset all fields", role: .destructive) {
                subject = ""
                status = 0
                priority = 1
                count = 1
                progress = 0.25
                includeDate = true
                dueDate = .now
                notice = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
