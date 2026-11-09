import Foundation

public struct HelpRequest: Identifiable, Hashable, Codable, Sendable {
    public let id: RequestID
    public var title: String
    public var details: String
    public var location: TaggedLocation
    /// Where to meet, such as "Cornell Tech lobby"; empty when not given.
    public var meetingSpot: String
    public let requesterID: UserID
    /// Set when claimed.
    public var helperID: UserID?
    public var status: RequestStatus
    public let createdAt: Date
    public var claimedAt: Date?

    public init(
        id: RequestID,
        title: String,
        details: String,
        location: TaggedLocation,
        meetingSpot: String = "",
        requesterID: UserID,
        helperID: UserID? = nil,
        status: RequestStatus = .open,
        createdAt: Date,
        claimedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.location = location
        self.meetingSpot = meetingSpot
        self.requesterID = requesterID
        self.helperID = helperID
        self.status = status
        self.createdAt = createdAt
        self.claimedAt = claimedAt
    }
}
