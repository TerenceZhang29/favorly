import Foundation

public struct NewRequestDraft: Sendable {
    public var title: String
    public var details: String
    public var category: RequestCategory
    public var location: TaggedLocation
    /// Where to meet, such as "Cornell Tech lobby"; empty when not given.
    public var meetingSpot: String

    public init(
        title: String,
        details: String,
        category: RequestCategory,
        location: TaggedLocation,
        meetingSpot: String = ""
    ) {
        self.title = title
        self.details = details
        self.category = category
        self.location = location
        self.meetingSpot = meetingSpot
    }
}
