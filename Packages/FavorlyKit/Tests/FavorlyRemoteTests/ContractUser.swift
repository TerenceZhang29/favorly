import FavorlyCore

/// One signed-up person in a contract test, with repositories that act as them.
struct ContractUser: Sendable {
    let id: UserID
    let requests: any RequestRepository
    let chat: any ChatRepository
    let reviews: any ReviewRepository
    let kindness: any KindnessRepository
    let moderation: any ModerationRepository
}
