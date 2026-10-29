import FavorlyCore
import SwiftUI

/// Every screen a navigation stack can push, registered once at the root of each tab's stack.
struct AppDestinations: ViewModifier {
    let environment: AppEnvironment

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: RequestID.self) { id in
                RequestDetailView(requestID: id, environment: environment)
            }
            .navigationDestination(for: UserID.self) { id in
                ProfileView(userID: id, environment: environment)
            }
            .navigationDestination(for: ChatDestination.self) { destination in
                ChatView(requestID: destination.requestID, environment: environment)
            }
    }
}
