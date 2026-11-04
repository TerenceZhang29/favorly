import FavorlyCore

/// The neighborhood names the mock offers near each demo place, from what the server's `neighborhoods_near`
/// answers there. On Roosevelt Island the island comes first, where the server lists "Upper East Side" first.
public enum DemoNeighborhoods {
    /// Places farther than this from every entry have no data, like the server outside NYC.
    static let reach = 1000.0

    static let entries: [(point: GeoPoint, names: [String])] = [
        (
            LocationPresets.cornellTech.location.point,
            [
                "Roosevelt Island", "Upper East Side", "Lenox Hill", "Long Island City", "Hunters Point",
                "East Midtown", "Turtle Bay", "Queensbridge",
            ]
        ),
        (
            LocationPresets.rooseveltIslandNorth.location.point,
            [
                "Roosevelt Island", "Upper East Side", "Lenox Hill", "Yorkville", "Old Astoria", "Hallets Point",
                "Queensbridge", "Ravenswood",
            ]
        ),
        (
            LocationPresets.longIslandCity.location.point,
            ["Long Island City", "Hunters Point", "Sunnyside Yards", "Greenpoint"]
        ),
        (
            LocationPresets.midtownEast.location.point,
            [
                "East Midtown", "Turtle Bay", "United Nations", "Murray Hill", "Kips Bay", "Midtown", "Times Square",
                "Upper East Side",
            ]
        ),
    ]

    /// The names of the nearest entry within `reach`, or none.
    public static func names(near point: GeoPoint) -> [String] {
        entries
            .map { (distance: Distance.meters(from: point, to: $0.point), names: $0.names) }
            .filter { $0.distance <= reach }
            .min { $0.distance < $1.distance }?
            .names ?? []
    }
}
