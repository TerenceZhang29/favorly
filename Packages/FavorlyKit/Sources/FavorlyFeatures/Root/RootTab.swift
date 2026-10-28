import Foundation

enum RootTab: String, CaseIterable, Identifiable, Sendable {
    case nearby
    case post
    case activity
    case profile
    case devSettings

    var id: String { rawValue }

    /// The tabs this build shows: Dev Settings only in Debug builds, never in the App Store build.
    static var visible: [RootTab] {
        #if DEBUG
            tabs(showingDevSettings: true)
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
