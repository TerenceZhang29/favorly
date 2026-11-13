#if DEBUG
    import FavorlyCore
    import FavorlyFeatures
    import Foundation

    /// Debug demo launches with `-demoReplies`: when the user writes in a thread, the other person answers 15
    /// seconds later, once the screenshot walk has left the chat, so the Messages banner and unread badge show on
    /// one phone, as in the App Store screenshots.
    @MainActor
    final class DemoReplier {
        static let reply = "Perfect, see you in the lobby. Thank you!"
        private let environment: AppEnvironment
        /// The user's messages already answered.
        private var answered: Set<MessageID> = []

        init(environment: AppEnvironment) {
            self.environment = environment
        }

        /// Runs until the task is cancelled.
        func run() async {
            for await _ in environment.repository.changes() {
                await answerNewMessages()
            }
        }

        private func answerNewMessages() async {
            let user = environment.session.currentUser.id
            guard let posted = try? await environment.repository.requests(postedBy: user),
                  let claimed = try? await environment.repository.requests(claimedBy: user)
            else { return }
            for request in posted + claimed where request.status == .claimed {
                guard let other = request.requesterID == user ? request.helperID : request.requesterID,
                      let last = try? await environment.chat.messages(for: request.id, as: user).last,
                      last.senderID == user, !answered.contains(last.id)
                else { continue }
                answered.insert(last.id)
                try? await Task.sleep(for: .seconds(15))
                _ = try? await environment.chat.send(Self.reply, in: request.id, by: other)
            }
        }
    }
#endif
