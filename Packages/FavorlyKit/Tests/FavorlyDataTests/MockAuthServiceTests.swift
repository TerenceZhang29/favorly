import FavorlyCore
import FavorlyData
import Testing

@MainActor
struct MockAuthServiceTests {
    let session = MockSessionStore()

    private func makeAuth(startsSignedIn: Bool = false) -> MockAuthService {
        MockAuthService(session: session, startsSignedIn: startsSignedIn, artificialDelay: .zero)
    }

    private func draft(_ name: String = "Sam") -> ProfileSetupDraft {
        ProfileSetupDraft(displayName: name, confirmedAdult: true, acceptedTerms: true)
    }

    @Test func startsSignedOutOrSignedInAsAsked() {
        #expect(makeAuth().state == .signedOut)
        #expect(makeAuth(startsSignedIn: true).state == .signedIn)
    }

    @Test func signingInAsksForAProfile() async throws {
        let auth = makeAuth()
        try await auth.signInWithApple(identityToken: "token", nonce: "nonce")
        #expect(auth.state == .needsProfile)
    }

    @Test func completingTheProfileSignsInAsANewUser() async throws {
        let auth = makeAuth()
        try await auth.signInWithApple(identityToken: "token", nonce: "nonce")
        try await auth.completeProfile(draft("  Sam "))

        #expect(auth.state == .signedIn)
        #expect(session.currentUser.displayName == "Sam")
        #expect(!DemoUsers.all.map(\.id).contains(session.currentUser.id))
        #expect(session.profile(for: session.currentUser.id) == session.currentUser)
    }

    @Test func anInvalidProfileIsRefusedAndStaysInSetup() async throws {
        let auth = makeAuth()
        try await auth.signInWithApple(identityToken: "token", nonce: "nonce")
        await #expect(throws: FavorlyError.validation("You must be 18 or older to use Favorly.")) {
            try await auth.completeProfile(ProfileSetupDraft(
                displayName: "Sam",
                confirmedAdult: false,
                acceptedTerms: true
            ))
        }
        #expect(auth.state == .needsProfile)
        #expect(session.currentUser == DemoUsers.alex)
    }

    @Test func aProfileCanOnlyBeCompletedAfterSigningIn() async {
        await #expect(throws: FavorlyError.notAllowed) {
            try await makeAuth().completeProfile(draft())
        }
    }

    @Test func signingOutReturnsToSignedOut() async {
        let auth = makeAuth(startsSignedIn: true)
        await auth.signOut()
        #expect(auth.state == .signedOut)
    }

    @Test func deletingTheAccountForgetsTheUserAndSignsOut() async throws {
        let auth = makeAuth(startsSignedIn: true)
        try await auth.deleteAccount()
        #expect(auth.state == .signedOut)
        #expect(session.profile(for: DemoUsers.alex.id) == nil)
        #expect(!session.availableUsers.contains(DemoUsers.alex))
    }

    @Test func deletingRequiresBeingSignedIn() async {
        await #expect(throws: FavorlyError.notAllowed) {
            try await makeAuth().deleteAccount()
        }
    }
}
