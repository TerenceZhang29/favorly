import FavorlyCore
import Testing

struct LocationPrivacyTests {
    @Test func aPointIsRoundedToThreeDecimalPlaces() {
        let snapped = LocationPrivacy.snapped(GeoPoint(latitude: 40.75531, longitude: -73.95617))
        #expect(snapped == GeoPoint(latitude: 40.755, longitude: -73.956))
    }

    @Test func halvesRoundAwayFromZero() {
        let snapped = LocationPrivacy.snapped(GeoPoint(latitude: 40.7555, longitude: -73.9565))
        #expect(snapped == GeoPoint(latitude: 40.756, longitude: -73.957))
    }

    @Test func aSnappedPointMovesLessThan100Meters() {
        let point = GeoPoint(latitude: 40.75549, longitude: -73.95649)
        #expect(Distance.meters(from: point, to: LocationPrivacy.snapped(point)) < 100)
    }

    @Test func snappingTwiceChangesNothing() {
        let once = LocationPrivacy.snapped(GeoPoint(latitude: 40.75531, longitude: -73.95617))
        #expect(LocationPrivacy.snapped(once) == once)
    }
}
