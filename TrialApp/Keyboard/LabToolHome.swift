import SwiftUI
import SwiftUIIntrospect

/// A real native tool command center, adaptive to the area iPadOS grants.
struct LabToolHome: View {
    let onSelect: (LabTool) -> Void
    let onClose: () -> Void

    @State private var search = ""
    @State private var filter = 0
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue
    @AppStorage("keyboard.lab.favorites") private var pinnedIDs =
        "sefaria,wikipedia,clipboard,textFX,calculator,templates"

    private var accent: Color { LabDesign.accent(themeName) }
    private var pinned: Set<String> { Set(pinnedIDs.split(separator: ",").map(String.init)) }

    private var visible: [LabTool] {
        let all = filter == 1 ? LabTool.allCases.filter { pinned.contains($0.rawValue) }
                              : LabTool.allCases
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? all : all.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.detail.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Button(action: onClose) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 34, height: 34)
                        .labGlass(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to keyboard")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your workspace")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("Everything you need, where you type")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 18, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accent)
                    .frame(width: 35, height: 35)
                    .labGlass(12)
            }
            .padding(.horizontal, 14)
            .frame(height: 59)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                LabEditableField(
                    id: "launcher.search",
                    placeholder: "Search all tools",
                    text: $search,
                    minHeight: 37
                )
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 13)
            .padding(.bottom, 7)

            HStack(spacing: 8) {
                Picker("View", selection: $filter) {
                    Text("All tools").tag(0)
                    Text("Favorites").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)

                Spacer()

                Text("\(visible.count) tools")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 9)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150, maximum: 300), spacing: 9)],
                    spacing: 9
                ) {
                    ForEach(visible) { tool in
                        LabAnimatedTile(
                            title: tool.title, detail: tool.detail,
                            symbol: tool.symbol, tint: tool.tint
                        ) {
                            onSelect(tool)
                        }
                    }
                }
                .padding(.horizontal, 13)
                .padding(.bottom, 12)
                if visible.isEmpty {
                    ContentUnavailableView.search(text: search)
                        .padding(.top, 16)
                }
            }
            .scrollIndicators(.hidden)
            .introspect(.scrollView, on: .iOS(.v17, .v18, .v26, .v27)) { scroll in
                scroll.bounces = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(colors: [LabDesign.canvas,
                                    accent.opacity(0.05),
                                    LabDesign.canvas],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct LabQuickAccess: View {
    let open: (LabTool) -> Void
    let showAll: () -> Void
    @AppStorage("keyboard.lab.favorites") private var pinnedIDs =
        "sefaria,wikipedia,clipboard,textFX,calculator,templates"

    private var favorites: [LabTool] {
        let ids = pinnedIDs.split(separator: ",").map(String.init)
        let tools = ids.compactMap(LabTool.init(rawValue:))
        return tools.isEmpty ? LabTool.favorites : Array(tools.prefix(6))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Quick actions", systemImage: "bolt.horizontal.circle")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                Button(action: showAll) {
                    Label("Explore", systemImage: "square.grid.2x2")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.indigo)
            }
            .padding(.horizontal, 17)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(favorites) { tool in
                    Button { open(tool) } label: {
                        HStack(spacing: 7) {
                            Image(systemName: tool.symbol)
                                .foregroundStyle(tool.tint)
                                .font(.system(size: 13))
                            Text(tool.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 37)
                        .background(tool.bg, in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 9)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }
}
