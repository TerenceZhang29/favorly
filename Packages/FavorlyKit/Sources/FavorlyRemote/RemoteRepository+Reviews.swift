import FavorlyCore
import Foundation
import Supabase

extension RemoteRepository: ReviewRepository {
    public func reviews(about user: UserID) async throws -> [Review] {
        guard let id = user.remoteID else { return [] }
        let rows: [ReviewRow] = try await call {
            try await client.from("reviews")
                .select()
                .eq("reviewee_id", value: id)
                .order("created_at", ascending: false)
                .execute()
                .value
        }
        let reviews = rows.map { $0.model() }
        await directory.load(Set(reviews.flatMap { [$0.reviewerID, $0.revieweeID] }))
        return reviews
    }

    public func review(for request: RequestID) async throws -> Review? {
        let rows: [ReviewRow] = try await call {
            try await client.from("reviews").select().eq("request_id", value: request.rawValue).limit(1).execute().value
        }
        return rows.first?.model()
    }

    public func submitReview(_ draft: NewReviewDraft, for request: RequestID, by _: UserID) async throws -> Review {
        let draft = try ReviewRules.validate(draft)
        let params: [String: AnyJSON] = [
            "request_id": .string(request.rawValue.uuidString),
            "rating": .integer(draft.rating),
            "comment": .string(draft.comment),
        ]
        let row: ReviewRow = try await call {
            try await client.rpc(
                "submit_review",
                params: params
            ).execute().value
        }
        broadcaster.send()
        return row.model()
    }
}
