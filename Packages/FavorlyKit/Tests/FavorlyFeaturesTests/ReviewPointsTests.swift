import FavorlyCore
@testable import FavorlyFeatures
import Foundation
import Testing

/// The points preview on the review sheet, as in the Grove mockup.
@MainActor
struct ReviewPointsTests {
    let viewModel = ReviewFormViewModel(requestID: RequestID(rawValue: UUID()), environment: TestWorld().environment)

    @Test func beforeARatingItExplainsTheRule() {
        #expect(viewModel.pointsText(for: "Bea") == "Bea earns 10 points, plus 2 per star")
    }

    @Test(arguments: [(1, 12), (4, 18), (5, 20)])
    func eachRatingShowsWhatTheHelperEarns(rating: Int, points: Int) {
        viewModel.rating = rating
        #expect(viewModel.pointsText(for: "Bea") == "Bea earns +\(points) Kindness points for this favor")
    }
}
