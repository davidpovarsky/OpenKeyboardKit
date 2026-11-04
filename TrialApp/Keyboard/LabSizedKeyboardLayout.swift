import OpenKeyboardKit
import SwiftUI

/// One source of truth for BOTH languages and the two real key sizes.
/// No empty spacer is added for the larger mode: the KeyboardKit key rows
/// themselves become taller, so the extension's measured height follows.
enum LabSizedKeyboardLayout {
    static func make(for context: KeyboardContext,
                     hebrew: Bool,
                     largeKeys: Bool) -> KeyboardLayout {
        var layout = hebrew
            ? LabHebrewLayout.make(for: context)
            : KeyboardLayout.standard(for: context)
        guard largeKeys else { return layout }
        // Keep all the original widths, actions, insets and iPad layouts.
        let extra: CGFloat = context.deviceTypeForKeyboard == .pad ? 13 : 6
        for row in layout.itemRows.indices {
            for column in layout.itemRows[row].indices {
                layout.itemRows[row][column].size.height += extra
            }
        }
        layout.idealItemHeight += Double(extra)
        return layout
    }
}
