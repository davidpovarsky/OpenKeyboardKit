import SwiftUI
import UIKit

private enum LabStudio {
    static let canvas = Color(red: 0.055, green: 0.072, blue: 0.096)
    static let surface = Color(red: 0.102, green: 0.124, blue: 0.157)
    static let elevated = Color(red: 0.142, green: 0.169, blue: 0.206)
    static let mint = Color(red: 0.71, green: 0.96, blue: 0.80)
    static let lilac = Color(red: 0.75, green: 0.74, blue: 1)
    static let secondary = Color(red: 0.64, green: 0.69, blue: 0.75)
}

private enum StudioDestination: String, CaseIterable, Identifiable {
    case home = "Discover"
    case tools = "Tools"
    case tryIt = "Playground"
    case setup = "Setup"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .home: "square.grid.2x2"
        case .tools: "square.stack.3d.up"
        case .tryIt: "text.cursor"
        case .setup: "slider.horizontal.3"
        }
    }
}

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
    @State private var selection: StudioDestination = .home
    @State private var search = ""

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tools: [ShowcaseTool] = [
        .init(title: "Sefaria", subtitle: "Explore original Jewish texts", symbol: "books.vertical", tint: LabStudio.lilac),
        .init(title: "Wikipedia", subtitle: "Knowledge without leaving your keyboard", symbol: "globe.europe.africa", tint: .cyan),
        .init(title: "Translate", subtitle: "Translate Hebrew and English", symbol: "character.bubble", tint: LabStudio.mint),
        .init(title: "Clipboard", subtitle: "Keep useful clips close", symbol: "doc.on.clipboard", tint: .teal),
        .init(title: "Text FX", subtitle: "Refine, clean, and transform text", symbol: "textformat", tint: LabStudio.lilac),
        .init(title: "Dictionary", subtitle: "A definition when you need one", symbol: "text.book.closed", tint: .orange),
        .init(title: "Calculator", subtitle: "Answers in a few taps", symbol: "plus.forwardslash.minus", tint: LabStudio.mint),
        .init(title: "Conversion", subtitle: "Units and numbers, simplified", symbol: "arrow.left.arrow.right", tint: .cyan),
        .init(title: "Notepad", subtitle: "Catch a thought instantly", symbol: "note.text", tint: .yellow),
        .init(title: "Handwriting", subtitle: "Make space for Apple Pencil", symbol: "pencil.tip", tint: .orange),
        .init(title: "Photos & Files", subtitle: "Bring media into the flow", symbol: "photo.on.rectangle", tint: .cyan),
        .init(title: "GIF Gallery", subtitle: "Find the right reaction", symbol: "play.rectangle", tint: LabStudio.lilac),
        .init(title: "Script Studio", subtitle: "Your own JavaScript-powered tools", symbol: "curlybraces.square", tint: LabStudio.mint)
    ]

    private var matchingTools: [ShowcaseTool] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return tools }
        return tools.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(spacing: 0) {
                    sidebar
                    Rectangle().fill(.white.opacity(0.07)).frame(width: 1)
                    destination(selection)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                TabView(selection: $selection) {
                    destination(.home)
                        .tabItem { Label("Discover", systemImage: "square.grid.2x2") }
                        .tag(StudioDestination.home)
                    destination(.tools)
                        .tabItem { Label("Tools", systemImage: "square.stack.3d.up") }
                        .tag(StudioDestination.tools)
                    destination(.tryIt)
                        .tabItem { Label("Try", systemImage: "text.cursor") }
                        .tag(StudioDestination.tryIt)
                    destination(.setup)
                        .tabItem { Label("Setup", systemImage: "slider.horizontal.3") }
                        .tag(StudioDestination.setup)
                }
            }
        }
        .background(LabStudio.canvas.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .tint(LabStudio.mint)
        .sheet(item: $activeTool) { tool in
            NavigationStack {
                toolDetail(tool)
                    .navigationTitle(tool.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { activeTool = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 28) {
            brand
                .padding(.top, 26)
                .padding(.horizontal, 22)

            VStack(spacing: 7) {
                ForEach(StudioDestination.allCases) { section in
                    Button {
                        navigate(to: section)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: section.symbol)
                                .font(.system(size: 18))
                                .frame(width: 24)
                            Text(section.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            if selection == section {
                                Circle().fill(LabStudio.mint).frame(width: 6, height: 6)
                            }
                        }
                        .foregroundStyle(selection == section ? LabStudio.mint : LabStudio.secondary)
                        .padding(.horizontal, 15)
                        .frame(height: 48)
                        .background(
                            selection == section ? LabStudio.mint.opacity(0.12) : .clear,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == section ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 20)

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(LabStudio.mint)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your workspace")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Personal tools, right where you type.")
                        .font(.system(size: 11))
                        .foregroundStyle(LabStudio.secondary)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 17))
            .padding(.horizontal, 14)
            .padding(.bottom, 22)
        }
        .frame(width: 252)
        .background(LabStudio.canvas)
    }

    private var brand: some View {
        HStack(spacing: 11) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LabStudio.canvas)
                .frame(width: 40, height: 40)
                .background(LabStudio.mint, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text("KEYBOARD")
                    .tracking(1.6)
                    .foregroundStyle(.white)
                Text("LAB")
                    .tracking(4)
                    .foregroundStyle(LabStudio.mint)
            }
            .font(.system(size: 11, weight: .heavy, design: .rounded))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func destination(_ section: StudioDestination) -> some View {
        switch section {
        case .home: overview
        case .tools: toolLibrary
        case .tryIt: playground
        case .setup: setup
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    brand
                    Spacer()
                    Image(systemName: "sparkle")
                        .font(.system(size: 18))
                        .foregroundStyle(LabStudio.mint)
                        .frame(width: 39, height: 39)
                        .background(LabStudio.surface, in: Circle())
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 11) {
                    Text("MEET YOUR NEW SUPERPOWER")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2.1)
                        .foregroundStyle(LabStudio.mint)
                    (Text("A world of tools.\n").foregroundColor(.white)
                        + Text("One keyboard.").foregroundColor(LabStudio.mint))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .tracking(-1.8)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                    Text("Research, write, create and automate — without breaking your flow.")
                        .font(.system(size: 15))
                        .foregroundStyle(LabStudio.secondary)
                        .lineSpacing(4)
                }

                preview
                Button {
                    navigate(to: .tryIt)
                } label: {
                    HStack {
                        Text("Try it for yourself")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LabStudio.canvas)
                    .frame(height: 54)
                    .padding(.horizontal, 19)
                    .background(LabStudio.mint, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(LabPressedButton())
                .accessibilityHint("Opens a real text field where you can test your installed keyboard")

                HStack(spacing: 12) {
                    feature(icon: "square.stack.3d.up", title: "Power tools",
                            subtitle: "Explore what is possible", color: LabStudio.lilac, target: .tools)
                    feature(icon: "slider.horizontal.3", title: "Make it yours",
                            subtitle: "Get set up in minutes", color: LabStudio.mint, target: .setup)
                }
            }
            .frame(maxWidth: 780)
            .padding(.horizontal, 23)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
        }
        .background(LabStudio.canvas.ignoresSafeArea())
    }

    private var preview: some View {
        VStack(spacing: 0) {
            HStack {
                Label("YOUR WORKSPACE", systemImage: "circle.grid.2x2")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                Spacer()
                Text("PREVIEW")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(LabStudio.mint)
            }
            .foregroundStyle(LabStudio.secondary)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            HStack(spacing: 9) {
                Image(systemName: "sparkles")
                    .foregroundStyle(LabStudio.mint)
                Text("Everything you need, where you type")
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer(minLength: 0)
                Image(systemName: "ellipsis")
                    .foregroundStyle(LabStudio.secondary)
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(14)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
            .padding(.horizontal, 15)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(tools.prefix(6))) { tool in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(tool.tint)
                            .frame(width: 37, height: 37)
                            .background(tool.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        Text(tool.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, minHeight: 77, alignment: .leading)
                    .padding(12)
                    .background(LabStudio.elevated, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(15)
            .accessibilityLabel("Illustration of six keyboard tools")
            .accessibilityElement(children: .ignore)
        }
        .background(
            LinearGradient(colors: [LabStudio.surface, LabStudio.canvas],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 23)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 23)
                .strokeBorder(.white.opacity(0.09), lineWidth: 1)
        }
    }

    private func feature(
        icon: String, title: String, subtitle: String,
        color: Color, target: StudioDestination
    ) -> some View {
        Button {
            navigate(to: target)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(LabStudio.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(LabPressedButton())
    }

    private var toolLibrary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                pageHeader(
                    eyebrow: "YOUR CREATIVE TOOLBOX",
                    title: "Think it. Type it.",
                    description: "Explore the tools built into Keyboard Lab. Open them from the keyboard wherever you write."
                )
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LabStudio.secondary)
                    TextField("Find a tool", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .tint(LabStudio.mint)
                    if !search.isEmpty {
                        Button {
                            search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(LabStudio.secondary)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(16)
                .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 15))

                if matchingTools.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 27))
                        Text("No matching tools")
                            .font(.headline)
                        Text("Try searching for a different name.")
                            .font(.subheadline)
                    }
                    .foregroundStyle(LabStudio.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 148, maximum: 230), spacing: 12)],
                              spacing: 12) {
                        ForEach(matchingTools) { tool in
                            Button { activeTool = tool } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: tool.symbol)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(tool.tint)
                                        .frame(width: 45, height: 45)
                                        .background(tool.tint.opacity(0.13),
                                                    in: RoundedRectangle(cornerRadius: 14))
                                    Text(tool.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(tool.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundStyle(LabStudio.secondary)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
                                .padding(16)
                                .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 19))
                            }
                            .buttonStyle(LabPressedButton())
                        }
                    }
                }
            }
            .frame(maxWidth: 780)
            .padding(23)
            .frame(maxWidth: .infinity)
        }
        .background(LabStudio.canvas.ignoresSafeArea())
    }

    private var playground: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                pageHeader(
                    eyebrow: "THE PLAYGROUND",
                    title: "Give it a try.",
                    description: "An actual text field. Switch to Keyboard Lab with the globe key, then open Tools to explore."
                )
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("YOUR SPACE", systemImage: "text.alignleft")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(LabStudio.mint)
                        Spacer()
                        Text("\(sampleText.count) CHARACTERS")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(LabStudio.secondary)
                    }
                    TextEditor(text: $sampleText)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .frame(minHeight: 230)
                        .tint(LabStudio.mint)
                        .accessibilityLabel("Try the keyboard")
                    HStack {
                        Text("Ideas start here.")
                            .font(.system(size: 12))
                            .foregroundStyle(LabStudio.secondary)
                        Spacer()
                        Button {
                            sampleText = ""
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .disabled(sampleText.isEmpty)
                    }
                }
                .padding(19)
                .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 22))

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(LabStudio.mint)
                    Text("Enable Keyboard Lab in iOS Settings first. If it does not appear, press and hold the globe key. Some applications and secure fields restrict third-party keyboards.")
                        .font(.system(size: 12))
                        .foregroundStyle(LabStudio.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(17)
                .background(LabStudio.elevated.opacity(0.55),
                            in: RoundedRectangle(cornerRadius: 17))
            }
            .frame(maxWidth: 780)
            .padding(23)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LabStudio.canvas.ignoresSafeArea())
    }

    private var setup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                pageHeader(
                    eyebrow: "GET STARTED",
                    title: "Make it yours.",
                    description: "Just a few steps and your new keyboard will be ready throughout iOS."
                )

                HStack(spacing: 12) {
                    Image(systemName: keyboardExtensionIsEmbedded ?
                          "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(keyboardExtensionIsEmbedded ?
                                         LabStudio.mint : .orange)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(keyboardExtensionIsEmbedded ?
                             "Keyboard extension detected" : "Keyboard extension not found")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(keyboardExtensionIsEmbedded ?
                             "Your app bundle includes Keyboard Lab." :
                             "Reinstall the app with its embedded extension.")
                            .font(.system(size: 12))
                            .foregroundStyle(LabStudio.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 11) {
                    setupStep(1, title: "Add your keyboard",
                              detail: "Settings → General → Keyboard → Keyboards → Add New Keyboard → Keyboard Lab.",
                              symbol: "keyboard")
                    setupStep(2, title: "Switch to Keyboard Lab",
                              detail: "Open a text field, then press and hold the globe key to select Keyboard Lab.",
                              symbol: "globe")
                    setupStep(3, title: "Unlock live tools",
                              detail: "For network tools, allow Full Access in keyboard settings and turn Network On in Script Studio.",
                              symbol: "network")
                }

                Button {
                    navigate(to: .tryIt)
                } label: {
                    HStack {
                        Text("Open the playground")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LabStudio.canvas)
                    .padding(.horizontal, 18)
                    .frame(height: 51)
                    .background(LabStudio.mint,
                                in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(LabPressedButton())

                VStack(alignment: .leading, spacing: 9) {
                    Label("Privacy & compatibility", systemImage: "hand.raised")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Saved clips, notes and snippets stay local. Clipboard capture is manual. Live services only access the network after you give Full Access and explicitly enable network features. Some system pickers are limited in keyboard extensions.")
                        .font(.system(size: 12))
                        .foregroundStyle(LabStudio.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(destination: URL(string: "https://github.com/davidpovarsky/OpenKeyboardKit")!) {
                        Label("View open source project", systemImage: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LabStudio.mint)
                    }
                }
                .padding(18)
                .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 19))
            }
            .frame(maxWidth: 780)
            .padding(23)
            .frame(maxWidth: .infinity)
        }
        .background(LabStudio.canvas.ignoresSafeArea())
    }

    private func setupStep(_ number: Int, title: String, detail: String,
                           symbol: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(LabStudio.canvas)
                .frame(width: 34, height: 34)
                .background(LabStudio.mint, in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .foregroundStyle(LabStudio.lilac)
                    Text(title).foregroundStyle(.white)
                }
                .font(.system(size: 14, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(LabStudio.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LabStudio.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func pageHeader(eyebrow: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            brand.padding(.bottom, 14)
            Text(eyebrow)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(LabStudio.mint)
            Text(title)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .tracking(-1.6)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.75)
                .accessibilityAddTraits(.isHeader)
            Text(description)
                .font(.system(size: 14))
                .foregroundStyle(LabStudio.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func toolDetail(_ tool: ShowcaseTool) -> some View {
        VStack(spacing: 15) {
            Image(systemName: tool.symbol)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(tool.tint)
                .frame(width: 84, height: 84)
                .background(tool.tint.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 25))
            Text(tool.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(tool.subtitle)
                .font(.system(size: 14))
                .foregroundStyle(LabStudio.secondary)
            Text("Open Keyboard Lab inside any text field, then choose Tools → \(tool.title).")
                .font(.system(size: 14))
                .foregroundStyle(LabStudio.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
            Spacer(minLength: 0)
        }
        .padding(.top, 37)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LabStudio.canvas.ignoresSafeArea())
    }

    private func navigate(to newValue: StudioDestination) {
        if reduceMotion {
            selection = newValue
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = newValue
            }
        }
    }

    private var keyboardExtensionIsEmbedded: Bool {
        guard let plugIns = Bundle.main.builtInPlugInsURL else { return false }
        return FileManager.default.fileExists(
            atPath: plugIns.appendingPathComponent("TrialKeyboardExtension.appex").path
        )
    }
}

private struct LabPressedButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
