import Foundation
import Testing

/// Which implementation a contract test runs against.
enum ContractBackend: String, CustomTestStringConvertible, Sendable {
    case mock
    /// The local Supabase stack. Needs `supabase start` in `backend/` and these variables:
    /// `FAVORLY_REMOTE_TESTS=1`, `FAVORLY_SUPABASE_URL` and `FAVORLY_SUPABASE_ANON_KEY`.
    case remote

    var testDescription: String { rawValue }

    /// The mock always; the local backend when asked for.
    static var enabled: [ContractBackend] {
        ProcessInfo.processInfo.environment["FAVORLY_REMOTE_TESTS"] == "1" ? [.mock, .remote] : [.mock]
    }
}
