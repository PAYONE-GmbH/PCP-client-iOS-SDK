//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PCPClient
import SwiftUI

struct ContentView: View {
  @State private var fingerprintToken = "-"
  private let fingerprintTokenizer = FingerprintTokenizer(
    paylaPartnerId: "YOUR_PARTNER_ID",
    partnerMerchantId: "YOUR_MERCHANT_ID",
    environment: .test
  )

  var body: some View {
    NavigationView(content: {
      VStack(alignment: .leading, spacing: 8) {
        Button("Get Fingerprint Token", action: startFingerprintTokenizer)
          .frame(maxWidth: .infinity)
        Text("Fingerprint Token:")
        Text(fingerprintToken)
        NavigationLink(destination: CreditcardTokenizerDemoView()) { Text("Go to Creditcard Tokenizer") }
        NavigationLink(destination: PayPalWebPaymentsView()) { Text("Go to PayPal Web Payments") }
        NavigationLink(destination: ApplePayExpressView()) { Text("Go to Apple Pay Express Checkout") }
        Spacer()
      }
      .padding()
    })
  }

  private func startFingerprintTokenizer() {
    fingerprintTokenizer.getSnippetToken { result in
      switch result {
      case let .success(token): fingerprintToken = token
      case let .failure(error): fingerprintToken = error.localizedDescription
      }
    }
  }
}

#Preview { ContentView() }
