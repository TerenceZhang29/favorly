import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Foundation
import os
import Testing

@MainActor
struct InboxModelTests {
    /// The ladder request (6): Dana asked, Chen is helping. Every message is a minute after the last.
    private static let ladderID = TestWorld.ladderID
    private let clock = OSAllocatedUnfairLock(initialState: TestWorld.now)
    private let repository: MockRequestRepository
    private let session = MockSessionStore()
    private let reads = InMemoryChatReadStore()

    init() {
        let clock = clock
        repository = MockRequestRepository(
            seed: { DemoRequests.all(now: TestWorld.now) },
            reviewSeed: { DemoReviews.all(now: TestWorld.now) },
            artificialDelay: .zero,
            now: { clock.withLock { $0 = $0.addingTimeInterval(60); return $0 } }
        )
    }

    private var environment: AppEnvironment {
        AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            moderation: repository,
            neighborhoods: repository,
            locationProvider: MockLocationProvider(settings: MockLocationSettings()),
            session: session,
            auth: MockAuthService(session: session, startsSignedIn: true, artificialDelay: .zero),
            push: MockPushRegistrar(),
            notifications: MockNotificationService(),
            locationSettings: nil,
            chatReads: reads
        )
    }

    private func model(as user: UserProfile) async -> InboxModel {
        session.switchUser(to: user.id)
        let model = InboxModel(environment: environment) { TestWorld.now }
        await model.load()
        return model
    }

    private func thread(_ model: InboxModel) -> InboxThread? {
        model.threads?.first { $0.requestID == Self.ladderID }
    }

    @Test func aClaimedRequestShowsAnEmptyThreadForBothPeople() async {
        let chen = await model(as: DemoUsers.chen)
        let helping = thread(chen)
        #expect(helping?.otherName == "Dana")
        #expect(helping?.roleText == "You're helping")
        #expect(helping?.previewText == "No messages yet. Say hello.")
        #expect(helping?.unreadCount == 0)
        #expect(chen.badgeText == nil)

        let dana = await model(as: DemoUsers.dana)
        #expect(thread(dana)?.roleText == "Your request")
        #expect(thread(dana)?.otherName == "Chen")
    }

    @Test func completedRequestsWithoutMessagesAreLeftOut() async {
        // Bea helped with several of Alex's requests, all completed, none with messages.
        let alex = await model(as: DemoUsers.alex)
        #expect(alex.threads?.allSatisfy { $0.status == .claimed || $0.lastMessage != nil } == true)
    }

    @Test func theOtherPersonsMessagesAreUnreadUntilTheChatOpens() async throws {
        _ = try await repository.send("On my way", in: Self.ladderID, by: DemoUsers.chen.id)
        _ = try await repository.send("Ten minutes", in: Self.ladderID, by: DemoUsers.chen.id)
        let dana = await model(as: DemoUsers.dana)
        #expect(thread(dana)?.unreadCount == 2)
        #expect(thread(dana)?.previewText == "Ten minutes")
        #expect(thread(dana)?.unreadLabel == "2 unread")
        #expect(dana.badgeText == "2")

        dana.chatOpened(Self.ladderID)
        #expect(thread(dana)?.unreadCount == 0)
        #expect(dana.badgeText == nil)

        // A reply of her own shows with "You:" and doesn't count.
        _ = try await repository.send("Great", in: Self.ladderID, by: DemoUsers.dana.id)
        await dana.load()
        #expect(thread(dana)?.previewText == "You: Great")
        #expect(thread(dana)?.unreadCount == 0)
    }

    @Test func aMessageWhileTheChatIsOpenIsReadAndRaisesNoBanner() async throws {
        let dana = await model(as: DemoUsers.dana)
        dana.chatOpened(Self.ladderID)
        _ = try await repository.send("Here", in: Self.ladderID, by: DemoUsers.chen.id)
        await dana.load()
        #expect(dana.banner == nil)
        #expect(thread(dana)?.unreadCount == 0)

        dana.chatClosed(Self.ladderID)
        _ = try await repository.send("Downstairs", in: Self.ladderID, by: DemoUsers.chen.id)
        await dana.load()
        #expect(thread(dana)?.unreadCount == 1)
        #expect(dana.banner?.text == "Downstairs")
    }

    @Test func aNewMessageRaisesTheBannerButOnesAlreadyThereDont() async throws {
        _ = try await repository.send("Before launch", in: Self.ladderID, by: DemoUsers.chen.id)
        let dana = await model(as: DemoUsers.dana)
        #expect(dana.banner == nil)

        _ = try await repository.send("On my way", in: Self.ladderID, by: DemoUsers.chen.id)
        await dana.load()
        let banner = try #require(dana.banner)
        #expect(banner.senderName == "Chen")
        #expect(banner.favorTitle == "Hold a ladder while I change a bulb")
        #expect(banner.text == "On my way")
        #expect(banner.announcement == "New message from Chen: On my way")

        // The next load doesn't raise it again, and Later dismisses it.
        dana.dismissBanner()
        await dana.load()
        #expect(dana.banner == nil)
    }

    @Test func herOwnMessagesNeverRaiseTheBanner() async throws {
        let dana = await model(as: DemoUsers.dana)
        _ = try await repository.send("Are you close?", in: Self.ladderID, by: DemoUsers.dana.id)
        await dana.load()
        #expect(dana.banner == nil)
    }

    @Test func openingTheChatOrTimingOutClearsTheBanner() async throws {
        let dana = await model(as: DemoUsers.dana)
        _ = try await repository.send("One", in: Self.ladderID, by: DemoUsers.chen.id)
        await dana.load()
        let first = try #require(dana.banner)
        dana.chatOpened(Self.ladderID)
        #expect(dana.banner == nil)
        dana.chatClosed(Self.ladderID)

        _ = try await repository.send("Two", in: Self.ladderID, by: DemoUsers.chen.id)
        await dana.load()
        dana.bannerTimedOut(first)
        #expect(dana.banner?.text == "Two")
        try dana.bannerTimedOut(#require(dana.banner))
        #expect(dana.banner == nil)
    }

    @Test func switchingUsersStartsOverWithoutABanner() async throws {
        let model = await model(as: DemoUsers.dana)
        _ = try await repository.send("Hi Dana", in: Self.ladderID, by: DemoUsers.chen.id)
        session.switchUser(to: DemoUsers.chen.id)
        await model.load()
        #expect(model.banner == nil)
        #expect(thread(model)?.roleText == "You're helping")
    }

    @Test func theSegmentsSplitMyRequestsFromHelping() async throws {
        // Dana asks for the ladder and also claims the eggs, so she has one thread of each kind.
        _ = try await repository.claim(TestWorld.eggsID, by: DemoUsers.dana.id)
        let dana = await model(as: DemoUsers.dana)
        #expect(dana.visibleThreads?.count == 2)
        dana.filter = .mine
        #expect(dana.visibleThreads?.map(\.requestID) == [Self.ladderID])
        dana.filter = .helping
        #expect(dana.visibleThreads?.map(\.requestID) == [TestWorld.eggsID])
    }

    @Test func theBadgeCapsAt99() async throws {
        for number in 1 ... 100 {
            _ = try await repository.send("Message \(number)", in: Self.ladderID, by: DemoUsers.chen.id)
        }
        let dana = await model(as: DemoUsers.dana)
        #expect(dana.totalUnread == 100)
        #expect(dana.badgeText == "99+")
    }

    @Test func theTimeIsTheClockTodayAndTheDayBefore() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let today = now.addingTimeInterval(-60)
        let earlier = now.addingTimeInterval(-3 * 86400)
        #expect(InboxThread.fixture(at: today).timeText(now: now)
            == today.formatted(date: .omitted, time: .shortened))
        #expect(InboxThread.fixture(at: earlier).timeText(now: now)
            == earlier.formatted(.dateTime.month(.abbreviated).day()))
    }
}

private extension InboxThread {
    static func fixture(at date: Date) -> InboxThread {
        InboxThread(
            requestID: RequestID(rawValue: UUID()),
            otherName: "Bea",
            favorTitle: "Eggs",
            isMyRequest: true,
            status: .completed,
            lastMessage: nil,
            lastIsMine: false,
            unreadCount: 0,
            activityDate: date
        )
    }
}
