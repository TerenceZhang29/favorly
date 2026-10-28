import FavorlyCore
import Observation

/// Reporting a request, a message or a person: a reason, an optional note, and Send.
@MainActor
@Observable
final class ReportViewModel {
    var reason: ReportReason?
    var note = ""
    private(set) var isSending = false
    private(set) var didSend = false
    /// Why the last send failed.
    private(set) var sendError: String?

    let target: ReportTarget
    @ObservationIgnored private let environment: AppEnvironment

    init(target: ReportTarget, environment: AppEnvironment) {
        self.target = target
        self.environment = environment
    }

    var title: String {
        switch target {
        case .request: "Report request"
        case .message: "Report message"
        case .user: "Report person"
        }
    }

    var canSend: Bool {
        reason != nil && !isSending && !didSend && (try? ReportRules.validateNote(note)) != nil
    }

    func send() async {
        guard canSend, let reason else { return }
        isSending = true
        defer { isSending = false }
        sendError = nil

        do {
            try await environment.moderation.report(
                target, reason: reason, note: note, by: environment.session.currentUser.id
            )
            didSend = true
        } catch is CancellationError {
            // The sheet went away.
        } catch {
            sendError = ErrorMessage.text(for: error)
        }
    }
}
