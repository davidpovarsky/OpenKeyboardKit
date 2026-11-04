import Foundation

struct KeyboardScript: Identifiable, Codable {
    var id: String
    var title: String
    var detail: String
    var symbol: String
    var source: String
    var isBuiltIn: Bool
}

enum ScriptLibrary {
    static let scripts: [KeyboardScript] = [
        .init(id: "wikipedia", title: "Wikipedia", detail: "Live Hebrew Wikipedia search", symbol: "globe", source: """
            const ctx = native.context().trim();
            const query = ctx.split(/[\\n.!?]/).pop().trim().slice(-65) || "ירושלים";
            native.ui({ title: "ויקיפדיה", message: "מחפש: " + query, rows: [] });
            const url = "https://he.wikipedia.org/w/api.php?action=opensearch&format=json&limit=7&search=" + encodeURIComponent(query);
            native.fetch(url, (error, body) => {
              if (error) { native.ui({ title: "ויקיפדיה", message: error, rows: [] }); return; }
              try {
                const data = JSON.parse(body);
                const words = data[1] || [];
                const summaries = data[2] || [];
                native.ui({
                  title: "ויקיפדיה",
                  message: words.length ? "תוצאות חיפוש עבור: " + query : "לא נמצאו תוצאות",
                  rows: words.map((word, i) => ({
                    title: word, detail: summaries[i] || "הקש להוסיף את הכותרת", insert: word
                  }))
                });
              } catch (e) { native.log("Wikipedia: " + e); }
            });
            """, isBuiltIn: true),
        .init(id: "sefaria", title: "Sefaria", detail: "Fetch Hebrew sources over HTTPS", symbol: "book.closed", source: """
            const raw = native.context().trim();
            const match = raw.match(/[A-Za-z_]+[.]\\d+([.]\\d+)?$/);
            const ref = match ? match[0] : "Pirkei_Avot.1.1";
            native.ui({ title: "ספריא", message: "טוען " + ref + "...", rows: [] });
            const url = "https://www.sefaria.org/api/texts/" + encodeURIComponent(ref) + "?lang=he";
            native.fetch(url, (error, body) => {
              if (error) { native.ui({ title: "ספריא", message: error, rows: [] }); return; }
              try {
                const json = JSON.parse(body);
                const flatten = value => Array.isArray(value) ? value.map(flatten).join(" ") : String(value ?? "");
                const text = flatten(json.he || json.text || "").replace(/<[^>]*>/g, "").trim();
                native.ui({
                  title: json.ref || ref,
                  message: text ? "הקש על השורה כדי להכניס את הטקסט" : (json.error || "לא נמצא טקסט במקור"),
                  rows: text ? [{ title: text.slice(0, 145), detail: "הוסף טקסט מקור", insert: text }] : []
                });
              } catch (e) { native.log("Sefaria: " + e); }
            });
            """, isBuiltIn: true),
        .init(id: "json", title: "Format JSON", detail: "Format JSON before the cursor", symbol: "curlybraces", source: """
            const input = native.context().trim();
            try {
              const parsed = JSON.parse(input || '{"message":"Hello from JavaScriptCore","enabled":true,"count":3}');
              const formatted = JSON.stringify(parsed, null, 2);
              native.ui({
                title: "JSON Formatter",
                message: "JavaScriptCore formatted the JSON successfully.",
                rows: [{ title: formatted.slice(0, 250), detail: "הוסף JSON מעוצב", insert: formatted }]
              });
            } catch (e) {
              native.ui({ title: "JSON Formatter", message: "JSON לא תקין: " + e.message, rows: [] });
            }
            """, isBuiltIn: true),
        .init(id: "sefaria-search", title: "Sefaria Search", detail: "Search sources via HTTPS POST", symbol: "books.vertical", source: """
            const context = native.context().trim();
            const query = context.split(/[\\n.!?]/).pop().trim().slice(-70) || "שמע ישראל";
            native.ui({ title: "ספריא · חיפוש", message: "מחפש: " + query, rows: [] });
            native.request({
              url: "https://www.sefaria.org/api/search-wrapper",
              method: "POST",
              body: JSON.stringify({
                query: query, type: "text", field: "naive_lemmatizer", size: 8
              })
            }, (error, body) => {
              if (error) { native.ui({title:"Sefaria", message:error, rows:[]}); return; }
              try {
                const data = JSON.parse(body);
                const hits = (data.hits && data.hits.hits) || [];
                native.ui({
                  title: "Sefaria",
                  message: hits.length + " results for: " + query,
                  rows: hits.map((hit, i) => {
                    const source = hit._source || {};
                    const ref = source.ref || hit._id || "Result " + (i + 1);
                    const content = String(source.content || source.text || "")
                      .replace(/<[^>]*>/g, "").slice(0, 250);
                    return {title: ref, detail: content, insert: ref + " " + content};
                  })
                });
              } catch (e) { native.log("Could not parse Sefaria results: " + e); }
            });
            """, isBuiltIn: true),
        .init(id: "date", title: "Insert Date", detail: "Insert current date directly into the host text field", symbol: "calendar", source: """
            const date = new Date().toLocaleString("he-IL");
            native.insert(date);
            native.ui({ title: "תאריך ושעה", message: "הוכנס: " + date, rows: [] });
            """, isBuiltIn: true),
        .init(id: "demo", title: "SwiftUI Widgets", detail: "A native list created by JavaScript", symbol: "square.grid.2x2", source: """
            native.ui({
              title: "SwiftUI Form",
              message: "JavaScript configures a native SwiftUI form with fields and buttons.",
              fields: [
                {id: "name", title: "Name", placeholder: "Type a name"}
              ],
              buttons: [
                {id: "greet", title: "Insert greeting", symbol: "heart"}
              ],
              rows: [
                {title: "Shortcut", detail: "A normal native list row", insert: "Hello world"}
              ]
            });
            native.onAction = (id, values) => {
              if (id === "greet") {
                native.insert("שלום " + (values.name || "חבר") + "!");
              }
            };
            """, isBuiltIn: true)
    ]
}

struct ScriptRow: Codable, Identifiable {
    let title: String
    var detail: String?
    var insert: String?
    var id: String { title + (insert ?? "") }
}

struct ScriptPanel: Codable {
    var title: String
    var message: String?
    var rows: [ScriptRow]?
    var fields: [ScriptField]?
    var buttons: [ScriptButton]?
}

struct ScriptField: Codable, Identifiable {
    let id: String
    var title: String?
    var placeholder: String?
    var value: String?
}

struct ScriptButton: Codable, Identifiable {
    let id: String
    var title: String
    var symbol: String?
    var insert: String?
}
