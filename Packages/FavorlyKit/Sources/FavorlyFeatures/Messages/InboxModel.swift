import FavorlyCore
import Foundation
import Observation

/// The signed-in user's conversations, shared by the Messages tab, its badge and the incoming-message banner.
/// MainTabView owns one, loads it and keeps it fresh; Chat tells it which thread is on screen, so that thread
/// counts as read and raises no banner.
@MainActor
@Observable
final class InboxModel {
    enum State: Equatable {
        case loading
        /// Newest first.
        case loaded([InboxThread])
        case failed(String)
    }

    /// How long the banner stays before it slides away on its own.
    static let bannerDuration: Duration = .seconds(8)

    private(set) var state: State = .loading
    var filter: InboxFilter = .all
    /// The message the banner shows, if any.
    private(set) var banner: IncomingMessage?
    /// The thread whose chat is on screen.
    private(set) var openChat: RequestID?

    @ObservationIgnored private let environment: AppEnvironment
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var latestLoad = 0
    /// The user the data below belongs to.
    @ObservationIgnored private var loadedUser: UserID?
    /// Every message seen so far; nil before the first load, so messages already there raise no banner.
    @ObservationIgnored private var seenMessages: Set<MessageID>?
    @ObservationIgnored private var requests: [HelpRequest] = []
    @ObservationIgnored private var messagesByThread: [RequestID: [ChatMessage]] = [:]

    init(environment: AppEnvironment, now: @escaping @Sendable () -> Date = Date.init) {
        self.environment = environment
        self.now = now
    }

    /// Changes when the user is switched, which should trigger a fresh load.
    var reloadKey: UserID {
        currentUserID
    }

    var threads: [InboxThread]? {
        guard case let .loaded(threads) = state else { return nil }
        return threads
    }

    /// The threads the selected segment shows.
    var visibleThreads: [InboxThread]? {
        threads?.filter(filter.includes)
    }

    var totalUnread: Int {
        threads?.reduce(0) { $0 + $1.unreadCount } ?? 0
    }

    /// The Messages tab's badge: nil with nothing unread, and "99+" past 99.
    var badgeText: String? {
        switch totalUnread {
        case 0: nil
        case 1 ... 99: String(totalUnread)
        default: "99+"
        }
    }

    func timeText(for thread: InboxThread) -> String {
        thread.timeText(now: now())
    }

    // MARK: Loading

    /// Loads the threads of every request the user posted or is helping with that has a helper. A thread shows once
    /// it has messages, or while the request is claimed and a chat can start.
    func load() async {
        latestLoad += 1
        let load = latestLoad
        let user = currentUserID
        if loadedUser != user {
            loadedUser = user
            seenMessages = nil
            banner = nil
            state = .loading
        } else if case .failed = state {
            state = .loading
        }

        do {
            async let posted = environment.repository.requests(postedBy: user)
            async let claimed = environment.repository.requests(claimedBy: user)
            var byID: [RequestID: HelpRequest] = [:]
            for request in try await posted + claimed where request.helperID != nil {
                byID[request.id] = request
            }
            let requests = Array(byID.values)
            let messages = try await environment.chat.messages(inRequests: requests.map(\.id), as: user)
            guard load == latestLoad, user == currentUserID else { return }

            self.requests = requests
            messagesByThread = Dictionary(grouping: messages, by: \.requestID)
            if let openChat {
                markRead(openChat)
            }
            showBannerForNewMessages(in: messages, user: user)
            rebuild()
        } catch is CancellationError {
            // A newer load replaced this one.
        } catch {
            guard load == latestLoad else { return }
            state = .failed(ErrorMessage.text(for: error))
        }
    }

    /// Reloads after every repository write, such as a new message. Runs until the task is cancelled.
    func observeChanges() async {
        for await _ in environment.repository.changes() {
            await load()
        }
    }

    // MARK: Chat on screen

    /// The chat of `request` is on screen: its messages count as read, and its banner goes away.
    func chatOpened(_ request: RequestID) {
        openChat = request
        if banner?.requestID == request {
            banner = nil
        }
        markRead(request)
        rebuild()
    }

    func chatClosed(_ request: RequestID) {
        markRead(request)
        if openChat == request {
            openChat = nil
        }
        rebuild()
    }

    // MARK: Banner

    func dismissBanner() {
        banner = nil
    }

    /// Clears the banner when it is still showing `message`, once its time is up.
    func bannerTimedOut(_ message: IncomingMessage) {
        if banner == message {
            banner = nil
        }
    }

    // MARK: Helpers

    /// The newest message from someone else that wasn't there at the last load, unless its chat is on screen.
    private func showBannerForNewMessages(in messages: [ChatMessage], user: UserID) {
        defer { seenMessages = Set(messages.map(\.id)) }
        guard let seen = seenMessages else { return }
        let fresh = messages.filter { !seen.contains($0.id) && $0.senderID != user && $0.requestID != openChat }
        guard let latest = fresh.max(by: { $0.sentAt < $1.sentAt }),
              let request = requests.first(where: { $0.id == latest.requestID })
        else { return }
        banner = IncomingMessage(
            messageID: latest.id,
            requestID: latest.requestID,
            senderName: environment.session.displayName(for: latest.senderID),
            favorTitle: request.title,
            text: latest.text
        )
    }

    /// Saves that the user has seen `request`'s thread up to its latest message. The message's own time is used,
    /// not the device clock, so a phone whose clock is off still counts the right messages.
    private func markRead(_ request: RequestID) {
        guard let last = messagesByThread[request]?.last else { return }
        environment.chatReads.markRead(request, upTo: last.sentAt, for: currentUserID)
    }

    private func rebuild() {
        guard let user = loadedUser else { return }
        let threads = requests.compactMap { request -> InboxThread? in
            let messages = messagesByThread[request.id] ?? []
            guard !messages.isEmpty || request.status == .claimed else { return nil }
            let isMine = request.requesterID == user
            let other = isMine ? request.helperID : request.requesterID
            let last = messages.last
            return InboxThread(
                requestID: request.id,
                otherName: other.map(environment.session.displayName(for:)) ?? "",
                favorTitle: request.title,
                isMyRequest: isMine,
                status: request.status,
                lastMessage: last,
                lastIsMine: last?.senderID == user,
                unreadCount: ChatRules.unreadCount(
                    in: messages,
                    for: user,
                    readUpTo: environment.chatReads.readUpTo(request.id, for: user)
                ),
                activityDate: last?.sentAt ?? request.claimedAt ?? request.createdAt
            )
        }
        state = .loaded(threads.sorted { $0.activityDate > $1.activityDate })
    }

    private var currentUserID: UserID {
        environment.session.currentUser.id
    }
}
