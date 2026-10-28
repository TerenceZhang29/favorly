import FavorlyCore
@testable import FavorlyRemote
import Foundation
import Supabase
import Testing

/// Decodes JSON shaped like PostgREST's responses with the SDK's own decoder.
struct RowMappingTests {
    private func decode<T: Decodable>(_: T.Type, _ json: String) throws -> T {
        try PostgrestClient.Configuration.jsonDecoder.decode(T.self, from: Data(json.utf8))
    }

    static let requestJSON = """
    {"id": "5a3dac11-dd4c-453a-a9c5-1f88f82693ef", "title": "Need a cup of rice", "details": "Cooking tonight",
     "category": "ingredient", "latitude": 40.755, "longitude": -73.956,
     "location": "0101000020E610000077BE9F1A2F7D52C0713D0AD7A3604440", "location_label": "Roosevelt Island",
     "requester_id": "9F77130F-1396-4761-B317-9B422B16C155", "helper_id": null, "status": "open",
     "created_at": "2026-10-28T18:35:14.665619+00:00", "claimed_at": null
    """

    @Test func aRequestRowBecomesAHelpRequest() throws {
        let request = try decode(RequestRow.self, Self.requestJSON + "}").model()
        #expect(request.id.rawValue == UUID(uuidString: "5a3dac11-dd4c-453a-a9c5-1f88f82693ef"))
        #expect(request.title == "Need a cup of rice")
        #expect(request.category == .ingredient)
        #expect(request.location == TaggedLocation(
            point: GeoPoint(latitude: 40.755, longitude: -73.956), label: "Roosevelt Island"
        ))
        #expect(request.requesterID == UserID(rawValue: "9f77130f-1396-4761-b317-9b422b16c155"))
        #expect(request.helperID == nil)
        #expect(request.status == .open)
        #expect(request.createdAt.timeIntervalSince1970.rounded() == 1_793_212_515)
        #expect(request.claimedAt == nil)
    }

    @Test func aDeletedRequesterBecomesAPlaceholder() throws {
        let json = Self.requestJSON.replacingOccurrences(
            of: "\"9F77130F-1396-4761-B317-9B422B16C155\"", with: "null"
        ) + "}"
        #expect(try decode(RequestRow.self, json).model().requesterID == .deletedUser)
    }

    @Test func anUnknownCategoryIsAnError() {
        let json = Self.requestJSON.replacingOccurrences(of: "\"ingredient\"", with: "\"gardening\"") + "}"
        #expect(throws: RemoteMappingError.unknownValue) {
            try decode(RequestRow.self, json).model()
        }
    }

    @Test func aNearbyRowCarriesTheDistance() throws {
        let nearby = try decode(NearbyRow.self, Self.requestJSON + ", \"distance_m\": 42.5}").model()
        #expect(nearby.distanceMeters == 42.5)
        #expect(nearby.request.title == "Need a cup of rice")
    }

    @Test func messageReviewProfileAndKindnessRows() throws {
        let message = try decode(MessageRow.self, """
        {"id": "00000000-0000-0000-0000-000000000001", "request_id": "00000000-0000-0000-0000-000000000002",
         "sender_id": "00000000-0000-0000-0000-00000000000A", "text": "On my way",
         "sent_at": "2026-10-28T18:35:14+00:00"}
        """).model()
        #expect(message.senderID == UserID(rawValue: "00000000-0000-0000-0000-00000000000a"))
        #expect(message.text == "On my way")

        let review = try decode(ReviewRow.self, """
        {"id": "00000000-0000-0000-0000-000000000003", "request_id": "00000000-0000-0000-0000-000000000002",
         "reviewer_id": "00000000-0000-0000-0000-00000000000a", "reviewee_id": "00000000-0000-0000-0000-00000000000b",
         "rating": 5, "comment": "Fast and friendly", "created_at": "2026-10-28T18:35:14.1+00:00"}
        """).model()
        #expect(review.rating == 5)
        #expect(review.revieweeID == UserID(rawValue: "00000000-0000-0000-0000-00000000000b"))

        let profile = try decode(ProfileRow.self, """
        {"id": "00000000-0000-0000-0000-00000000000b", "display_name": "Bea", "neighborhood": ""}
        """).model()
        #expect(profile.displayName == "Bea")

        let summary = try decode(KindnessRow.self, """
        {"completed_favors": 2, "review_count": 2, "average_rating": 4.5, "lifetime_points": 38}
        """).model()
        #expect(summary == KindnessSummary(
            completedFavors: 2, reviewCount: 2, averageRating: 4.5, lifetimePoints: 38, redeemedPoints: 0
        ))
    }
}
