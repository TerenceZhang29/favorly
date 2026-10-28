import CryptoKit
import Foundation

/// The one-time value that ties a Sign in with Apple token to this sign-in. Apple gets its SHA-256 hash; the
/// server gets the raw value and checks that it hashes to what is inside the token.
enum AppleSignInNonce {
    private static let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

    static func make(length: Int = 32) -> String {
        var generator = SystemRandomNumberGenerator()
        return String((0 ..< length).map { _ in characters.randomElement(using: &generator)! })
    }

    static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
