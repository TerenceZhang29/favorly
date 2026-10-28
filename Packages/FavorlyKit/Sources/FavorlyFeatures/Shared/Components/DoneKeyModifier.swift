import SwiftUI

/// Turns a multi-line field's Return key into a Done key that closes the keyboard.
/// A multi-line field would otherwise start a new line, leaving no key that puts the keyboard away.
struct DoneKeyModifier: ViewModifier {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .submitLabel(.done)
            .onChange(of: text) { old, new in
                if Self.isReturnKey(old: old, new: new) {
                    text = old
                    isFocused = false
                }
            }
    }

    /// True when `new` is `old` plus one typed line break. Pasted text keeps its line breaks.
    nonisolated static func isReturnKey(old: String, new: String) -> Bool {
        guard new.count == old.count + 1 else { return false }
        let lineBreaks: (String) -> Int = { $0.count(where: \.isNewline) }
        return lineBreaks(new) == lineBreaks(old) + 1
    }
}
