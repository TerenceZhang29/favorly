import FavorlyCore
import Foundation

/// Previews register no device.
struct PreviewPushRegistrar: PushRegistrar {
    func register(deviceToken _: Data) async throws {}

    func unregister() async {}
}
