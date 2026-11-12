import Foundation

/// Where each person has read up to in each thread, kept on the device. It powers the unread counts on the
/// Messages tab; the server keeps no read receipts, so the other person never sees it.
@MainActor
public protocol ChatReadStore: AnyObject, Sendable {
    /// The send time of the last message `user` saw in the thread of `request`; nil if they never opened it.
    func readUpTo(_ request: RequestID, for user: UserID) -> Date?
    /// Saves that `user` has seen the thread of `request` up to the message sent at `date`. Never moves back.
    func markRead(_ request: RequestID, upTo date: Date, for user: UserID)
}
