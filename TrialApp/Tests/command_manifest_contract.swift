import Foundation

/// Run on Windows with the installed Swift toolchain or macOS CI:
/// swiftc ScriptLibrary.swift LabCommandManifest.swift command_manifest_contract.swift -o manifest-test
@main
struct CommandManifestContractTests {
    static func main() throws {
        // A pre-v0.9 script saved in UserDefaults must still decode normally.
        let old = """
        {"id":"old-script","title":"Legacy","detail":"Legacy script",
         "symbol":"curlybraces","source":"native.ui({title: 'OK'});",
         "isBuiltIn":false}
        """
        let legacy = try JSONDecoder().decode(
            KeyboardScript.self, from: Data(old.utf8)
        )
        precondition(legacy.manifest == nil)
        precondition(legacy.commandManifest.action.symbol == "play.fill")
        precondition(legacy.commandManifest.input.required == false)

        let source = """
        // @keyboard-manifest {"input":{"placeholder":"Query","required":true},"action":{"title":"Search","symbol":"magnifyingglass"},"permissions":["network"],"result":"inlineList"}
        native.ui({title:"OK", rows:[]});
        """
        let parsed = LabCommandManifest.parse(from: source)
        precondition(parsed != nil)
        precondition(parsed?.input.placeholder == "Query")
        precondition(parsed?.input.maxLength == 4000)
        precondition(parsed?.action.symbol == "magnifyingglass")
        precondition(parsed?.permissions == ["network"])
        precondition(parsed?.result == .inlineList)

        let serialized = try JSONEncoder().encode(parsed)
        let reloaded = try JSONDecoder().decode(LabCommandManifest.self, from: serialized)
        precondition(reloaded == parsed)
        precondition(LabCommandManifest.parse(from: "// @keyboard-manifest {broken") == nil)

        var hostile = reloaded
        hostile.input.maxLength = 999999
        hostile.input.placeholder = String(repeating: "x", count: 1000)
        hostile.permissions = ["camera", "network", "clipboard", "all-files"]
        let safe = hostile.validated()
        precondition(safe.input.maxLength == 4000)
        precondition(safe.input.placeholder.count == 120)
        precondition(safe.permissions == ["network", "clipboard"])

        let sefaria = LabCommandManifest.defaults(for: "sefaria-search", title: "Sefaria")
        precondition(sefaria.permissions.contains("network"))
        precondition(sefaria.action.symbol == "magnifyingglass")
        let date = LabCommandManifest.defaults(for: "date", title: "Date")
        precondition(date.input.required == false)

        print("PASS: legacy script decoding, manifest defaults, custom directives,")
        print("      input bounds, permissions, Codable roundtrip and built-in presets.")
    }
}
