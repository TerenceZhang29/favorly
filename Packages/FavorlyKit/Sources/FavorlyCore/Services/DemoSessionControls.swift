import Foundation

/// Switching between demo users. Only the mock and preview sessions offer it, and only Debug builds show it.
@MainActor
public protocol DemoSessionControls: AnyObject, Sendable {
    var availableUsers: [UserProfile] { get }
    func switchUser(to id: UserID)
}
