import Foundation
import os

/// A test clock that stays put until a test moves it, for rules that depend on how much time has passed.
final class AdjustableClock: Sendable {
    private let current: OSAllocatedUnfairLock<Date>

    init(_ start: Date) {
        current = OSAllocatedUnfairLock(initialState: start)
    }

    var now: Date {
        current.withLock { $0 }
    }

    func moveForward(by seconds: TimeInterval) {
        current.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
}
