import SwiftUI

extension View {
    /// For a multi-line text field bound to `text`: the Return key reads Done and closes the keyboard.
    func doneKey(text: Binding<String>) -> some View {
        modifier(DoneKeyModifier(text: text))
    }
}
