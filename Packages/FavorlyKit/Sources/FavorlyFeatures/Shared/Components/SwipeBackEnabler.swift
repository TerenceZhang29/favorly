#if canImport(UIKit)
    import SwiftUI
    import UIKit

    /// Keeps swipe-to-go-back working on a screen whose back button is replaced: hiding the system back
    /// button otherwise turns the gesture off. Placed invisibly in the screen's background.
    struct SwipeBackEnabler: UIViewControllerRepresentable {
        func makeUIViewController(context _: Context) -> Controller {
            Controller()
        }

        func updateUIViewController(_: Controller, context _: Context) {}

        final class Controller: UIViewController {
            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                navigationController?.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
#endif
