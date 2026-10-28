import FavorlyCore
@testable import FavorlyDevice
import Foundation

@MainActor
final class FakeLocationSource: LocationSource {
    struct Failure: Error {}

    var authorization: LocationAuthorization
    /// What the user answers when asked.
    var answer: LocationAuthorization
    var point: GeoPoint?
    private(set) var requests = 0

    init(authorization: LocationAuthorization, answer: LocationAuthorization = .allowed, point: GeoPoint? = nil) {
        self.authorization = authorization
        self.answer = answer
        self.point = point
    }

    func requestAuthorization() async -> LocationAuthorization {
        requests += 1
        authorization = answer
        return answer
    }

    func currentPoint() async throws -> GeoPoint {
        guard let point else { throw Failure() }
        return point
    }
}
