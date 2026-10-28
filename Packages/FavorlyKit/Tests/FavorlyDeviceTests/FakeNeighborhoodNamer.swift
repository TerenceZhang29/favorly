import FavorlyCore
import FavorlyDevice
import Foundation
import os

final class FakeNeighborhoodNamer: NeighborhoodNamer {
    let result: String?
    private let lookups = OSAllocatedUnfairLock(initialState: 0)

    init(_ result: String?) {
        self.result = result
    }

    var lookupCount: Int {
        lookups.withLock { $0 }
    }

    func name(for _: GeoPoint) async -> String? {
        lookups.withLock { $0 += 1 }
        return result
    }
}
