//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import SwiftUI
import PCPClient
import PassKit

struct ContentView: View {
    @State private var fingerprintToken = "-"
    private let fingerprintTokenizer = FingerprintTokenizer(
        paylaPartnerId: "YOUR_PARTNER_ID",
        partnerMerchantId: "YOUR_MERCHANT_ID",
        environment: .test
    )

    @State private var shouldShowApplePay = false
    @State private var applePayResult = "No Apple Pay result yet"
    private let applePayHandler = ApplePayHandler(processPaymentServerUrl: URL(string: "YOUR_PROCESS_PAYMENT_URL")!)

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
            
            if shouldShowApplePay {
                ApplePayButton()
                    .onTapGesture {
                        startPayment()
                    }
                    .frame(height: 30)
            }
            Text(applePayResult)
        }
        .padding()
        .onAppear {
            shouldShowApplePay = applePayHandler.supportsApplePay()
        }
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

    private func startPayment() {
        let request = makeRequest()
        if applePayHandler.supportsApplePay() {
            applePayHandler.onShippingMethodDidChange = { shippingMethod in
                var currentPaymentSummaryItems = [
                    PKPaymentSummaryItem(label: "Item 1", amount: NSDecimalNumber(decimal: Decimal(33.99))),
                    PKPaymentSummaryItem(label: "Item 2", amount: NSDecimalNumber(decimal: Decimal(2.99)))
                ]
                if shippingMethod.identifier == "free" {
                    currentPaymentSummaryItems.append(
                        PKPaymentSummaryItem(label: "Free Shipping", amount: NSDecimalNumber(decimal: Decimal(0.00)))
                    )
                    currentPaymentSummaryItems.append(
                        PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: Decimal(36.98)))
                    )
                } else if shippingMethod.identifier == "express" {
                    currentPaymentSummaryItems.append(
                        PKPaymentSummaryItem(label: "Express Shipping", amount: NSDecimalNumber(decimal: Decimal(10.00)))
                    )
                    currentPaymentSummaryItems.append(
                        PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: Decimal(46.98)))
                    )
                }
                return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: currentPaymentSummaryItems)
            }
            applePayHandler.startPayment(
                request: request,
                onDidSelectPaymentMethod: { _ in
                    PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: request.paymentSummaryItems)
                }
            ) { success in
                if success {
                    applePayResult = "Success"
                } else {
                    applePayResult = "Failed"
                }
            }
        } else {
            applePayResult = "Apple Pay is not available."
        }
    }

    private func makeRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "YOUR_MERCHANT_IDENTIFIER"
        request.supportedNetworks = [.visa, .girocard]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "DE"
        request.currencyCode = "EUR"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Item 1", amount: NSDecimalNumber(decimal: Decimal(33.99))),
            PKPaymentSummaryItem(label: "Item 2", amount: NSDecimalNumber(decimal: Decimal(2.99))),
            PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: Decimal(36.98)))
        ]
        request.requiredBillingContactFields = [.postalAddress, .emailAddress, .name]
        request.requiredShippingContactFields = [.postalAddress, .emailAddress, .name]
        let freeShipping = PKShippingMethod(label: "Free Shipping", amount: NSDecimalNumber(decimal: Decimal(0.00)), type: .final)
        freeShipping.identifier = "free"
        freeShipping.detail = "Arrives in 1-3 business days."
        let expressShipping = PKShippingMethod(label: "Express Shipping", amount: NSDecimalNumber(decimal: Decimal(10.00)), type: .final)
        expressShipping.identifier = "express"
        expressShipping.detail = "Arrives tomorrow"
        request.shippingMethods = [freeShipping, expressShipping]
        request.applicationData = Data()
        return request
    }
}

#Preview {
    ContentView()
}
