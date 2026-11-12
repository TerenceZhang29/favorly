@testable import FavorlyFeatures
import Foundation
import Testing

struct FavorlyLogoTests {
    @Test(arguments: [false, true])
    func theLogoShipsAtTwoAndThreeTimesScale(dark: Bool) {
        for scale in ["@2x", "@3x"] {
            let name = FavorlyLogo.resourceName(dark: dark) + scale
            #expect(Bundle.module.url(forResource: name, withExtension: "png") != nil, "\(name).png is missing")
        }
    }
}
