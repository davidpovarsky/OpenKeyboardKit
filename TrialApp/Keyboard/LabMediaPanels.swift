import SwiftUI
import UIKit
import PencilKit
import PhotosUI
import UniformTypeIdentifiers

/// The canvas is a native PencilKit view. Export uses the clipboard because
/// the iOS keyboard text proxy cannot attach arbitrary image files to hosts.
private struct PencilCanvas: UIViewRepresentable {
    let canvas: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .label, width: 3)
        canvas.backgroundColor = UIColor.secondarySystemBackground
        canvas.isOpaque = true
        return canvas
    }

    func updateUIView(_ view: PKCanvasView, context: Context) {}
}

struct LabHandwritingPanel: View {
    let insertText: (String) -> Void
    let fullAccess: Bool

    @State private var canvas = PKCanvasView()
    @State private var status = ""

    var body: some View {
        VStack(spacing: 11) {
            LabHint(text: "Draw with Apple Pencil or your finger. This does not perform handwriting recognition.", icon: "pencil.tip")
                .padding(.horizontal, 12)

            PencilCanvas(canvas: canvas)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 13))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 10) {
                Button("Clear") {
                    canvas.drawing = PKDrawing()
                    status = ""
                }
                .buttonStyle(.bordered)

                Button {
                    guard fullAccess else {
                        status = "Full Access is required to copy the image."
                        return
                    }
                    let bounds = canvas.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 600, height: 280) : canvas.bounds
                    let image = canvas.drawing.image(from: bounds, scale: 2)
                    UIPasteboard.general.image = image
                    status = "Drawing copied. Paste it in an app that supports images."
                } label: {
                    Label("Copy image", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(.horizontal, 14)

            Text(status)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.bottom, 9)
        }
    }
}

struct LabMediaPanel: View {
    let insertText: (String) -> Void
    let fullAccess: Bool

    @State private var photo: PhotosPickerItem?
    @State private var showFiles = false
    @State private var status = "Select a photo or file to continue."

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabHint(text: "Native Apple photo and document pickers. Picking an item grants access only to that selection.", icon: "photo")

            PhotosPicker(selection: $photo, matching: .images) {
                Label("Choose photo", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color.blue.opacity(0.11),
                                in: RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .onChange(of: photo) { value in
                Task {
                    guard let value else { return }
                    do {
                        guard let data = try await value.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            status = "Photo could not be loaded."
                            return
                        }
                        guard fullAccess else {
                            status = "Enable Full Access to copy a selected photo."
                            return
                        }
                        UIPasteboard.general.image = image
                        status = "Photo copied to clipboard. Paste into a compatible app."
                    } catch {
                        status = error.localizedDescription
                    }
                }
            }

            Button { showFiles = true } label: {
                Label("Choose document", systemImage: "folder")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color.green.opacity(0.11),
                                in: RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .fileImporter(isPresented: $showFiles, allowedContentTypes: [.item]) { result in
                switch result {
                case .success(let url):
                    status = "Selected: \(url.lastPathComponent)"
                    insertText(url.lastPathComponent)
                case .failure(let error):
                    status = error.localizedDescription
                }
            }

            LabHint(text: "Keyboard extensions cannot directly attach files or photos to other apps. Images are copied only after an explicit choice; filenames can be inserted as text.")
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct LabTranslatePanel: View {
    let readContext: () -> String
    let insertText: (String) -> Void
    let fullAccess: Bool
    let networkAllowed: Bool

    @State private var input = ""
    @State private var output = ""
    @State private var sourceLanguage = "he"
    @State private var targetLanguage = "en"
    @State private var isLoading = false
    @State private var consent = false
    @State private var status = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Text(sourceLanguage == "he" ? "🇮🇱 Hebrew" : "🇬🇧 English")
                Spacer()
                Button {
                    let previous = sourceLanguage
                    sourceLanguage = targetLanguage
                    targetLanguage = previous
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .buttonStyle(.bordered)
                Spacer()
                Text(targetLanguage == "he" ? "🇮🇱 Hebrew" : "🇬🇧 English")
            }
            .font(.subheadline.weight(.semibold))

            TextEditor(text: $input)
                .frame(minHeight: 94)
                .padding(8)
                .background(Color(uiColor: .tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14))

            HStack {
                Button("From cursor") { input = LabText.clip(readContext(), limit: 450) }
                    .buttonStyle(.bordered)
                Button("Paste") {
                    if fullAccess {
                        input = LabText.clip(UIPasteboard.general.string ?? "", limit: 450)
                    }
                }
                .disabled(!fullAccess)
                .buttonStyle(.bordered)
            }

            Toggle("Send this text to a translation service", isOn: $consent)
                .font(.caption)

            LabHint(text: "Experimental translation uses MyMemory's public API. It sends the text only after you tap Translate and opt in. Rate limits and service availability may vary.", icon: "network")

            Button(action: translate) {
                HStack {
                    if isLoading { ProgressView().controlSize(.small) }
                    Text("Translate")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!fullAccess || !networkAllowed || !consent ||
                      input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)

            if !fullAccess || !networkAllowed {
                LabHint(text: "Enable Full Access and Network On in Script Studio.")
            }

            if !status.isEmpty {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }

            if !output.isEmpty {
                Text(output)
                    .font(.system(size: 15))
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .tertiarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 14))
                LabActionButton(text: "Insert translation", icon: "text.insert") {
                    insertText(output)
                }
            }
        }
    }

    private func translate() {
        let clipped = LabText.clip(input, limit: 450)
        guard fullAccess, networkAllowed, consent,
              !clipped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        status = "Translating..."
        output = ""

        let pair = sourceLanguage + "|" + targetLanguage
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            URLQueryItem(name: "q", value: clipped),
            URLQueryItem(name: "langpair", value: pair)
        ]
        Task {
            do {
                var request = URLRequest(url: components.url!)
                request.timeoutInterval = 17
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                      data.count < 250_000,
                      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let responseData = json["responseData"] as? [String: Any],
                      let translated = responseData["translatedText"] as? String else {
                    status = "Translation service did not return a result."
                    isLoading = false
                    return
                }
                output = translated
                status = "Translation ready"
            } catch {
                status = error.localizedDescription
            }
            isLoading = false
        }
    }
}
