import SwiftUI

extension View {
    /// Sets a Grove text style: its Figtree font, letter spacing and case.
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
            .tracking(style.size * style.trackingFactor)
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}
