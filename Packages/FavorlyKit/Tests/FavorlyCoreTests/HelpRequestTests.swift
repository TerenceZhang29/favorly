import FavorlyCore
import Foundation
import Testing

struct HelpRequestTests {
    @Test func newRequestDefaultsToOpenWithNoHelper() {
        let request = HelpRequest(
            id: RequestID(rawValue: UUID()),
            title: "Borrow a cup of rice",
            details: "",
            location: TaggedLocation(point: GeoPoint(latitude: 40.7553, longitude: -73.9562), label: "Cornell Tech"),
            requesterID: .requester,
            createdAt: Date(timeIntervalSince1970: 0)
        )
        #expect(request.status == .open)
        #expect(request.helperID == nil)
        #expect(request.claimedAt == nil)
    }

    @Test func requestSurvivesACodableRoundTrip() throws {
        let request = HelpRequest.fixture(status: .claimed)
        let decoded = try JSONDecoder().decode(HelpRequest.self, from: JSONEncoder().encode(request))
        #expect(decoded == request)
    }

    @Test func nearbyRequestTakesItsIdentityFromTheRequest() {
        let request = HelpRequest.fixture()
        #expect(NearbyRequest(request: request, distanceMeters: 12).id == request.id)
    }
}
