//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import SwiftUI
import PCPClient

struct ContentView: View {
    @State private var fingerprintToken = "-"
    private let fingerprintTokenizer = FingerprintTokenizer(
        paylaPartnerId: "YOUR_PARTNER_ID",
        partnerMerchantId: "YOUR_MERCHANT_ID",
        environment: .test
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                startFingerprintTokenizer()
            }, label: {
                Text("Get Fingerprint Token")
            })
            .frame(maxWidth: .infinity)
            Text("Fingerprint Token:")
            Text(fingerprintToken)
            Spacer()
        }
        .padding()
    }

    private func startFingerprintTokenizer() {
        fingerprintTokenizer.getSnippetToken { result in
            switch result {
            case let .success(token):
                fingerprintToken = token
            case let .failure(error):
                fingerprintToken = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
}
