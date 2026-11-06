import Foundation

/// TEMPORARY, for finding why UI tests are slow on GitHub's simulator (see docs/PROGRESS.md, Known issues).
/// A UI test run can launch the app with `-ciExperiment <name>` to turn one part of the Grove look off.
/// Users never pass it, so for them every check below is false. Remove this file once the cause is found.
enum CIExperiment {
    static let name: String? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-ciExperiment"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }()

    /// The system font instead of Figtree.
    static var systemFont: Bool { name == "systemFont" }
    /// No UIKit styling of the navigation bar, tab bar and segmented controls.
    static var noAppearance: Bool { name == "noAppearance" }
    /// A plain background color instead of `GroveBackground`.
    static var plainBackground: Bool { name == "plainBackground" }
    /// List rows without the card background.
    static var plainRows: Bool { name == "plainRows" }
}
