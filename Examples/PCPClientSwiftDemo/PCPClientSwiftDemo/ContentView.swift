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
        NavigationLink(destination: ApplePayExpressView()) { Text("Go to Apple Pay Express Checkout") }
        Spacer()

      }
      .padding()
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

    // Example: Custom validation icons (v1.4)
    // Uncomment and provide your own icon URLs to use custom icons.
    // let customIconsConfig = CustomIconsConfig(
    //   useCustomValidationIcons: true,
    //   showCardBrandIcons: true,
    //   successIcon: "https://your-cdn.com/icons/check.svg",
    //   errorIcon: "https://your-cdn.com/icons/error.svg"
    // )

    // Example: Click-to-Pay configuration (v1.4)
    // Uncomment and fill in your scheme credentials to enable CTP.
    // let ctpConfig = CTPConfig(
    //   schemeConfig: CTPSchemeConfig(
    //     merchantPresentationName: "YOUR_SHOP_NAME",
    //     visaConfig: CTPVisaConfig(
    //       srcInitiatorId: "YOUR_SRC_INITIATOR_ID",
    //       srcDpaId: "YOUR_SRC_DPA_ID"
    //     ),
    //     mastercardConfig: CTPMastercardConfig(
    //       srcInitiatorId: "YOUR_SRC_INITIATOR_ID",
    //       srcDpaId: "YOUR_SRC_DPA_ID"
    //     )
    //   ),
    //   transactionAmount: CTPTransactionAmount(amount: "36.98", currencyCode: "EUR"),
    //   enableCTP: true,
    //   enableCustomerOnboarding: true,
    //   uiConfig: CTPUIConfig(accentColor: "#0070ba")
    // )

    return CreditcardTokenizerView(
      tokenizerUrl: URL(string: "YOUR_URL")!,
      config: CreditcardTokenizerConfig(
        iframeConfig: IframeConfig(
          iframeWrapperId: "payment-IFrame",
          width: Double(400)
          // zIndex: 9999  // optional, defaults to 9999
        ),
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
        // v1.4 optional parameters:
        // email: "customer@example.com",
        // showCardholderName: true,
        // customIconsConfig: customIconsConfig,
        // ctpConfig: ctpConfig,
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

}

#Preview {
  ContentView()
}
