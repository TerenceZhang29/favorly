/// Switches to another tab, such as the Nearby score pill opening Profile. Call it like a function:
/// `selectTab(.profile)`. The default does nothing, for views outside the tabs.
struct SelectTabAction {
    private let select: @MainActor (RootTab) -> Void

    init(_ select: @escaping @MainActor (RootTab) -> Void = { _ in }) {
        self.select = select
    }

    @MainActor
    func callAsFunction(_ tab: RootTab) {
        select(tab)
    }
}
