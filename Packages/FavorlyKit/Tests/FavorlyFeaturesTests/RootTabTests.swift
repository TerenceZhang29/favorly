@testable import FavorlyFeatures
import Testing

@Test func rootHasFiveTabsInDemoOrder() {
    #expect(RootTab.allCases == [.nearby, .post, .activity, .profile, .devSettings])
    #expect(RootTab.profile.title == "Profile")
    #expect(RootTab.profile.systemImage == "person.crop.circle")
}

@Test func rootTabsHaveDistinctTitlesAndIcons() {
    #expect(Set(RootTab.allCases.map(\.title)).count == RootTab.allCases.count)
    #expect(Set(RootTab.allCases.map(\.systemImage)).count == RootTab.allCases.count)
}

@Test func devSettingsAreLeftOutOfTheAppStoreBuild() {
    #expect(RootTab.tabs(showingDevSettings: false) == [.nearby, .post, .activity, .profile])
    #expect(RootTab.tabs(showingDevSettings: true) == RootTab.allCases)
}

@Test func debugBuildsShowDevSettings() {
    // Tests run in Debug, so the visible tabs include Dev Settings.
    #expect(RootTab.visible == RootTab.allCases)
}
