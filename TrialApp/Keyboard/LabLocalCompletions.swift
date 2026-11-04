import Foundation
import UIKit
import Combine

/// Offline keyboard suggestions. Never sends host text to a server.
/// UITextChecker provides Apple-supported completions for available languages;
/// the fallback list is intentionally small, not a claim of QuickType parity.
@MainActor
final class LabLocalCompletions: ObservableObject {
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var prefix = ""

    private let checker = UITextChecker()
    private let fallbackEnglish = [
        "about", "after", "again", "also", "because", "before", "between",
        "could", "design", "different", "document", "example", "family",
        "first", "from", "good", "great", "have", "hello", "help", "important",
        "information", "keyboard", "language", "more", "next", "people",
        "please", "project", "remember", "search", "should", "something",
        "support", "system", "there", "these", "this", "through", "today",
        "together", "tools", "typing", "understand", "very", "when", "where",
        "which", "with", "would", "write"
    ]
    private let fallbackHebrew = [
        "אנחנו", "אפשר", "אחרי", "אתה", "באמת", "בבקשה", "ביחד", "ביותר",
        "בוקר", "ברכה", "גדול", "דברים", "דוגמה", "הבאה", "היום", "הכול",
        "המשך", "העבודה", "הצלחה", "הקלדה", "הראשון", "השלמה", "התקנה",
        "התוצאה", "וידאו", "ויקיפדיה", "זה", "זמן", "חדש", "חשוב",
        "טוב", "ישראל", "ירושלים", "יכולים", "כדאי", "כלים",
        "כתיבה", "לבדוק", "להוסיף", "להקליד", "למקלדת", "לראות",
        "מחשב", "מקלדת", "מקורי", "משתמש", "נהדר", "נכון", "נראה",
        "ספריא", "עבודה", "עכשיו", "פשוט", "פתיחה", "צורה", "צריך",
        "קוד", "ראשון", "רכיבים", "רוצים", "שימוש", "שלום",
        "תודה", "תוכנית", "תוצאה"
    ]

    func refresh(contextBefore: String, hebrew: Bool) {
        let word = Self.partialWord(in: String(contextBefore.suffix(400)))
        guard word.count >= 2, word.count <= 28 else {
            prefix = ""
            suggestions = []
            return
        }
        let languagePrefix = hebrew ? "he" : "en"
        let language = UITextChecker.availableLanguages.first {
            $0 == languagePrefix ||
            $0.hasPrefix(languagePrefix + "_") ||
            $0.hasPrefix(languagePrefix + "-")
        }
        let fetched: [String]
        if let language {
            let range = NSRange(location: 0, length: (word as NSString).length)
            fetched = checker.completions(forPartialWordRange: range,
                                          in: word, language: language) ?? []
        } else {
            fetched = []
        }

        let fallback = hebrew ? fallbackHebrew : fallbackEnglish
        let candidates = fetched + fallback.filter {
            $0.localizedCaseInsensitiveHasPrefix(word)
        }
        var unique = Set<String>()
        let filtered = candidates.filter { candidate in
            let folded = candidate.folding(options: [.caseInsensitive], locale: nil)
            let original = word.folding(options: [.caseInsensitive], locale: nil)
            return folded != original &&
                candidate.localizedCaseInsensitiveHasPrefix(word) &&
                unique.insert(folded).inserted
        }
        prefix = word
        suggestions = Array(filtered.prefix(3))
    }

    func reset() {
        prefix = ""
        suggestions = []
    }

    /// Extract only the word immediately before the cursor, no previous words.
    static func partialWord(in context: String) -> String {
        let fragment = context.reversed().prefix { character in
            character.unicodeScalars.allSatisfy {
                CharacterSet.letters.contains($0) ||
                CharacterSet.nonBaseCharacters.contains($0)
            }
        }
        return String(fragment.reversed())
    }
}
