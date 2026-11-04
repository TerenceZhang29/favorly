import FavorlyCore
import Foundation
import Observation

@MainActor
@Observable
final class PostRequestViewModel {
    enum LocationState: Equatable {
        case loading
        case tagged(TaggedLocation)
        case failed(String)
        /// Location is off for Favorly; the form offers Settings instead of Retry.
        case denied(String)
    }

    /// Everything that should trigger a fresh location lookup when it changes.
    struct ReloadKey: Hashable {
        /// Nil on the device's own location.
        let preset: LocationPreset?
        let simulatesError: Bool
    }

    /// The names Post offers for the location, from `NeighborhoodDirectory`.
    enum NeighborhoodState: Equatable {
        case loading
        case loaded([String])
        case failed(String)
    }

    var title = ""
    var details = ""
    var category = RequestCategory.other
    /// The neighborhood shown with the request, one of the offered names.
    var neighborhood = ""
    /// Where to meet, such as "Cornell Tech lobby"; optional.
    var meetingSpot = ""
    private(set) var locationState: LocationState = .loading
    private(set) var neighborhoodState: NeighborhoodState = .loading
    private(set) var isSubmitting = false
    /// Why the last submit failed.
    private(set) var submitError: String?

    @ObservationIgnored private let environment: AppEnvironment
    /// Remembers the neighborhood of the last post, to offer it first next time. Never leaves the device.
    @ObservationIgnored private let defaults: UserDefaults
    static let lastNeighborhoodKey = "lastNeighborhood"

    init(environment: AppEnvironment, defaults: UserDefaults = .standard) {
        self.environment = environment
        self.defaults = defaults
    }

    var reloadKey: ReloadKey {
        ReloadKey(
            preset: environment.locationSettings?.selectedPreset,
            simulatesError: environment.locationSettings?.simulatesError ?? false
        )
    }

    // MARK: Live validation

    /// What is wrong with the title, once the user has typed something.
    var titleMessage: String? {
        title.isEmpty ? nil : validationMessage(title: title, details: "")
    }

    var detailsMessage: String? {
        validationMessage(title: "Valid title", details: details)
    }

    var meetingSpotMessage: String? {
        do {
            try DraftValidator.validateMeetingSpot(meetingSpot)
            return nil
        } catch {
            return ErrorMessage.text(for: error)
        }
    }

    /// The offered names, once they are known.
    var neighborhoodChoices: [String] {
        guard case let .loaded(choices) = neighborhoodState else { return [] }
        return choices
    }

    var canSubmit: Bool {
        taggedLocation != nil && neighborhoodChoices.contains(neighborhood) && !isSubmitting
            && validationMessage(title: title, details: details) == nil && meetingSpotMessage == nil
    }

    /// "Tagged at Roosevelt Island", following the picked neighborhood, or nil until the names are known.
    var locationText: String? {
        guard taggedLocation != nil, !neighborhoodChoices.isEmpty else { return nil }
        return "Tagged at \(neighborhood)"
    }

    // MARK: Loading and submitting

    func loadLocation() async {
        do {
            let location = try await environment.locationProvider.currentLocation()
            locationState = .tagged(location)
            await loadNeighborhoods()
        } catch is CancellationError {
            // A newer lookup replaced this one.
        } catch {
            locationState = error as? FavorlyError == .locationPermissionDenied
                ? .denied(ErrorMessage.text(for: error))
                : .failed(ErrorMessage.text(for: error))
        }
    }

    /// Asks for the names around the location. Where the directory has none (outside NYC), the location's own
    /// name is the only choice. Keeps the picked name if it is still offered, else the last post's, else the first.
    func loadNeighborhoods() async {
        guard let taggedLocation else { return }
        neighborhoodState = .loading
        do {
            var choices = try await environment.neighborhoods.neighborhoods(near: taggedLocation.point)
            if choices.isEmpty {
                choices = [taggedLocation.label]
            }
            let preferred = [neighborhood, defaults.string(forKey: Self.lastNeighborhoodKey)].compactMap(\.self)
            neighborhood = preferred.first(where: choices.contains) ?? choices[0]
            neighborhoodState = .loaded(choices)
        } catch is CancellationError {
            // A newer lookup replaced this one.
        } catch {
            neighborhoodState = .failed(ErrorMessage.text(for: error))
        }
    }

    /// Posts the request as the current user. Returns it and clears the form on success.
    func submit() async -> HelpRequest? {
        guard canSubmit, let taggedLocation else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        submitError = nil

        do {
            let location = TaggedLocation(point: taggedLocation.point, label: neighborhood)
            let draft = NewRequestDraft(
                title: title,
                details: details,
                category: category,
                location: location,
                meetingSpot: meetingSpot
            )
            let request = try await environment.repository.create(draft, by: environment.session.currentUser.id)
            defaults.set(neighborhood, forKey: Self.lastNeighborhoodKey)
            title = ""
            details = ""
            category = .other
            meetingSpot = ""
            // Now a notification is clearly useful: someone may pick this up.
            await environment.notifications.requestPermissionIfNeeded()
            return request
        } catch {
            submitError = ErrorMessage.text(for: error)
            return nil
        }
    }

    // MARK: Helpers

    private var taggedLocation: TaggedLocation? {
        guard case let .tagged(location) = locationState else { return nil }
        return location
    }

    private func validationMessage(title: String, details: String) -> String? {
        // Only the title and details matter here; the neighborhood is picked and the meeting spot has its own message.
        let location = TaggedLocation(point: GeoPoint(latitude: 0, longitude: 0), label: "Here")
        let draft = NewRequestDraft(title: title, details: details, category: category, location: location)
        do {
            try DraftValidator.validate(draft)
            return nil
        } catch {
            return ErrorMessage.text(for: error)
        }
    }
}
