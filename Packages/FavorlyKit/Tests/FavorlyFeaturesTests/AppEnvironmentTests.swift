import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import SwiftUI
import Testing

@MainActor
struct AppEnvironmentTests {
    private func makeEnvironment() -> AppEnvironment {
        let locationSettings = MockLocationSettings()
        let repository = MockRequestRepository(artificialDelay: .zero)
        let session = MockSessionStore()
        return AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            moderation: repository,
            locationProvider: MockLocationProvider(settings: locationSettings),
            session: session,
            auth: MockAuthService(session: session, startsSignedIn: true, artificialDelay: .zero),
            locationSettings: locationSettings
        )
    }

    @Test func debugSummaryNamesTheUserAndLocation() {
        #expect(makeEnvironment().debugSummary == "Alex @ Cornell Tech, Roosevelt Island")
    }

    @Test func debugSummaryFollowsUserAndLocationChanges() {
        let environment = makeEnvironment()
        (environment.session as? MockSessionStore)?.switchUser(to: DemoUsers.bea.id)
        environment.locationSettings?.selectedPreset = LocationPresets.ithaca
        #expect(environment.debugSummary == "Bea @ Ithaca, NY")
    }

    @Test func locationProviderFollowsTheSharedLocationSettings() async throws {
        let environment = makeEnvironment()
        environment.locationSettings?.selectedPreset = LocationPresets.midtownEast
        #expect(try await environment.locationProvider.currentLocation() == LocationPresets.midtownEast.location)

        environment.locationSettings?.simulatesError = true
        await #expect(throws: FavorlyError.locationUnavailable) {
            try await environment.locationProvider.currentLocation()
        }
    }

    @Test func previewEnvironmentIsSelfConsistent() async throws {
        let environment = AppEnvironment.preview()
        #expect(environment.auth.state == .signedIn)
        let controls = try #require(environment.session as? any DemoSessionControls)
        #expect(controls.availableUsers.contains(environment.session.currentUser))
        let settings = try #require(environment.locationSettings)
        #expect(settings.presets.contains(settings.selectedPreset))

        let here = try await environment.locationProvider.currentLocation()
        #expect(here == settings.selectedPreset.location)
        #expect(try await !environment.repository.nearby(around: here.point, radiusMeters: 1000).isEmpty)
    }

    @Test func environmentValuesDefaultToThePreviewEnvironment() {
        let environment = EnvironmentValues().appEnvironment
        #expect(environment.debugSummary == AppEnvironment.preview().debugSummary)
    }

    @Test func previewSessionSwitchesBetweenItsUsers() throws {
        let session = AppEnvironment.preview().session
        let controls = try #require(session as? any DemoSessionControls)
        let other = try #require(controls.availableUsers.first { $0 != session.currentUser })
        controls.switchUser(to: other.id)
        #expect(session.currentUser == other)
        #expect(session.profile(for: other.id) == other)
    }

    @Test func previewAuthMovesThroughEverySignInState() async throws {
        let auth = AppEnvironment.preview().auth
        await auth.signOut()
        #expect(auth.state == .signedOut)
        try await auth.signInWithApple(identityToken: "", nonce: "")
        #expect(auth.state == .needsProfile)
        try await auth.completeProfile(ProfileSetupDraft(displayName: "Sam", confirmedAdult: true, acceptedTerms: true))
        #expect(auth.state == .signedIn)
    }

    @Test func previewRepositoryIsReadOnly() async throws {
        let environment = AppEnvironment.preview()
        let user = environment.session.currentUser.id
        let here = try await environment.locationProvider.currentLocation()
        let first = try #require(try await environment.repository.nearby(around: here.point, radiusMeters: 1000).first)

        #expect(try await environment.repository.request(id: first.id) == first.request)
        await #expect(throws: FavorlyError.notAllowed) {
            try await environment.repository.claim(first.id, by: user)
        }
        await #expect(throws: FavorlyError.notAllowed) {
            try await environment.repository.create(
                NewRequestDraft(title: "Need rice", details: "", category: .other, location: here),
                by: user
            )
        }
    }

    @Test func withoutPresetsTheSummarySaysTheDevicesLocation() {
        let world = TestWorld()
        #expect(world.deviceEnvironment(locationProvider: DeniedLocationProvider()).debugSummary
            == "Alex @ this device's location")
    }
}
