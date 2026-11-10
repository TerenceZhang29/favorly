import Foundation

enum RootTab: String, CaseIterable, Identifiable, Sendable {
    case nearby
    case post
    case activity
    case profile
    case devSettings

    var id: String { rawValue }

    /// The tabs this build shows: Dev Settings only in Debug builds, never in the App Store build. A Debug launch
    /// with `-noDevSettings` hides it too, for the App Store screenshots.
    static var visible: [RootTab] {
        #if DEBUG
            tabs(showingDevSettings: !ProcessInfo.processInfo.arguments.contains("-noDevSettings"))
        #else
            tabs(showingDevSettings: false)
        #endif
    }

    static func tabs(showingDevSettings: Bool) -> [RootTab] {
        showingDevSettings ? allCases : allCases.filter { $0 != .devSettings }
    }

    var title: String {
        switch self {
        case .nearby: "Nearby"
        case .post: "Post"
        case .activity: "My Activity"
        case .profile: "Profile"
        case .devSettings: "Dev Settings"
        }
    }

    /// The symbol when the tab is selected: filled where SF Symbols has a filled form.
    var selectedSystemImage: String {
        switch self {
        case .nearby: "location.fill"
        case .post: "plus.circle.fill"
        case .activity: "list.bullet"
        case .profile: "person.crop.circle.fill"
        case .devSettings: "gearshape.fill"
        }
    }

    var systemImage: String {
        switch self {
        case .nearby: "location"
        case .post: "plus.circle"
        case .activity: "list.bullet"
        case .profile: "person.crop.circle"
        case .devSettings: "gearshape"
        }
    }
}
