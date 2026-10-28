import FavorlyCore
import Foundation

public extension AppEnvironment {
    /// One instance shared by every view that has no environment injected, so their state stays in sync.
    @MainActor static let sharedPreview = preview()

    /// Fixed sample data for SwiftUI previews.
    @MainActor
    static func preview() -> AppEnvironment {
        let here = TaggedLocation(point: GeoPoint(latitude: 40.7553, longitude: -73.9562), label: "Cornell Tech")
        let alex = UserProfile(
            id: UserID(rawValue: "preview-alex"),
            displayName: "Alex",
            neighborhood: "Roosevelt Island"
        )
        let bea = UserProfile(id: UserID(rawValue: "preview-bea"), displayName: "Bea", neighborhood: "Roosevelt Island")
        let requests = [
            HelpRequest(
                id: RequestID(rawValue: UUID()),
                title: "Need 2 eggs for a cake",
                details: "Baking tonight and the store is closed.",
                category: .ingredient,
                location: TaggedLocation(
                    point: GeoPoint(latitude: 40.7560, longitude: -73.9555),
                    label: "Roosevelt Island"
                ),
                requesterID: bea.id,
                createdAt: Date().addingTimeInterval(-600)
            ),
            HelpRequest(
                id: RequestID(rawValue: UUID()),
                title: "Borrow a cup of rice",
                details: "",
                category: .ingredient,
                location: here,
                requesterID: alex.id,
                createdAt: Date().addingTimeInterval(-1200)
            ),
        ]
        let repository = PreviewRequestRepository(requests: requests)
        return AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            locationProvider: PreviewLocationProvider(location: here),
            session: PreviewSessionStore(availableUsers: [alex, bea], currentUser: alex),
            auth: PreviewAuthService(),
            locationSettings: PreviewLocationSettings(preset: LocationPreset(id: "preview-here", location: here))
        )
    }
}
