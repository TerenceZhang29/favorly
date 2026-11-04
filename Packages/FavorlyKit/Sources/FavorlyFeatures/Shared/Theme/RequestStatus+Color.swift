import FavorlyCore

extension RequestStatus {
    var badgeColors: BadgeColors {
        switch self {
        case .open: .lime
        case .claimed: .tint
        case .completed: .quiet
        case .cancelled: .outline
        }
    }
}
