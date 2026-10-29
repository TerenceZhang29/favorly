import FavorlyCore
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

    var title = ""
    var details = ""
    var category = RequestCategory.other
    /// The neighborhood shown with the request. Starts as the location's name; the user may change it.
    var locationLabel = ""
    /// The name the last location came with, to tell whether the user changed `locationLabel`.
    @ObservationIgnored private var suggestedLabel = ""
    private(set) var locationState: LocationState = .loading
    private(set) var isSubmitting = false
    /// Why the last submit failed.
    private(set) var submitError: String?

    @ObservationIgnored private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
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

    /// What is wrong with the neighborhood, once the location is known.
    var locationLabelMessage: String? {
        guard taggedLocation != nil else { return nil }
        do {
            try DraftValidator.validateLocationLabel(locationLabel)
            return nil
        } catch {
            return ErrorMessage.text(for: error)
        }
    }

    var canSubmit: Bool {
        taggedLocation != nil && !isSubmitting && validationMessage(title: title, details: details) == nil
            && locationLabelMessage == nil
    }

    /// "Tagged at Cornell Tech, Roosevelt Island", following edits, or nil until the location is known.
    var locationText: String? {
        guard taggedLocation != nil else { return nil }
        let label = locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? "Tagged at your location" : "Tagged at \(label)"
    }

    // MARK: Loading and submitting

    func loadLocation() async {
        do {
            let location = try await environment.locationProvider.currentLocation()
            // Follow the new name unless the user wrote their own.
            if locationLabel.isEmpty || locationLabel == suggestedLabel {
                locationLabel = location.label
            }
            suggestedLabel = location.label
            locationState = .tagged(location)
        } catch is CancellationError {
            // A newer lookup replaced this one.
        } catch {
            locationState = error as? FavorlyError == .locationPermissionDenied
                ? .denied(ErrorMessage.text(for: error))
                : .failed(ErrorMessage.text(for: error))
        }
    }

    /// Posts the request as the current user. Returns it and clears the form on success.
    func submit() async -> HelpRequest? {
        guard canSubmit, let taggedLocation else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        submitError = nil

        do {
            let location = TaggedLocation(point: taggedLocation.point, label: locationLabel)
            let draft = NewRequestDraft(title: title, details: details, category: category, location: location)
            let request = try await environment.repository.create(draft, by: environment.session.currentUser.id)
            title = ""
            details = ""
            category = .other
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
        // Only the title and details matter here; the neighborhood has its own message.
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
