import Foundation

/// Refuses offensive words in anything other people read: titles, details, messages, review comments and names.
/// The server applies the same list (`backend/supabase/migrations/20261029000006_safety.sql`); a test keeps the
/// two the same. Reports and moderation catch what a word list cannot.
public enum ContentFilter {
    public static let message = "Please remove offensive language."

    /// Lowercase, letters only. Endings such as "s" or "ing" are matched too.
    public static let words: Set<String> = [
        "asshole", "bastard", "bitch", "bullshit", "chink", "cock", "cunt", "dick", "fag", "faggot", "fuck",
        "fucker", "fucking", "kike", "motherfucker", "nigga", "nigger", "pussy", "retard", "shit", "slut",
        "spic", "tranny", "twat", "wank", "whore",
    ]

    static let endings = ["", "s", "es", "ed", "er", "ers", "ing", "y"]

    public static func containsOffensiveWord(_ text: String) -> Bool {
        let tokens = text.lowercased().split { !("a" ... "z").contains($0) }
        return tokens.contains { token in
            endings.contains { ending in
                token.hasSuffix(ending) && words.contains(String(token.dropLast(ending.count)))
            }
        }
    }

    public static func validate(_ text: String) throws {
        guard !containsOffensiveWord(text) else { throw FavorlyError.validation(message) }
    }
}
