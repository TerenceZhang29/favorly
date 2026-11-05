import FavorlyCore
import Foundation
import Observation

/// A request's thread between the requester and the helper, as seen by the signed-in user.
@MainActor
@Observable
final class ChatViewModel {
    enum State: Equatable {
        case loading
        /// Oldest first.
        case loaded([ChatMessage])
        case failed(String)
    }

    let requestID: RequestID
    private(set) var state: State = .loading
    private(set) var request: HelpRequest?
    /// What the user is typing.
    var draft = ""
    private(set) var isSending = false
    /// Why the last send failed.
    private(set) var sendError: String?
    /// The other person's Kindness score, for the header; nil until loaded or if it can't be.
    private(set) var otherSummary: KindnessSummary?

    @ObservationIgnored private let environment: AppEnvironment
    @ObservationIgnored private var latestLoad = 0

    init(requestID: RequestID, environment: AppEnvironment) {
        self.requestID = requestID
        self.environment = environment
    }

    /// Changes when the user is switched, which should trigger a fresh load.
    var reloadKey: UserID {
        currentUserID
    }

    var messages: [ChatMessage]? {
        guard case let .loaded(messages) = state else { return nil }
        return messages
    }

    var title: String {
        request?.title ?? ""
    }

    /// The request is picked up and the signed-in user is one of the two people in it.
    var isOpenForSending: Bool {
        guard let request else { return false }
        return ChatRules.canSend(request: request, by: currentUserID)
    }

    /// Shown instead of the text field once the thread is read-only.
    var closedText: String? {
        guard let request, case .loaded = state, !isOpenForSending else { return nil }
        return switch request.status {
        case .cancelled: "This request was cancelled. The conversation is read-only."
        default: "This request is completed. The conversation is read-only."
        }
    }

    var canSend: Bool {
        isOpenForSending && !isSending && (try? ChatRules.validateText(draft)) != nil
    }

    /// "12 / 500", shown once the user starts typing.
    var draftCountText: String? {
        draft.isEmpty ? nil : "\(draft.count) / \(ChatRules.messageLengthRange.upperBound)"
    }

    /// What is wrong with the draft, once it is too long. An empty draft only disables Send.
    var draftMessage: String? {
        guard draft.count > ChatRules.messageLengthRange.upperBound else { return nil }
        do {
            try ChatRules.validateText(draft)
            return nil
        } catch {
            return ErrorMessage.text(for: error)
        }
    }

    func isMine(_ message: ChatMessage) -> Bool {
        message.senderID == currentUserID
    }

    /// "You", or the sender's name.
    func senderName(of message: ChatMessage) -> String {
        isMine(message) ? "You" : environment.session.displayName(for: message.senderID)
    }

    // MARK: Header and request card, as in the Grove mockup

    /// The other person in the thread: the helper for the requester, the requester for the helper.
    var otherName: String? {
        guard let request, let other = Self.otherPerson(in: request, for: currentUserID) else { return nil }
        return environment.session.displayName(for: other)
    }

    /// "120 points · 9 favors done", under the other person's name.
    var otherScoreText: String? {
        guard let summary = otherSummary else { return nil }
        let favors = summary.completedFavors == 1 ? "1 favor done" : "\(summary.completedFavors) favors done"
        return "\(summary.lifetimePoints) points · \(favors)"
    }

    /// Whether the signed-in user is the helper, for the card's "You're helping" badge.
    var isHelping: Bool {
        request?.helperID == currentUserID
    }

    /// "You're helping" or "Helping you".
    var roleText: String {
        isHelping ? "You're helping" : "Helping you"
    }

    /// What the helper can earn, shown to the helper only: "+10 to +20 pts".
    var pointsRangeText: String? {
        guard isHelping else { return nil }
        let most = KindnessRules.pointsPerFavor + KindnessRules.pointsPerStar * ReviewRules.ratingRange.upperBound
        return "+\(KindnessRules.pointsPerFavor) to +\(most) pts"
    }

    /// Who finishes the favor: "Alex marks it done when you're finished", or, for the requester, "Mark it done
    /// on the request when Bea is finished". Nil once the request is no longer claimed.
    var completionNote: String? {
        guard request?.status == .claimed, let otherName else { return nil }
        return isHelping
            ? "\(otherName) marks it done when you're finished"
            : "Mark it done on the request when \(otherName) is finished"
    }

    private static func otherPerson(in request: HelpRequest, for user: UserID) -> UserID? {
        request.requesterID == user ? request.helperID : request.requesterID
    }

    // MARK: Loading

    /// Loads the request and its thread. A thread already on screen stays visible while it reloads.
    func load() async {
        latestLoad += 1
        let load = latestLoad
        let user = currentUserID
        if case .failed = state {
            state = .loading
        }

        do {
            let request = try await environment.repository.request(id: requestID)
            let messages = try await environment.chat.messages(for: requestID, as: user)
            let other = Self.otherPerson(in: request, for: user)
            let summary = if let other {
                try? await environment.kindness.kindnessSummary(for: other)
            } else {
                KindnessSummary?.none
            }
            guard load == latestLoad else { return }
            self.request = request
            otherSummary = summary
            state = .loaded(messages)
        } catch is CancellationError {
            // A newer load replaced this one.
        } catch {
            guard load == latestLoad else { return }
            state = .failed(ErrorMessage.text(for: error))
        }
    }

    /// Reloads after every repository write, such as the other person's reply. Runs until the task is cancelled.
    func observeChanges() async {
        for await _ in environment.repository.changes() {
            await load()
        }
    }

    // MARK: Sending

    func send() async {
        guard canSend else { return }
        isSending = true
        defer { isSending = false }
        sendError = nil

        do {
            _ = try await environment.chat.send(draft, in: requestID, by: currentUserID)
            draft = ""
            await load()
        } catch is CancellationError {
            // The screen went away.
        } catch {
            sendError = ErrorMessage.text(for: error)
            await load()
        }
    }

    // MARK: Helpers

    private var currentUserID: UserID {
        environment.session.currentUser.id
    }
}
