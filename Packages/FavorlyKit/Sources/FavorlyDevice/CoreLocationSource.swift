import CoreLocation
import FavorlyCore
import Foundation

/// `CLLocationManager` behind `LocationSource`: when-in-use permission, and one fix at about 100 m accuracy,
/// which is all Favorly keeps anyway.
@MainActor
public final class CoreLocationSource: NSObject, LocationSource {
    private let manager = CLLocationManager()
    private var authorizationWaiters: [CheckedContinuation<LocationAuthorization, Never>] = []
    private var pointWaiters: [CheckedContinuation<GeoPoint, any Error>] = []

    override public init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public var authorization: LocationAuthorization {
        Self.authorization(from: manager.authorizationStatus)
    }

    public func requestAuthorization() async -> LocationAuthorization {
        guard authorization == .notDetermined else { return authorization }
        return await withCheckedContinuation { continuation in
            authorizationWaiters.append(continuation)
            manager.requestWhenInUseAuthorization()
        }
    }

    public func currentPoint() async throws -> GeoPoint {
        try await withCheckedThrowingContinuation { continuation in
            pointWaiters.append(continuation)
            manager.requestLocation()
        }
    }

    nonisolated static func authorization(from status: CLAuthorizationStatus) -> LocationAuthorization {
        // Spelled without .authorizedWhenInUse, which macOS (where the package tests run) does not have.
        switch status {
        case .notDetermined: .notDetermined
        case .denied, .restricted: .denied
        default: .allowed
        }
    }

    fileprivate func answered(_ authorization: LocationAuthorization) {
        guard authorization != .notDetermined else { return }
        let waiters = authorizationWaiters
        authorizationWaiters = []
        waiters.forEach { $0.resume(returning: authorization) }
    }

    fileprivate func located(_ result: Result<GeoPoint, any Error>) {
        let waiters = pointWaiters
        pointWaiters = []
        waiters.forEach { $0.resume(with: result) }
    }
}

extension CoreLocationSource: CLLocationManagerDelegate {
    /// The manager was made on the main thread, so it calls back there.
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorization = Self.authorization(from: manager.authorizationStatus)
        MainActor.assumeIsolated { answered(authorization) }
    }

    public nonisolated func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let point = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        MainActor.assumeIsolated { located(.success(point)) }
    }

    public nonisolated func locationManager(_: CLLocationManager, didFailWithError _: any Error) {
        MainActor.assumeIsolated { located(.failure(FavorlyError.locationUnavailable)) }
    }
}
