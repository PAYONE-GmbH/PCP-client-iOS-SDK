import SwiftUI

/// SwiftUI navigation wrapper around the same configurable screen used by the Objective-C example.
struct CreditcardTokenizerDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        do {
            return CreditcardTokenizerDemoViewController(
                configuration: try CreditcardTokenizerDemoConfiguration.load(from: .main)
            )
        } catch {
            let controller = UIViewController()
            let label = UILabel()
            label.text = error.localizedDescription
            label.numberOfLines = 0
            label.textAlignment = .center
            controller.view = label
            return controller
        }
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}
