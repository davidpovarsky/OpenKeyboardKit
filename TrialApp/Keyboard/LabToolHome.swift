import SwiftUI

/// Native, adaptive tool launcher inspired by the clarity of Clink,
/// not a web view or image-based imitation.
struct LabToolHome: View {
    let onSelect: (LabTool) -> Void
    let onClose: () -> Void

    @State private var search = ""
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue
    @AppStorage("keyboard.lab.favorites") private var pinnedIDs = "sefaria,wikipedia,clipboard,textFX,calculator,templates"

    private var accent: Color {
        LabTheme(rawValue: themeName)?.accent ?? .indigo
    }

    private var visible: [LabTool] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return LabTool.allCases }
        return LabTool.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.detail.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 38, height: 36)
                }
                .accessibilityLabel("Back to keyboard")
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Keyboard Lab")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Your tools, one tap away")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(accent)
                    .font(.title3)
                    .padding(9)
                    .background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
            }
            .padding(.horizontal, 18)
            .frame(height: 64)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Find a tool", text: $search)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color(uiColor: .tertiarySystemBackground), in: Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 158, maximum: 360), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(visible) { tool in
                        Button { onSelect(tool) } label: {
                            LabToolTile(tool: tool)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(tool.title): \(tool.detail)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(.secondary)
                Text("Local tools run on-device. Network features require your permission.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .tint(accent)
    }
}

struct LabToolTile: View {
    let tool: LabTool

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: tool.symbol)
                .font(.system(size: 28, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tool.tint)
                .frame(height: 35)
            Text(tool.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(tool.detail)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 95)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tool.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tool.tint.opacity(0.17), lineWidth: 0.85)
        )
    }
}

/// Replaces dead space above the keys in expanded mode with useful shortcuts.
struct LabQuickAccess: View {
    let open: (LabTool) -> Void
    let showAll: () -> Void
    @AppStorage("keyboard.lab.favorites") private var pinnedIDs = "sefaria,wikipedia,clipboard,textFX,calculator,templates"

    private var favoriteTools: [LabTool] {
        let names = pinnedIDs.split(separator: ",").map(String.init)
        let picked = names.compactMap(LabTool.init(rawValue:))
        return picked.isEmpty ? LabTool.favorites : Array(picked.prefix(6))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Quick access")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: showAll) {
                    Label("All tools", systemImage: "square.grid.2x2")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.indigo)
            }
            .padding(.horizontal, 17)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), spacing: 8)],
                spacing: 8
            ) {
                ForEach(favoriteTools) { tool in
                    Button { open(tool) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tool.symbol)
                                .foregroundStyle(tool.tint)
                                .font(.system(size: 14))
                            Text(tool.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(tool.bg, in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}
