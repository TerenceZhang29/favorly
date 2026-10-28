import Foundation
import os

/// Fans a "something changed" signal out to every open `AsyncStream`, like the mock's broadcaster.
final class RemoteChangeBroadcaster: Sendable {
    private let continuations = OSAllocatedUnfairLock<[UUID: AsyncStream<Void>.Continuation]>(initialState: [:])

    func stream() -> AsyncStream<Void> {
        let id = UUID()
        // Signals carry no payload, so one pending signal is enough for a slow subscriber.
        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.onTermination = { [continuations] _ in
            continuations.withLock { $0[id] = nil }
        }
        continuations.withLock { $0[id] = continuation }
        return stream
    }

    func send() {
        let current = continuations.withLock { Array($0.values) }
        for continuation in current {
            continuation.yield()
        }
    }
}
