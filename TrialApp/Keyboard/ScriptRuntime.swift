import Foundation
import JavaScriptCore
import UIKit
import SwiftUI

@objc protocol KeyboardScriptChannel: JSExport {
    func send(_ message: String)
    func context() -> String
}

final class ScriptNativeChannel: NSObject, KeyboardScriptChannel {
    weak var model: ScriptStudioModel?
    var readContext: (() -> String)?

    func context() -> String {
        String((readContext?() ?? "").suffix(500))
    }

    func send(_ message: String) {
        if Thread.isMainThread {
            model?.handle(message)
        } else {
            DispatchQueue.main.async { [weak self] in self?.model?.handle(message) }
        }
    }
}

final class ScriptStudioModel: ObservableObject {
    @Published var panel: ScriptPanel?
    @Published var status = "בחר סקריפט"
    @Published var isLoading = false
    @Published var customScripts: [KeyboardScript] = []

    var canFetch = false
    var canReadClipboard = false
    var insertText: ((String) -> Void)?

    private var context: JSContext?
    private var bridge: ScriptNativeChannel?
    private var networkSession: URLSession = .init(configuration: .ephemeral)
    private var currentRun = UUID()
    private static let savedScriptsKey = "keyboard.trial.customScripts.v2"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.savedScriptsKey),
           let saved = try? JSONDecoder().decode([KeyboardScript].self, from: data) {
            customScripts = saved
        }
    }

    func run(_ script: KeyboardScript, readContext: @escaping () -> String, allowNetwork: Bool, allowClipboard: Bool, insert: @escaping (String) -> Void) {
        currentRun = UUID()
        networkSession.invalidateAndCancel()
        networkSession = .init(configuration: .ephemeral)
        canFetch = allowNetwork
        canReadClipboard = allowClipboard
        insertText = insert
        isLoading = false
        panel = nil
        status = "מריץ: " + script.title

        let channel = ScriptNativeChannel()
        channel.model = self
        channel.readContext = readContext
        bridge = channel

        guard let js = JSContext() else {
            status = "לא ניתן לאתחל JavaScriptCore"
            return
        }
        context = js
        js.exceptionHandler = { [weak self] _, value in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.status = "שגיאת JavaScript: " + (value?.toString() ?? "Unknown")
            }
        }
        js.setObject(channel, forKeyedSubscript: "__keyboardNative" as NSString)
        js.evaluateScript("""
            var __callbacks = Object.create(null);
            var __callbackIndex = 0;
            function __complete(id, error, response) {
              var cb = __callbacks[id];
              delete __callbacks[id];
              if (typeof cb === "function") cb(error, response);
            }
            var native = {
              ui: function(data) {
                __keyboardNative.send(JSON.stringify({type: "ui", data: data}));
              },
              log: function(message) {
                __keyboardNative.send(JSON.stringify({type: "log", value: String(message)}));
              },
              insert: function(value) {
                __keyboardNative.send(JSON.stringify({type: "insert", value: String(value)}));
              },
              copy: function(value) {
                __keyboardNative.send(JSON.stringify({type: "copy", value: String(value)}));
              },
              context: function() {
                return __keyboardNative.context();
              },
              fetch: function(url, callback) {
                var id = String(++__callbackIndex);
                __callbacks[id] = callback;
                __keyboardNative.send(JSON.stringify({type: "fetch", url: String(url), id: id}));
              }
            };
            """)
        js.evaluateScript(script.source)
    }

    func handle(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let dataObject = try? JSONSerialization.jsonObject(with: data),
              let command = dataObject as? [String: Any],
              let type = command["type"] as? String else {
            status = "שגיאת תקשורת עם סקריפט"
            return
        }

        switch type {
        case "ui":
            guard let value = command["data"],
                  JSONSerialization.isValidJSONObject(value),
                  let payload = try? JSONSerialization.data(withJSONObject: value),
                  let parsed = try? JSONDecoder().decode(ScriptPanel.self, from: payload) else {
                status = "סקריפט החזיר ממשק לא תקין"
                return
            }
            panel = parsed
            isLoading = false
            status = "תוצאות מוכנות"
        case "log":
            status = String((command["value"] as? String ?? "").prefix(500))
            isLoading = false
        case "insert":
            insertText?(command["value"] as? String ?? "")
            status = "הטקסט הוכנס"
        case "copy":
            guard canReadClipboard else { status = "יש להפעיל Full Access כדי להעתיק"; return }
            UIPasteboard.general.string = command["value"] as? String ?? ""
            status = "הועתק ללוח"
        case "fetch":
            let url = command["url"] as? String ?? ""
            let id = command["id"] as? String ?? ""
            fetch(url: url, callbackId: id)
        default:
            status = "פקודה לא מוכרת: " + type
        }
    }

    private func fetch(url: String, callbackId: String) {
        guard canFetch else {
            finish(id: callbackId, error: "הפעל Full Access והרשאת רשת במסך הסקריפטים", body: nil)
            return
        }
        guard let endpoint = URL(string: url),
              endpoint.scheme?.lowercased() == "https",
              endpoint.host != nil else {
            finish(id: callbackId, error: "נדרשת כתובת HTTPS תקינה", body: nil)
            return
        }
        isLoading = true
        status = "מבצע בקשת רשת..."
        let run = currentRun
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 18
        request.setValue("KeyboardTrial/0.2 (iOS)", forHTTPHeaderField: "User-Agent")
        networkSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self, self.currentRun == run else { return }
                self.isLoading = false
                if let error = error {
                    self.finish(id: callbackId, error: error.localizedDescription, body: nil)
                    return
                }
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200...299).contains(statusCode) else {
                    self.finish(id: callbackId, error: "HTTP " + String(statusCode), body: nil)
                    return
                }
                guard let data = data, data.count <= 2_000_000,
                      let body = String(data: data, encoding: .utf8) else {
                    self.finish(id: callbackId, error: "התשובה אינה טקסט UTF-8 או גדולה מ-2MB", body: nil)
                    return
                }
                self.finish(id: callbackId, error: nil, body: body)
            }
        }.resume()
    }

    private func finish(id: String, error: String?, body: String?) {
        let expression = "__complete(" + jsString(id) + "," + jsString(error) + "," + jsString(body) + ");"
        context?.evaluateScript(expression)
    }

    private func jsString(_ value: String?) -> String {
        guard let value = value else { return "null" }
        guard let data = try? JSONSerialization.data(withJSONObject: [value], options: [.fragmentsAllowed]),
              let text = String(data: data, encoding: .utf8) else { return "null" }
        return String(text.dropFirst().dropLast())
    }

    func installFromClipboard() {
        guard canReadClipboard else {
            status = "הפעל Full Access כדי לייבא מהלוח"
            return
        }
        guard let code = UIPasteboard.general.string, !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "לא נמצא קוד בלוח ההעתקות"
            return
        }
        guard code.utf8.count <= 50_000 else {
            status = "גודל הקובץ המרבי הוא 50KB"
            return
        }
        let first = code.components(separatedBy: .newlines).first ?? ""
        let name = first.hasPrefix("// @title ") ? String(first.dropFirst(10)).trimmingCharacters(in: .whitespaces) : "My JS " + String(customScripts.count + 1)
        customScripts.append(
            .init(id: UUID().uuidString, title: name, detail: "Imported from clipboard", symbol: "curlybraces", source: code, isBuiltIn: false)
        )
        persist()
        status = "הסקריפט נשמר במקלדת"
    }

    func delete(_ script: KeyboardScript) {
        guard !script.isBuiltIn else { return }
        customScripts.removeAll { $0.id == script.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(customScripts) {
            UserDefaults.standard.set(data, forKey: Self.savedScriptsKey)
        }
    }
}
