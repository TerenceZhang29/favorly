import Foundation

/// Tells the server which device to send the signed-in user's notifications to.
public protocol PushRegistrar: Sendable {
    func register(deviceToken: Data) async throws
    /// Forgets the last registered device, at sign-out. Failures are ignored: the server drops dead tokens.
    func unregister() async
}
