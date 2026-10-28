import Foundation

/// Where the Supabase project is. The anon key is public by design: row-level security protects the data.
public struct RemoteConfiguration: Sendable {
    public let url: URL
    public let anonKey: String

    public init(url: URL, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
    }

    /// Reads `FavorlySupabaseURL` and `FavorlySupabaseAnonKey`, or nil when either is missing or empty.
    public init?(info: [String: Any]) {
        guard let urlText = info["FavorlySupabaseURL"] as? String, let url = URL(string: urlText),
              url.scheme != nil,
              let anonKey = info["FavorlySupabaseAnonKey"] as? String, !anonKey.isEmpty
        else { return nil }
        self.init(url: url, anonKey: anonKey)
    }
}
