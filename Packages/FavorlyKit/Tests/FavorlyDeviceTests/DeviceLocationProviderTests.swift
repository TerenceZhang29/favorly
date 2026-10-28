import FavorlyCore
@testable import FavorlyDevice
import Testing

@MainActor
struct DeviceLocationProviderTests {
    static let precise = GeoPoint(latitude: 40.75531, longitude: -73.95617)
    static let snapped = GeoPoint(latitude: 40.755, longitude: -73.956)

    @Test func anAllowedLocationIsSnappedAndNamed() async throws {
        let provider = DeviceLocationProvider(
            source: FakeLocationSource(authorization: .allowed, point: Self.precise),
            namer: FakeNeighborhoodNamer("Roosevelt Island")
        )
        #expect(try await provider.currentLocation() == TaggedLocation(point: Self.snapped, label: "Roosevelt Island"))
    }

    @Test func theFirstLoadAsksForPermission() async throws {
        let source = FakeLocationSource(authorization: .notDetermined, answer: .allowed, point: Self.precise)
        let provider = DeviceLocationProvider(source: source, namer: FakeNeighborhoodNamer("Roosevelt Island"))
        _ = try await provider.currentLocation()
        _ = try await provider.currentLocation()
        #expect(source.requests == 1)
    }

    @Test(arguments: [LocationAuthorization.notDetermined, .denied])
    func sayingNoOrHavingSaidNoIsPermissionDenied(start: LocationAuthorization) async {
        let source = FakeLocationSource(authorization: start, answer: .denied, point: Self.precise)
        let provider = DeviceLocationProvider(source: source, namer: FakeNeighborhoodNamer(nil))
        await #expect(throws: FavorlyError.locationPermissionDenied) {
            try await provider.currentLocation()
        }
    }

    @Test func aFailedFixIsLocationUnavailable() async {
        let provider = DeviceLocationProvider(
            source: FakeLocationSource(authorization: .allowed, point: nil),
            namer: FakeNeighborhoodNamer(nil)
        )
        await #expect(throws: FavorlyError.locationUnavailable) {
            try await provider.currentLocation()
        }
    }

    @Test func anUnnamedPlaceGetsAPlainLabel() async throws {
        let provider = DeviceLocationProvider(
            source: FakeLocationSource(authorization: .allowed, point: Self.precise),
            namer: FakeNeighborhoodNamer(nil)
        )
        #expect(try await provider.currentLocation().label == "Your neighborhood")
    }

    @Test func theNameIsLookedUpOncePerSquare() async throws {
        let source = FakeLocationSource(authorization: .allowed, point: Self.precise)
        let namer = FakeNeighborhoodNamer("Roosevelt Island")
        let provider = DeviceLocationProvider(source: source, namer: namer)
        _ = try await provider.currentLocation()
        source.point = GeoPoint(latitude: 40.75549, longitude: -73.95649) // the same 100 m square
        _ = try await provider.currentLocation()
        #expect(namer.lookupCount == 1)

        source.point = GeoPoint(latitude: 40.760, longitude: -73.950)
        _ = try await provider.currentLocation()
        #expect(namer.lookupCount == 2)
    }

    @Test func coreLocationStatusesMapToAuthorization() {
        #expect(CoreLocationSource.authorization(from: .notDetermined) == .notDetermined)
        #if os(iOS)
            #expect(CoreLocationSource.authorization(from: .authorizedWhenInUse) == .allowed)
        #endif
        #expect(CoreLocationSource.authorization(from: .authorizedAlways) == .allowed)
        #expect(CoreLocationSource.authorization(from: .denied) == .denied)
        #expect(CoreLocationSource.authorization(from: .restricted) == .denied)
    }

    @Test func theNeighborhoodNameFallsBackToTheCity() {
        #expect(GeocoderNeighborhoodNamer
            .name(subLocality: "Roosevelt Island", locality: "New York") == "Roosevelt Island")
        #expect(GeocoderNeighborhoodNamer.name(subLocality: nil, locality: "Ithaca") == "Ithaca")
        #expect(GeocoderNeighborhoodNamer.name(subLocality: " ", locality: "Ithaca") == "Ithaca")
        #expect(GeocoderNeighborhoodNamer.name(subLocality: nil, locality: nil) == nil)
    }
}
