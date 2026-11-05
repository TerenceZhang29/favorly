import Observation

/// Which tabs have hidden the Grove tab bar, such as a tab showing a chat. The bar shows for every other tab.
@MainActor
@Observable
final class TabBarVisibility {
    private(set) var hiddenTabs: Set<RootTab> = []

    func setHidden(_ hidden: Bool, for tab: RootTab) {
        if hidden {
            hiddenTabs.insert(tab)
        } else {
            hiddenTabs.remove(tab)
        }
    }

    func isHidden(for tab: RootTab) -> Bool {
        hiddenTabs.contains(tab)
    }
}
