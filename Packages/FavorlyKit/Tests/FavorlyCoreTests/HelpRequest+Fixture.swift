import FavorlyCore
import Foundation

extension UserID {
    static let requester = UserID(rawValue: "user-requester")
    static let helper = UserID(rawValue: "user-helper")
    static let stranger = UserID(rawValue: "user-stranger")
}

extension HelpRequest {
    /// A request posted by `.requester`. A claimed or completed one has `.helper` as its helper.
    static func fixture(status: RequestStatus = .open) -> HelpRequest {
        let wasClaimed = status == .claimed || status == .completed
        return HelpRequest(
            id: RequestID(rawValue: UUID()),
            title: "Need 2 eggs for a cake",
            details: "",
            location: TaggedLocation(point: GeoPoint(latitude: 40.7553, longitude: -73.9562), label: "Cornell Tech"),
            requesterID: .requester,
            helperID: wasClaimed ? .helper : nil,
            status: status,
            createdAt: Date(timeIntervalSince1970: 0),
            claimedAt: wasClaimed ? Date(timeIntervalSince1970: 60) : nil
        )
    }
}
