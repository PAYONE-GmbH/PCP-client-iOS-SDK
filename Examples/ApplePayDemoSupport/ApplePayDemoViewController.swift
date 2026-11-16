// UIKit example shared by the Objective-C standard and express entry points.
import PassKit
import UIKit

@objc public final class ApplePayDemoViewController: UIViewController {
    private let checkout: ApplePayDemoCheckout
    private let standardOrder: ApplePayDemoStandardOrder?
    private let result = UILabel()
    private let payButton = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)

    @objc public init(configuration: ApplePayDemoConfiguration, standardOrder: ApplePayDemoStandardOrder?) {
        self.standardOrder = standardOrder
        if let standardOrder {
            checkout = ApplePayDemoCheckout(configuration: configuration, standardOrder: standardOrder)
        } else {
            checkout = ApplePayDemoCheckout(configuration: configuration)
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("Use init(configuration:standardOrder:)") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = standardOrder == nil ? "Apple Pay Express Checkout" : "Apple Pay Standard Checkout"
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        let explanation = UILabel()
        explanation.numberOfLines = 0
        explanation.text = standardOrder?.summary ?? "Kontakt und Versand werden im Apple-Pay-Sheet ausgewählt."
        stack.addArrangedSubview(explanation)
        result.numberOfLines = 0
        result.text = "Demo – keine echte Zahlung"
        stack.addArrangedSubview(result)
        if checkout.supportsApplePay() {
            payButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            payButton.addTarget(self, action: #selector(startPayment), for: .touchUpInside)
            stack.addArrangedSubview(payButton)
        } else {
            result.text = "Apple Pay is not available."
        }
    }

    @objc private func startPayment() {
        payButton.isEnabled = false
        result.text = "Demo-Angebot wird geladen …"
        checkout.start { [weak self] message in
            self?.result.text = message
            self?.payButton.isEnabled = true
        }
    }
}
