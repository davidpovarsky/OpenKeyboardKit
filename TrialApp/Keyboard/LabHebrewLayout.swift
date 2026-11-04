import OpenKeyboardKit
import SwiftUI

/// Hebrew character layout applied to the SAME KeyboardKit key renderer used
/// for English. There is no independent SwiftUI key grid anymore.
///
/// Arrays are stored in VISUAL left-to-right order, matching the iPad's
/// Hebrew layout; the keyboard's underlying rows continue to be managed by
/// KeyboardKit (including modifier and action keys).
enum LabHebrewLayout {
    static let rows: [[String]] = [
        ["/", "׳", "ק", "ר", "א", "ט", "ו", "ן", "ם", "פ"],
        ["ש", "ד", "ג", "כ", "ע", "י", "ח", "ל", "ך", "ף"],
        ["ז", "ס", "ב", "ה", "נ", "מ", "צ", "ת", "ץ"]
    ]

    static func make(for context: KeyboardContext) -> KeyboardLayout {
        var layout = KeyboardLayout.standard(for: context)
        guard context.keyboardType == .alphabetic else { return layout }

        // Preserve standard keys (backspace, return, shift, globe, symbols,
        // space) and their KeyboardKit sizing. Replace only character keys,
        // inserting missing letters if a localized row has more glyphs.
        var mappedRow = 0
        for rowIndex in layout.itemRows.indices {
            guard mappedRow < rows.count else { break }
            let positions = layout.itemRows[rowIndex].indices.filter { index in
                if case .character = layout.itemRows[rowIndex][index].action {
                    return true
                }
                return false
            }
            guard !positions.isEmpty else { continue }

            let glyphs = rows[mappedRow]
            let used = min(positions.count, glyphs.count)
            for offset in 0..<used {
                layout.itemRows[rowIndex][positions[offset]].action =
                    .character(glyphs[offset])
            }
            if glyphs.count > positions.count, let last = positions.last,
               let template = layout.itemRows[rowIndex].first(where: {
                   if case .character = $0.action { return true }
                   return false
               }) {
                let added = glyphs.dropFirst(positions.count).map {
                    template.copy(withAction: .character($0))
                }
                layout.itemRows[rowIndex].insert(contentsOf: added, at: last + 1)
            }
            mappedRow += 1
        }
        return layout
    }
}
