import FavorlyCore
import Foundation

/// Remembers the registered device instead of telling a server.
public actor MockPushRegistrar: PushRegistrar {
    public private(set) var deviceToken: Data?

    public init() {}

    public func register(deviceToken: Data) async throws {
        self.deviceToken = deviceToken
    }

    public func unregister() async {
        deviceToken = nil
    }
}
