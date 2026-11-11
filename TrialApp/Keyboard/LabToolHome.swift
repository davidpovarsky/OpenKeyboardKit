import SwiftUI
import SwiftUIIntrospect

/// The extension's compact command center. Tool fields use LabInputRouter,
/// so the real system keyboard remains visible below this workspace.
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
        let all = filter == 1
            ? LabTool.allCases.filter { pinned.contains($0.rawValue) }
            : LabTool.allCases
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? all : all.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.detail.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Button(action: onClose) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 39, height: 39)
                        .background(LabDesign.card, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to keyboard")

                VStack(alignment: .leading, spacing: 3) {
                    Text("Keyboard Lab")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                    Text("Your tools, right where you type")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 37, height: 37)
                    .background(accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 13))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(height: 61)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                LabEditableField(
                    id: "launcher.search",
                    placeholder: "Search tools",
                    text: $search,
                    minHeight: 37
                )
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 26, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear tool search")
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 9)

            HStack(spacing: 10) {
                Picker("Tool filter", selection: $filter) {
                    Text("All tools").tag(0)
                    Text("Favorites").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)

                Spacer(minLength: 5)
                Text("\(visible.count) TOOLS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 12)

            ScrollView {
                if visible.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: filter == 1 ? "star" : "magnifyingglass")
                            .font(.system(size: 26))
                            .foregroundStyle(accent)
                        Text(filter == 1 && search.isEmpty
                            ? "No favorites yet"
                            : "No matching tools")
                            .font(.system(size: 14, weight: .semibold))
                        Text(filter == 1 && search.isEmpty
                            ? "Long press any tool to add it here."
                            : "Try a different search.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 44)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 138, maximum: 230), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(visible) { tool in
                            LabAnimatedTile(
                                title: tool.title,
                                detail: tool.detail,
                                symbol: tool.symbol,
                                tint: tool.tint
                            ) {
                                onSelect(tool)
                            }
                            .contextMenu {
                                Button {
                                    onSelect(tool)
                                } label: {
                                    Label("Open " + tool.title,
                                          systemImage: "arrow.up.right.square")
                                }
                                Button {
                                    toggleFavorite(tool)
                                } label: {
                                    Label(
                                        pinned.contains(tool.rawValue)
                                            ? "Remove from Favorites" : "Add to Favorites",
                                        systemImage: pinned.contains(tool.rawValue)
                                            ? "star.slash" : "star"
                                    )
                                }
                            } preview: {
                                LabToolPreview(tool: tool,
                                               isFavorite: pinned.contains(tool.rawValue))
                            }
                            .accessibilityHint("Long press to preview and manage favorites")
                        }
                    }
                    .padding(.horizontal, 13)
                    .padding(.bottom, 14)
                }
            }
            .scrollIndicators(.hidden)
            .introspect(.scrollView, on: .iOS(.v17, .v18, .v26, .v27)) { scroll in
                scroll.bounces = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [
                    accent.opacity(0.055),
                    LabDesign.canvas,
                    LabDesign.canvas
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .sensoryFeedback(.selection, trigger: pinnedIDs)
    }

    private func toggleFavorite(_ tool: LabTool) {
        var ids = pinnedIDs.split(separator: ",").map(String.init)
        if ids.contains(tool.rawValue) {
            ids.removeAll { $0 == tool.rawValue }
        } else {
            // Match the six-shortcut limit in the Profiles panel.
            if ids.count >= 6 {
                ids.removeFirst()
            }
            ids.append(tool.rawValue)
        }
        pinnedIDs = ids.joined(separator: ",")
    }
}

struct LabQuickAccess: View {
    let open: (LabTool) -> Void
    let showAll: () -> Void

    @AppStorage("keyboard.lab.favorites") private var pinnedIDs =
        "sefaria,wikipedia,clipboard,textFX,calculator,templates"
    @AppStorage("keyboard.lab.theme") private var themeName = LabTheme.classic.rawValue

    private var favorites: [LabTool] {
        let ids = pinnedIDs.split(separator: ",").map(String.init)
        let tools = ids.compactMap(LabTool.init(rawValue:))
        return tools.isEmpty ? LabTool.favorites : Array(tools.prefix(6))
    }

    private var accent: Color { LabDesign.accent(themeName) }

    var body: some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(accent.opacity(0.11),
                                in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Quick access")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("Your favorite shortcuts")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(action: showAll) {
                    HStack(spacing: 5) {
                        Text("All tools")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .frame(height: 33)
                    .background(accent.opacity(0.11),
                                in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 15)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 118, maximum: 210), spacing: 9)],
                spacing: 9
            ) {
                ForEach(favorites) { tool in
                    Button {
                        open(tool)
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: tool.symbol)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(tool.tint)
                                .frame(width: 29, height: 29)
                                .background(tool.tint.opacity(0.11),
                                            in: RoundedRectangle(cornerRadius: 9))
                            Text(tool.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 9)
                        .frame(height: 46)
                        .background(LabDesign.card, in: RoundedRectangle(cornerRadius: 13))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .strokeBorder(LabDesign.stroke, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            open(tool)
                        } label: {
                            Label("Open " + tool.title,
                                  systemImage: "arrow.up.right.square")
                        }
                        Button {
                            let items = pinnedIDs.split(separator: ",").map(String.init)
                            pinnedIDs = items.filter { $0 != tool.rawValue }
                                .joined(separator: ",")
                        } label: {
                            Label("Remove Favorite", systemImage: "star.slash")
                        }
                    } preview: {
                        LabToolPreview(tool: tool, isFavorite: true)
                    }
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
    }
}
