import FavorlyCore

/// Dev Settings, demo launches only: the other person in the user's most recently claimed request sends a message,
/// so the banner and unread badge can be tried on one phone.
enum DevMessageSimulator {
    static let noThread = "Nothing to reply to yet. Claim a request, or have one of yours claimed, first."

    /// Sends the message and says what happened.
    @MainActor
    static func receiveMessage(in environment: AppEnvironment) async -> String {
        let user = environment.session.currentUser.id
        do {
            async let posted = environment.repository.requests(postedBy: user)
            async let claimed = environment.repository.requests(claimedBy: user)
            let latest = try await (posted + claimed)
                .filter { $0.status == .claimed }
                .max { ($0.claimedAt ?? $0.createdAt) < ($1.claimedAt ?? $1.createdAt) }
            guard let request = latest,
                  let other = request.requesterID == user ? request.helperID : request.requesterID
            else { return noThread }
            _ = try await environment.chat.send("Hi! Checking in about \(request.title).", in: request.id, by: other)
            return "\(environment.session.displayName(for: other)) sent you a message."
        } catch {
            return ErrorMessage.text(for: error)
        }
    }
}
