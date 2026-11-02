// Two explicit entry points, sharing the UI and merchant-backend adapter.
import SwiftUI

struct ApplePayExpressView: View {
    var body: some View { ApplePayCheckoutView(standard: false) }
}

struct ApplePayStandardView: View {
    var body: some View { ApplePayCheckoutView(standard: true) }
}

private struct ApplePayCheckoutView: View {
    let standard: Bool
    @State private var checkout: ApplePayDemoCheckout?
    @State private var standardOrder: ApplePayDemoStandardOrder?
    @State private var available = false
    @State private var busy = false
    @State private var result = "Demo – keine echte Zahlung"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Demo – keine echte Zahlung")
            if let standardOrder {
                Text("Bestelldaten vor Apple Pay").font(.headline)
                Text(standardOrder.summary)
            } else if !standard {
                Text("Kontakt und Versand werden im Apple-Pay-Sheet ausgewählt.")
            }
            if available {
                ApplePayButton(action: startPayment, isEnabled: !busy)
                    .frame(height: 44)
            } else {
                Text("Apple Pay is not available.")
            }
            Text(result)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(standard ? "Apple Pay Standard Checkout" : "Apple Pay Express Checkout")
        .onAppear {
            do {
                if checkout == nil {
                    let configuration = try ApplePayDemoConfiguration.load(from: .main)
                    if standard {
                        let order = try ApplePayDemoStandardOrder.load(from: .main)
                        standardOrder = order
                        checkout = ApplePayDemoCheckout(configuration: configuration, standardOrder: order)
                    } else {
                        checkout = ApplePayDemoCheckout(configuration: configuration)
                    }
                }
                available = checkout?.supportsApplePay() == true
            } catch {
                result = error.localizedDescription
                available = false
            }
        }
    }

    private func startPayment() {
        guard !busy, let checkout, checkout.supportsApplePay() else { return }
        busy = true
        result = "Demo-Versandangebot wird geladen …"
        checkout.start { message in
            result = message
            busy = false
        }
    }
}
