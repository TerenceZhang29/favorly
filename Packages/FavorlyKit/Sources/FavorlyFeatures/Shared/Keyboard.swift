#if canImport(UIKit)
    import UIKit
#endif

/// Closes the on-screen keyboard, wherever focus is. Used before leaving a form, so the keyboard doesn't stay
/// open over the next screen.
enum Keyboard {
    @MainActor
    static func dismiss() {
        #if canImport(UIKit)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
