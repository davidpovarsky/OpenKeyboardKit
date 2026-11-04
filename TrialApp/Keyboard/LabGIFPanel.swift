import SwiftUI
import UniformTypeIdentifiers
import UIKit

private struct CommonsGIF: Identifiable {
    let id: Int
    let title: String
    let sourceURL: URL
    let previewURL: URL
}

@MainActor
private final class GIFSearchState: ObservableObject {
    @Published var images: [CommonsGIF] = []
    @Published var notice = ""
    @Published var loading = false
    private var task: Task<Void, Never>?

    func search(_ phrase: String) {
        task?.cancel()
        let term = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { notice = "Enter a search term."; return }
        images = []
        notice = "Searching Wikimedia Commons..."
        loading = true

        task = Task { [weak self] in
            guard let self else { return }
            do {
                var c = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
                c.queryItems = [
                    .init(name: "action", value: "query"),
                    .init(name: "format", value: "json"),
                    .init(name: "generator", value: "search"),
                    .init(name: "gsrnamespace", value: "6"),
                    .init(name: "gsrsearch", value: "filetype:gif " + term),
                    .init(name: "gsrlimit", value: "12"),
                    .init(name: "prop", value: "imageinfo"),
                    .init(name: "iiprop", value: "url|mime|size"),
                    .init(name: "iiurlwidth", value: "220")
                ]
                var req = URLRequest(url: c.url!)
                req.timeoutInterval = 18
                let (data, response) = try await URLSession.shared.data(for: req)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode), data.count < 2_000_000,
                      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let query = json["query"] as? [String: Any],
                      let pages = query["pages"] as? [String: [String: Any]] else {
                    self.notice = "No GIF results."
                    self.loading = false
                    return
                }
                var values: [CommonsGIF] = []
                for (_, item) in pages {
                    guard let pageid = item["pageid"] as? Int,
                          let info = (item["imageinfo"] as? [[String: Any]])?.first,
                          info["mime"] as? String == "image/gif",
                          let source = info["url"] as? String,
                          let url = URL(string: source),
                          let preview = URL(string: info["thumburl"] as? String ?? source) else { continue }
                    let title = (item["title"] as? String ?? "").replacingOccurrences(of: "File:", with: "")
                    values.append(.init(id: pageid, title: title, sourceURL: url, previewURL: preview))
                }
                self.images = values.sorted { $0.title < $1.title }
                self.notice = values.isEmpty ? "No GIFs found." : "\(values.count) GIFs from Wikimedia Commons"
            } catch is CancellationError {
                return
            } catch {
                self.notice = error.localizedDescription
            }
            self.loading = false
        }
    }

    func cancel() { task?.cancel() }
}

struct LabGIFPanel: View {
    let fullAccess: Bool
    let networkAllowed: Bool

    @StateObject private var model = GIFSearchState()
    @State private var query = ""
    @State private var isCopying = false
    @State private var status = ""

    private var ready: Bool { fullAccess && networkAllowed }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                LabNativeSearchBar(
                    id: "gif.query",
                    text: $query,
                    placeholder: "Search animated GIFs",
                    onSubmit: { if ready { model.search(query) } }
                )
                Button {
                    if ready { model.search(query) }
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!ready || query.isEmpty)
            }
            .frame(height: 50)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            if !ready {
                Text("Enable Full Access and Network On to search the public GIF library.")
                    .font(.caption2).foregroundStyle(.orange)
            }

            HStack {
                Text(isCopying ? "Copying GIF..." : (status.isEmpty ? model.notice : status))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if model.loading || isCopying { ProgressView().controlSize(.small) }
                Spacer()
            }
            .padding(.horizontal, 15)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(model.images) { item in
                        Button { copy(item) } label: {
                            VStack(spacing: 7) {
                                AsyncImage(url: item.previewURL) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 11)
                                        .fill(Color(uiColor: .tertiarySystemBackground))
                                        .overlay { ProgressView().controlSize(.mini) }
                                }
                                .frame(height: 90)
                                Text(item.title)
                                    .font(.caption2)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(uiColor: .tertiarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 13)
            }


        }
        .background(Color(uiColor: .secondarySystemBackground))
        .onDisappear { model.cancel() }
    }

    private func copy(_ item: CommonsGIF) {
        guard ready else { return }
        isCopying = true
        status = ""
        Task {
            do {
                var req = URLRequest(url: item.sourceURL)
                req.timeoutInterval = 20
                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      data.count < 4_000_000 else {
                    status = "GIF is too large or unavailable (4MB limit)."
                    isCopying = false
                    return
                }
                UIPasteboard.general.setData(data, forPasteboardType: UTType.gif.identifier)
                status = "GIF copied. Paste it into an app that accepts animated GIFs."
            } catch {
                status = error.localizedDescription
            }
            isCopying = false
        }
    }
}
