import SwiftUI

extension View {
    /// For a `List` or `Form`: the Grove background shows behind it, instead of the system's gray.
    @ViewBuilder
    func groveListBackground() -> some View {
        if CIExperiment.plainBackground {
            scrollContentBackground(.hidden)
                .background(Theme.Colors.background)
        } else {
            scrollContentBackground(.hidden)
                .background(GroveBackground())
        }
    }

    /// For a section of a grouped list: its rows sit on the Grove surface color.
    func groveRows() -> some View {
        listRowBackground(Rectangle().fill(Theme.Colors.surface))
    }
}
