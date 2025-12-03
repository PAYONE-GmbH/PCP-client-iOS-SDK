//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PCPClient
import PassKit
import SwiftUI

struct ContentView: View {
  @State private var fingerprintToken = "-"
  private let fingerprintTokenizer = FingerprintTokenizer(
    paylaPartnerId: "YOUR_PARTNER_ID",
    partnerMerchantId: "YOUR_MERCHANT_ID",
    environment: .test
  )

  @State private var shouldShowApplePay = false
  @State private var applePayResult = "No Apple Pay result yet"
  private let applePayHandler = ApplePayHandler(
    processPaymentServerUrl: URL(string: "YOUR_PROCESS_PAYMENT_URL")!)

  @State private var creditcardTokenResult = ""

  var body: some View {
    NavigationView(content: {
      VStack(alignment: .leading, spacing: 8) {
        Button(
          action: {
            startFingerprintTokenizer()
          },
          label: {
            Text("Get Fingerprint Token")
          }
        )
        .frame(maxWidth: .infinity)
        Text("Fingerprint Token:")
        Text(fingerprintToken)
        NavigationLink(destination: creditcardTokenizer) { Text("Go to Creditcard Tokenizer") }
        NavigationLink(destination: PayPalWebPaymentsView()) { Text("Go to PayPal Web Payments") }
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
    })
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
          PKPaymentSummaryItem(label: "Item 2", amount: NSDecimalNumber(decimal: Decimal(2.99))),
        ]
        if shippingMethod.identifier == "free" {
          currentPaymentSummaryItems.append(
            PKPaymentSummaryItem(
              label: "Free Shipping", amount: NSDecimalNumber(decimal: Decimal(0.00)))
          )
          currentPaymentSummaryItems.append(
            PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: Decimal(36.98)))
          )
        } else if shippingMethod.identifier == "express" {
          currentPaymentSummaryItems.append(
            PKPaymentSummaryItem(
              label: "Express Shipping", amount: NSDecimalNumber(decimal: Decimal(10.00)))
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

  private var creditcardTokenizer: some View {
    // Example: Custom text configuration with multiple locales
    let customTextConfig: [String: LocaleTextConfig] = [
      "en": LocaleTextConfig(
        labels: LocaleTextLabels(
          cardNumber: "Card Number",
          cardholderName: "Cardholder Name",
          expiryDate: "Expiry Date",
          securityCode: "Security Code"
        ),
        placeholders: LocaleTextPlaceholders(
          cardNumber: "1234 5678 9012 3456",
          cardholderName: "John Doe",
          expiryDate: "MM/YY",
          securityCode: "CVV"
        ),
        arialabels: LocaleTextAriaLabels(
          cardNumber: "Enter your card number",
          cardholderName: "Enter the name on the card",
          expiryDate: "Enter the expiration month and year of your card",
          securityCode: "Enter the card verification code"
        ),
        errors: LocaleTextErrors(
          cardNumber: CardNumberErrors(
            isRequired: "Card number is required",
            isInvalid: "Invalid card number",
            isTooShort: "Card number is too short",
            notSupported: "Card type not supported"
          ),
          cardholderName: CardholderNameErrors(
            isRequired: "Cardholder name is required",
            isInvalid: "Invalid cardholder name"
          ),
          expiryDate: ExpiryDateErrors(
            isRequired: "Expiry date is required",
            isInvalid: "Invalid expiry date"
          ),
          securityCode: SecurityCodeErrors(
            isRequired: "Security code is required",
            amexCardSecurityCodeError: "Invalid Amex security code",
            generalSecurityCodeError: "Invalid security code"
          )
        )
      ),
      "de": LocaleTextConfig(
        labels: LocaleTextLabels(
          cardNumber: "Kartennummer",
          cardholderName: "Karteninhaber",
          expiryDate: "Ablaufdatum",
          securityCode: "Sicherheitscode"
        ),
        placeholders: LocaleTextPlaceholders(
          cardNumber: "1234 5678 9012 3456",
          cardholderName: "Max Mustermann",
          expiryDate: "MM/JJ",
          securityCode: "CVV"
        ),
        arialabels: LocaleTextAriaLabels(
          cardNumber: "Geben Sie Ihre Kartennummer ein",
          cardholderName: "Geben Sie den Namen auf der Karte ein",
          expiryDate: "Geben Sie den Ablaufmonat und das Jahr Ihrer Karte ein",
          securityCode: "Geben Sie den Kartenprüfcode ein"
        ),
        errors: LocaleTextErrors(
          cardNumber: CardNumberErrors(
            isRequired: "Kartennummer ist erforderlich",
            isInvalid: "Ungültige Kartennummer",
            isTooShort: "Kartennummer ist zu kurz",
            notSupported: "Kartentyp nicht unterstützt"
          ),
          cardholderName: CardholderNameErrors(
            isRequired: "Karteninhaber ist erforderlich",
            isInvalid: "Ungültiger Karteninhaber"
          ),
          expiryDate: ExpiryDateErrors(
            isRequired: "Ablaufdatum ist erforderlich",
            isInvalid: "Ungültiges Ablaufdatum"
          ),
          securityCode: SecurityCodeErrors(
            isRequired: "Sicherheitscode ist erforderlich",
            amexCardSecurityCodeError: "Ungültiger Amex-Sicherheitscode",
            generalSecurityCodeError: "Ungültiger Sicherheitscode"
          )
        )
      ),
      "fr": LocaleTextConfig(
        labels: LocaleTextLabels(
          cardNumber: "Numéro de carte",
          cardholderName: "Nom du titulaire",
          expiryDate: "Date d'expiration",
          securityCode: "Code de sécurité"
        ),
        placeholders: LocaleTextPlaceholders(
          cardNumber: "1234 5678 9012 3456",
          cardholderName: "Jean Dupont",
          expiryDate: "MM/AA",
          securityCode: "CVV"
        )
      )
    ]

    return CreditcardTokenizerView(
      tokenizerUrl: URL(string: "YOUR_URL")!,
      config: CreditcardTokenizerConfig(
        iframeConfig: IframeConfig(
          iframeWrapperId: "payment-IFrame", width: Double(400)),
        uiConfig: UIConfig(
          formBgColor: "#fff",
          fieldBgColor: "#f9f9f9",
          fieldBorder: "1px solid #000",
          fieldOutline: "none",
          fieldLabelColor: "#333",
          fieldPlaceholderColor: "#aaa",
          fieldTextColor: "#000",
          fieldErrorCodeColor: "#f00"
        ),
        // switch to en_US or fr_FR to see other locales
        locale: "de_DE",
        token: "<Token to be retrieved from the CommercePlatform-API>",  // Fetch this from your backend
        mode: "test",
        allowedCardSchemes: nil,
        customTextConfig: customTextConfig,
        submitButtonConfig: SubmitButtonConfig(selector: "#submit"),
        tokenizationSuccessCallback: { statusCode, token, cardDetails, inputMode in
          print("SuccessCallback statusCode:", statusCode)
          print("SuccessCallback token:", token)
          print("SuccessCallback cardDetails:", cardDetails)
          print("SuccessCallback inputMode:", inputMode)
        },
        tokenizationFailureCallback: { statusCode, errorResponse in
          print("FailureCallback statusCode:", statusCode)
          print("FailureCallback errorResponse:", errorResponse)
        }
      )
    )
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
      PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: Decimal(36.98))),
    ]
    request.requiredBillingContactFields = [.postalAddress, .emailAddress, .name]
    request.requiredShippingContactFields = [.postalAddress, .emailAddress, .name]
    let freeShipping = PKShippingMethod(
      label: "Free Shipping", amount: NSDecimalNumber(decimal: Decimal(0.00)), type: .final)
    freeShipping.identifier = "free"
    freeShipping.detail = "Arrives in 1-3 business days."
    let expressShipping = PKShippingMethod(
      label: "Express Shipping", amount: NSDecimalNumber(decimal: Decimal(10.00)), type: .final)
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
