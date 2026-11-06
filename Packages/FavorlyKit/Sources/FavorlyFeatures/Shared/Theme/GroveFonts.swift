import Foundation
#if canImport(CoreText)
    import CoreText
#endif

/// Figtree, bundled with this module, registered for this process the first time a font is asked for.
/// If registering fails the names don't resolve and SwiftUI falls back to the system font, so text still shows.
enum GroveFonts {
    static let regular = "Figtree-Regular"
    static let medium = "Figtree-Medium"
    static let semiBold = "Figtree-SemiBold"
    static let bold = "Figtree-Bold"

    static let all = [regular, medium, semiBold, bold]

    /// Registers the fonts once; later calls do nothing.
    static func registerIfNeeded() {
        guard !CIExperiment.systemFont else { return }
        _ = registered
    }

    /// True once every bundled font file is registered (or was already, for example by an earlier test).
    static let registered: Bool = {
        #if canImport(CoreText)
            guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts"),
                  !urls.isEmpty
            else { return false }
            return urls.allSatisfy { url in
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    return true
                }
                // Already registered counts as success.
                let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
                return code == CTFontManagerError.alreadyRegistered.rawValue
            }
        #else
            return false
        #endif
    }()
}
