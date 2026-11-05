import SwiftUI

/// A chip's own pressed look, so a list row's highlight never dims a chip after it is tapped.
struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Theme.pressedOpacity : 1)
            .contentShape(Capsule())
    }
}
