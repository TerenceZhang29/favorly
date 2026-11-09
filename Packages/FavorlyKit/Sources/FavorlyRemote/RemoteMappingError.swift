import Foundation

/// The server sent a value the app does not know, such as a new status from a newer server.
enum RemoteMappingError: Error, Equatable {
    case unknownValue
}
