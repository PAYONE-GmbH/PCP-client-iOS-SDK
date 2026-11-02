// Native Apple Pay Express example. The configured backend simulates checkout.
import SwiftUI

struct ApplePayExpressView: View {
    @State private var checkout: ApplePayDemoCheckout?
    @State private var available = false
    @State private var busy = false
    @State private var result = "Apple Pay Express Demo – keine echte Zahlung"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apple Pay Express Demo – keine echte Zahlung")
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
        .navigationTitle("Apple Pay Express Checkout")
        .onAppear {
            do {
                if checkout == nil {
                    let configuration = try ApplePayDemoConfiguration.load(from: .main)
                    checkout = ApplePayDemoCheckout(configuration: configuration)
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
