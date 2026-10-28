import FavorlyCore
import Foundation

/// A row of `nearby_requests`: the request's columns plus its distance.
struct NearbyRow: Decodable, Sendable {
    let request: RequestRow
    let distanceMeters: Double

    enum CodingKeys: String, CodingKey {
        case distanceMeters = "distance_m"
    }

    init(from decoder: any Decoder) throws {
        request = try RequestRow(from: decoder)
        distanceMeters = try decoder.container(keyedBy: CodingKeys.self).decode(Double.self, forKey: .distanceMeters)
    }

    func model() throws -> NearbyRequest {
        try NearbyRequest(request: request.model(), distanceMeters: distanceMeters)
    }
}
