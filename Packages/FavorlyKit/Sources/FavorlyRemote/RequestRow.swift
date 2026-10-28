import FavorlyCore
import Foundation

/// A row of `public.requests`, or the request part of a `nearby_requests` row.
struct RequestRow: Decodable, Sendable {
    let id: UUID
    let title: String
    let details: String
    let category: String
    let latitude: Double
    let longitude: Double
    let locationLabel: String
    /// Nil once that person deleted their account.
    let requesterID: UUID?
    let helperID: UUID?
    let status: String
    let createdAt: Date
    let claimedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, details, category, latitude, longitude, status
        case locationLabel = "location_label"
        case requesterID = "requester_id"
        case helperID = "helper_id"
        case createdAt = "created_at"
        case claimedAt = "claimed_at"
    }

    func model() throws -> HelpRequest {
        guard let category = RequestCategory(rawValue: category), let status = RequestStatus(rawValue: status) else {
            throw RemoteMappingError.unknownValue
        }
        return HelpRequest(
            id: RequestID(rawValue: id),
            title: title,
            details: details,
            category: category,
            location: TaggedLocation(point: GeoPoint(latitude: latitude, longitude: longitude), label: locationLabel),
            requesterID: requesterID.map(UserID.init(remote:)) ?? .deletedUser,
            helperID: helperID.map(UserID.init(remote:)),
            status: status,
            createdAt: createdAt,
            claimedAt: claimedAt
        )
    }
}
