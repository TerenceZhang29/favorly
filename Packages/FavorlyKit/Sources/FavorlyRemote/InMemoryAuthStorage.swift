import Foundation
import os
import Supabase

/// Keeps the session in memory only, for tests and previews. The app uses the keychain.
public final class InMemoryAuthStorage: AuthLocalStorage {
    private let values = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    public init() {}

    public func store(key: String, value: Data) throws {
        values.withLock { $0[key] = value }
    }

    public func retrieve(key: String) throws -> Data? {
        values.withLock { $0[key] }
    }

    public func remove(key: String) throws {
        _ = values.withLock { $0.removeValue(forKey: key) }
    }
}
