import FavorlyCore
import Foundation

public enum DemoRequests {
    /// The seed set: fixed IDs, timestamps relative to `now`, and none posted by Alex.
    ///
    /// The first twelve are the Phase 1 set: six within 0.5 mi of Cornell Tech, three at 0.5–1.5 mi and three over
    /// 3 mi. Seeds 13–17 are favors completed days ago, so profiles have a history; none of them involve Alex.
    public static func all(now: Date = Date()) -> [HelpRequest] {
        let bea = DemoUsers.bea.id
        let chen = DemoUsers.chen.id
        let dana = DemoUsers.dana.id

        return [
            // Within 0.5 mi of Cornell Tech
            Seed(1, "Need 2 eggs for a cake", "Baking tonight and the store is closed.", chen,
                 "Roosevelt Island", 40.7560, -73.9555, minutesAgo: 12),
            Seed(2, "Borrow a cup of rice", "Any kind works. I can return it tomorrow.", bea,
                 "Roosevelt Island", 40.7570, -73.9548, minutesAgo: 25),
            Seed(3, "Help carrying a couch up 3 floors", "Two people needed, about 15 minutes.", bea,
                 "Roosevelt Island", 40.7580, -73.9540, minutesAgo: 40),
            Seed(4, "Jump start for a dead battery", "I have cables but no second car.", dana,
                 "Roosevelt Island", 40.7600, -73.9520, minutesAgo: 55),
            Seed(5, "Pick up a prescription bag from the pharmacy counter", "It is paid for and ready.", chen,
                 "Roosevelt Island", 40.7610, -73.9510, minutesAgo: 70),
            Seed(6, "Hold a ladder while I change a bulb", "Five minutes, hallway ceiling light.", dana,
                 "Roosevelt Island", 40.7540, -73.9570, minutesAgo: 90, status: .claimed, helper: chen),

            // 0.5–1.5 mi away
            Seed(7, "Walk my dog this evening", "Friendly beagle, 20 minutes around the block.", dana,
                 "Midtown East", 40.7555, -73.9690, minutesAgo: 30),
            Seed(8, "Borrow a hand truck for an hour", "Moving a small fridge down the hall.", chen,
                 "Long Island City", 40.7447, -73.9485, minutesAgo: 45),
            Seed(9, "Need a phone charger cable", "USB-C, just for the afternoon.", bea,
                 "Roosevelt Island north", 40.7700, -73.9430, minutesAgo: 60),

            // Over 3 mi away
            Seed(10, "Help moving boxes to storage", "Ten boxes, one elevator ride.", dana,
                 "Harlem", 40.8116, -73.9465, minutesAgo: 120),
            Seed(11, "Spare tire needs air", "Looking for a portable pump.", chen,
                 "Flushing", 40.7675, -73.8331, minutesAgo: 150),
            Seed(12, "Need a pinch of saffron", "For a paella, a few threads is plenty.", dana,
                 "Downtown Brooklyn", 40.6929, -73.9857, minutesAgo: 240, status: .completed, helper: bea),

            // History: completed days ago, with reviews in `DemoReviews`
            Seed(13, "Water my plants for the weekend", "Six pots on the balcony.", chen,
                 "Long Island City", 40.7440, -73.9490, minutesAgo: 3 * day, status: .completed, helper: bea),
            Seed(14, "Carry groceries up to the 4th floor", "The elevator is out again.", dana,
                 "Midtown East", 40.7545, -73.9690, minutesAgo: 4 * day, status: .completed, helper: bea),
            Seed(15, "Borrow a cordless drill", "Hanging two shelves.", chen,
                 "Long Island City", 40.7452, -73.9478, minutesAgo: 5 * day, status: .completed, helper: bea),
            Seed(16, "Need a cup of sugar", "Halfway through a batch of cookies.", dana,
                 "Midtown East", 40.7560, -73.9675, minutesAgo: 6 * day, status: .completed, helper: bea),
            Seed(17, "Tire pressure check before a road trip", "I have a gauge but no pump.", bea,
                 "Roosevelt Island", 40.7590, -73.9530, minutesAgo: 2 * day, status: .completed, helper: chen),
        ].map { $0.request(now: now) }
    }

    /// The fixed ID of seed request `number` (1–17).
    public static func id(_ number: UInt8) -> RequestID {
        RequestID(rawValue: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, number)))
    }

    /// Minutes in a day.
    private static let day: Double = 24 * 60

    private struct Seed {
        let number: UInt8
        let title: String
        let details: String
        let requester: UserID
        let label: String
        let latitude: Double
        let longitude: Double
        let minutesAgo: Double
        let status: RequestStatus
        let helper: UserID?

        init(
            _ number: UInt8,
            _ title: String,
            _ details: String,
            _ requester: UserID,
            _ label: String,
            _ latitude: Double,
            _ longitude: Double,
            minutesAgo: Double,
            status: RequestStatus = .open,
            helper: UserID? = nil
        ) {
            self.number = number
            self.title = title
            self.details = details
            self.requester = requester
            self.label = label
            self.latitude = latitude
            self.longitude = longitude
            self.minutesAgo = minutesAgo
            self.status = status
            self.helper = helper
        }

        func request(now: Date) -> HelpRequest {
            let createdAt = now.addingTimeInterval(-minutesAgo * 60)
            return HelpRequest(
                id: DemoRequests.id(number),
                title: title,
                details: details,
                location: TaggedLocation(point: GeoPoint(latitude: latitude, longitude: longitude), label: label),
                requesterID: requester,
                helperID: helper,
                status: status,
                createdAt: createdAt,
                // Seeded claims happened halfway between posting and now.
                claimedAt: helper == nil ? nil : now.addingTimeInterval(-minutesAgo * 30)
            )
        }
    }
}
