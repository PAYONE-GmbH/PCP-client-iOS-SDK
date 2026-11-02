# PCPClient SDK iOS

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=PAYONE-GmbH_PCP-client-iOS-SDK&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=PAYONE-GmbH_PCP-client-iOS-SDK)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=PAYONE-GmbH_PCP-client-iOS-SDK&metric=coverage)](https://sonarcloud.io/summary/new_code?id=PAYONE-GmbH_PCP-client-iOS-SDK)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![CocoaPods](https://img.shields.io/cocoapods/v/PCPClient.svg?style=flat)](https://cocoapods.org/pods/PCPClient)
![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)
[![GitHub License](https://img.shields.io/github/license/PAYONE-GmbH/PCP-client-iOS-SDK)](https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK/blob/main/LICENSE)

Welcome to the PAYONE Commerce Platform Client iOS SDK for the PAYONE Commerce Platform. This SDK provides everything a client needs to easily complete payments using Credit or Debit Card, PAYONE Buy Now Pay Later (BNPL) and Apple Pay.

## Table of Contents

- [Supported Languages and iOS Version](#supported-languages-and-ios-versions)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Creditcard Tokenizer](#creditcard-tokenizer)
    - [SDK integration guide](docs/creditcard-tokenizer.md)
    - [Runnable Swift and Objective-C examples](Examples/CreditcardTokenizerDemoSupport/README.md)
    - [Configuration reference](#creditcardtokenizerconfig-parameters)
  - [Fingerprint Tokenizer](#fingerprint-tokenizer)
    - [1. Import PCPClient modules](#1-import-pcpclient-modules)
    - [2. Create a new Fingerprint tokenizer instance](#2-create-a-new-fingerprint-tokenizer-instance)
    - [3. Get the snippet token](#3-get-the-snippet-token)
  - [Apple Pay Session Integration](#apple-pay-session-integration)
    - [Standard and Express flow comparison](docs/apple-pay.md)
    - [Apple Pay Standard integration guide](docs/apple-pay-standard.md)
    - [Apple Pay Express integration guide](docs/apple-pay-express.md)
    - [Runnable Swift and Objective-C examples](Examples/ApplePayDemoSupport/README.md)
  - [PayPal Web Payments Integration](#paypal-web-payments-integration)
    - [1. Add PayPal dependencies](#1-add-paypal-dependencies)
    - [2. Create the PayPal view and view model](#2-create-the-paypal-view-and-view-model)
    - [3. Initialize and configure PayPal client](#3-initialize-and-configure-paypal-client)
    - [4. Create order on your server](#4-create-order-on-your-server)
    - [5. Process the PayPal payment](#5-process-the-paypal-payment)
    - [6. Handle the payment result](#6-handle-the-payment-result)
- [Demonstration Projects](#demonstration-projects)
- [Contributing](#contributing)
- [Releasing the library](#releasing-the-library)
- [License](#license)

## Supported Languages and iOS Versions

The SDK supports Swift and Objective-C. For Objective-C the Bridge Module is needed. For Swift only the main module is needed.

In order to use the SDK you need to have at least iOS 15.

## Features

- **Creditcard Tokenizer**: Securely tokenize credit and debit card information.
- **Fingerprint Tokenizer**: Generate unique tokens for device fingerprinting.
- **Apple Pay Session Integration**: Seamlessly integrate Apple Pay into your payment workflow.
- **PayPal Web Payments Integration**: Integrate PayPal as a payment method with a streamlined browser-based checkout.

## Installation

### Swift Package Manager (SPM)

To integrate using Apple's Swift package manager, you have two options.

#### Package.swift

Add the following as a dependency to your `Package.swift`:

```swift
.package(url: "https://https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK.git", .upToNextMajor(from: "1.4.0"))
```

and then specify `"PCPClient"` as a dependency of the Target in which you wish to use PCPClient.
Here's an example `PackageDescription`:

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyPackage",
    products: [
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK.git", .upToNextMajor(from: "1.4.0"))
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: ["PCPClient"])
    ]
)
```

#### Via Xcode

Select `File` -> `Add Package Dependencies...`. In the upcoming dialog paste the URL of this repository.

```
https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK
```

Specify the version you want to use and click on 'Add Package'. This will pop up a dialog to chose which package products should be added to your target.

For Swift add `PCPClient` to your target and select `None` in the `Add to target` dropdown for `PCPClientBridge`.

For Objective-C add both package products to your target.

Finally, click again on 'Add Package'.

### CocoaPods

Add the following entry to your Podfile:

**Swift**

```rb
pod 'PCPClient'
```

**Objective-C**

```rb
pod 'PCPClient/PCPClientBridge'
```

Then run `pod install`.

Don't forget to import the module(s) in every file you'd like to use PCPClient.

**Swift**

```swift
import PCPClient
```

**Objective-C**

```objectivec
@import PCPClient;
```

> [!NOTE]
> When using SPM for the integration in an Objective-C project, you will also need the following import: `@import PCPClientBridge;`. If you did the integration via CocoaPods, simply importing PCPClient will be enough.

## Usage

### Creditcard Tokenizer

The Creditcard Tokenizer loads PAYONE Hosted Tokenization SDK 1.4.0 in a native WebKit view and returns a card token for use by your backend. Tokenization does not authorize a payment.

- **[SDK integration guide](docs/creditcard-tokenizer.md):** runtime token handling, hosted/bundled HTML, HTTPS base origin, SwiftUI/UIKit/Objective-C usage, callbacks/errors, diagnostics and lifecycle.
- **[Runnable examples](Examples/CreditcardTokenizerDemoSupport/README.md):** shared configurable screen, editable plist, token input and Requests & Responses trace. Tokens are entered at runtime; changing an expired token no longer requires rebuilding the app.
- **[Configuration reference](#creditcardtokenizerconfig-parameters):** advanced styling, custom text/icons and Click-to-Pay types retained below.

> **Hosted Tokenization SDK version history**
> - **v1.0** – Initial release
> - **v1.0.2** – Added `iframe.zIndex` config; added font customization (`fontFamily`, `fontUrl`, `labelStyle`, `inputStyle`, `errorValidationStyle`) to `uiConfig`
> - **v1.2** – Added `allowedCardSchemes` to restrict accepted card brands
> - **v1.3** – Added `customTextConfig` for per-locale text overrides; added Click-to-Pay support (`CTPConfig`); extended `uiConfig` with button, separator, checkbox, terms, border-radius and spacing properties; added `manualEntryFormLabelStyle`, `checkboxLabelStyle`, `termsTextStyle` to `uiConfig`
> - **v1.4** – Added `customIconsConfig` for custom validation icons; added `showCardholderName` to toggle the cardholder name field; added top-level `email` parameter; added `fontSizeMobile` to `FontStyle`; added `inputMode` to the success callback; updated `uiConfig` with remaining spacing and icon properties

#### Configuration reference

The following advanced options supplement the [step-by-step integration guide](docs/creditcard-tokenizer.md).

##### CreditcardTokenizerConfig parameters

| Parameter | Type | Required | Since | Description |
|-----------|------|----------|-------|-------------|
| `iframeConfig` | `IframeConfig` | Yes | v1.0 | Container, size and z-index for the payment iframe |
| `uiConfig` | `UIConfig?` | No | v1.0 | Visual appearance of the form |
| `locale` | `String?` | No | v1.0 | Language locale for the form (e.g. `"de_DE"`, `"en_US"`) |
| `token` | `String` | Yes | v1.0 | JWT from your backend (CommercePlatform-API) |
| `mode` | `String?` | No | v1.0 | `"live"` or `"test"` (defaults to `"test"`) |
| `allowedCardSchemes` | `[String]?` | No | v1.2 | Restrict accepted card brands in lowercase, e.g. `["visa", "mastercard", "amex", "diners", "discover", "jcb", "maestro", "unionpay"]`. All brands allowed if omitted. |
| `customTextConfig` | `[String: LocaleTextConfig]?` | No | v1.3 | Per-locale overrides for labels, placeholders, aria-labels and error messages |
| `submitButtonConfig` | `SubmitButtonConfig` | Yes | v1.0 | CSS selector of the submit button in your HTML |
| `email` | `String?` | No | v1.4 | Pre-filled email address (used by Click-to-Pay) |
| `showCardholderName` | `Bool` | No | v1.4 | Show or hide the cardholder name field (defaults to `true`) |
| `customIconsConfig` | `CustomIconsConfig?` | No | v1.4 | Custom validation icons – see reference below |
| `ctpConfig` | `CTPConfig?` | No | v1.3 | Click-to-Pay configuration – see reference below |
| `tokenizationSuccessCallback` | `(Int, String, CardDetails, String) -> Void` | No | v1.0 | Called on success with status code, token, card details and input mode |
| `tokenizationFailureCallback` | `(Int, [String: Any]) -> Void` | No | v1.0 | Called on failure with status code and error response |

##### Tokenization callbacks

**Success callback** – `(statusCode: Int, token: String, cardDetails: CardDetails, inputMode: String)`

| Parameter | Description |
|-----------|-------------|
| `statusCode` | HTTP-style status code; `201` indicates successful tokenization |
| `token` | Card token returned by PAYONE; pass it to your backend and follow its usage/lifetime contract |
| `cardDetails` | Truncated card data (see `CardDetails` below) |
| `inputMode` | Method used for tokenization: `"manual"`, `"register"` or `"ClickToPay"` |

`CardDetails` properties:

| Property | Type | Description |
|----------|------|-------------|
| `cardholderName` | `String` | Name of the cardholder as entered |
| `cardNumber` | `String` | Truncated card number (e.g. `411111XXXXXX1111`) |
| `expiryDate` | `String` | Card expiry in MMYY format (e.g. `1133` = November 2033) |
| `cardType` | `String` | Card scheme (e.g. `VISA`, `MASTERCARD`) |

**Failure callback** – `(statusCode: Int, errorResponse: [String: Any])`

| Parameter | Description |
|-----------|-------------|
| `statusCode` | HTTP-style error code; `400` typically indicates invalid input |
| `errorResponse` | Error details – use `errorResponse["error"]` for a descriptive message |

##### IframeConfig parameters

| Parameter | Type | Required | Since | Description |
|-----------|------|----------|-------|-------------|
| `iframeWrapperId` | `String` | Yes | v1.0 | ID of the HTML element that wraps the payment iframe |
| `height` | `Double?` | No | v1.0 | Initial height of the iframe in pixels; defaults to 400 when omitted. PAYONE may adjust it after loading. |
| `width` | `Double?` | No | v1.0 | Maximum width of the iframe in pixels (defaults to `400`) |
| `zIndex` | `Int?` | No | v1.0.2 | CSS z-index of the iframe (defaults to `9999`) |

##### UIConfig parameters

All properties are optional. Supported file formats for `fontUrl`: `.woff2`, `.woff`, `.ttf`, `.otf`, `.eot`, `.svg`, `.sfnt`.

**Basic appearance** (since v1.0)

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `formBgColor` | `String?` | Background color of the entire form | `"#E9EEF5"` |
| `formMarginLeft` | `String?` | Left margin of the form (since v1.3) | `"20px"` |
| `formMarginRight` | `String?` | Right margin of the form (since v1.3) | `"20px"` |
| `fieldBgColor` | `String?` | Background color of input fields | `"#FDFDFD"` |
| `fieldBorder` | `String?` | CSS border for input fields | `"#8FA8C8 solid 2px"` |
| `fieldOutline` | `String?` | CSS outline on focus/active | `"#3B82F6 solid 3px"` |
| `fieldLabelColor` | `String?` | Color of field labels | `"#334155"` |
| `fieldPlaceholderColor` | `String?` | Color of placeholder text | `"#6B7280"` |
| `fieldTextColor` | `String?` | Color of text entered by the user | `"#1E293B"` |
| `fieldErrorCodeColor` | `String?` | Color of validation error messages | `"#D97706"` |

**Font customization** (since v1.0.2, `fontSizeMobile` since v1.4)

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `fontFamily` | `String?` | CSS font-family for the form | `"Sansation"` |
| `fontUrl` | `String?` | URL to load a custom web font | `"https://fonts.googleapis.com/..."` |
| `labelStyle` | `FontStyle?` | Font size/weight for field labels | see below |
| `inputStyle` | `FontStyle?` | Font size/weight for input text | see below |
| `errorValidationStyle` | `FontStyle?` | Font size/weight for error messages | see below |
| `manualEntryFormLabelStyle` | `FontStyle?` | Font size/weight for "Manually enter your card details" label (since v1.3) | see below |
| `checkboxLabelStyle` | `FontStyle?` | Font size/weight for checkbox labels (since v1.3) | see below |
| `termsTextStyle` | `FontStyle?` | Font size/weight for terms & privacy text (since v1.3) | see below |

`FontStyle` has three optional `String` properties:
- `fontSize` – unit value (e.g. `"20px"`, `"1.2rem"`)
- `fontWeight` – any valid CSS value (e.g. `"900"`, `"normal"`, `"bold"`)
- `fontSizeMobile` – font size for viewport width < 380 px (since v1.4)

**Colors, borders & spacing** (since v1.3)

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `checkboxLabelColor` | `String?` | Color of checkbox label text | `"#334155"` |
| `checkboxSize` | `String?` | Size of checkboxes | `"20px"` |
| `btnBgColor` | `String?` | Submit button background color | `"#6390f2"` |
| `btnTextColor` | `String?` | Submit button text color | `"#FFFFFF"` |
| `btnBorderColor` | `String?` | Submit button border color | `"#6390f2"` |
| `separatorColor` | `String?` | Color of the separator line | `"#8FA8C8"` |
| `separatorTextColor` | `String?` | Color of separator text (e.g. "or") | `"#64748B"` |
| `termsTextColor` | `String?` | Color of terms & privacy text | `"#475569"` |
| `inputBorderRadius` | `String?` | Border radius of input fields | `"8px"` |
| `inputBorderColorDefault` | `String?` | Input border color (default state) | `"#7a0f45"` |
| `inputBorderColorSuccess` | `String?` | Input border color (valid input) | `"#22C55E"` |
| `inputBorderColorError` | `String?` | Input border color (invalid input) | `"#821030"` |
| `inputFocusOutline` | `String?` | Outline when an input has focus | `"#3B82F6 auto 0px"` |
| `inputPadding` | `String?` | Padding inside input fields | `"12px 16px"` |
| `fieldSpacingVertical` | `String?` | Gap between form elements | `"5px"` |
| `labelMarginBottom` | `String?` | Spacing below field labels | `"10px"` |
| `inputMarginBottom` | `String?` | Spacing below input fields | `"10px"` |
| `errorMarginBottom` | `String?` | Spacing below error messages | `"10px"` |
| `buttonMarginBottom` | `String?` | Spacing below the submit button | `"16px"` |
| `separatorTextMarginBottom` | `String?` | Spacing below separator text | `"20px"` |
| `checkboxTextMarginBottom` | `String?` | Spacing below checkbox text | `"10px"` |
| `termsTextMarginBottom` | `String?` | Spacing below terms & privacy text | `"10px"` |
| `iconWidth` | `String?` | Width of card brand / validation icons (since v1.4) | `"60px"` |
| `iconPaddingRight` | `String?` | Right padding of icons (since v1.4) | `"20px"` |

##### CustomIconsConfig (since v1.4)

Replace the default validation icons with custom images. Supported formats: SVG, PNG, JPEG, WebP.

```swift
let customIconsConfig = CustomIconsConfig(
    useCustomValidationIcons: true,
    showCardBrandIcons: false,  // if true, shows detected card brand in card number field
    successIcon: "/icons/valid.svg",
    errorIcon: "/icons/invalid.svg"
)
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `useCustomValidationIcons` | `Bool` | `false` | Enable custom validation icons |
| `showCardBrandIcons` | `Bool` | `false` | Show detected card brand icon in card number field instead of validation icon (requires `useCustomValidationIcons: true`) |
| `successIcon` | `String?` | – | Path or URL of the icon shown when validation passes |
| `errorIcon` | `String?` | – | Path or URL of the icon shown when validation fails |

##### CTPConfig – Click-to-Pay (since v1.3)

Click-to-Pay is a wallet-based payment method by card schemes (Visa, Mastercard) that tokenizes stored cards, eliminating manual entry. You must be onboarded against the card schemes by PAYONE before using this feature.

> [!IMPORTANT]
> SDK version 1.3 or higher is required for Click-to-Pay. Use SDK version 1.4 for all new integrations.

```swift
let ctpConfig = CTPConfig(
    schemeConfig: CTPSchemeConfig(
        merchantPresentationName: "My Shop",
        visaConfig: CTPVisaConfig(
            srcInitiatorId: "YOUR_PAYONE_VISA_UUID",
            srcDpaId: "YOUR_MERCHANT_UUID",
            encryptionKey: "STRING",   // provided by PAYONE
            nModulus: "STRING"         // provided by PAYONE
        ),
        mastercardConfig: CTPMastercardConfig(
            srcInitiatorId: "YOUR_PAYONE_MC_UUID",
            srcDpaId: "YOUR_MERCHANT_UUID"
        )
    ),
    transactionAmount: CTPTransactionAmount(amount: "36.98", currencyCode: "EUR"),
    enableCTP: true,
    enableCustomerOnboarding: true,
    uiConfig: CTPUIConfig(
        buttonStyle: "solid",
        buttonTextCase: "capitalize",
        buttonAndBadgeColor: "#3B82F6",
        accentColor: "#6390f2",
        fontFamily: "Sansation",
        buttonAndInputRadius: "1rem",
        cardItemRadius: "2rem"
    )
)
```

**CTPConfig parameters**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `enableCTP` | `Bool` | Yes | Set to `true` to enable Click-to-Pay |
| `enableCustomerOnboarding` | `Bool` | Yes | Set to `true` to allow new customers to enrol during checkout |
| `schemeConfig` | `CTPSchemeConfig` | Yes | Per-scheme configuration (Visa / Mastercard) |
| `transactionAmount` | `CTPTransactionAmount` | Yes | Amount and currency displayed to the customer |
| `uiConfig` | `CTPUIConfig?` | No | Visual customisation of the CTP component |

**CTPSchemeConfig parameters**

| Property | Type | Description |
|----------|------|-------------|
| `merchantPresentationName` | `String?` | Display name shown in the CTP flow |
| `visaConfig` | `CTPVisaConfig?` | Visa: `srcInitiatorId`, `srcDpaId`, optional `encryptionKey`, `nModulus` |
| `mastercardConfig` | `CTPMastercardConfig?` | Mastercard: `srcInitiatorId`, `srcDpaId` |

**CTPUIConfig properties** (all optional)

| Property | Description |
|----------|-------------|
| `buttonStyle` | Button style, e.g. `"solid"` or `"OUTLINED"` |
| `buttonTextCase` | Text case, e.g. `"capitalize"` or `"upper"` |
| `buttonAndBadgeColor` | Color of the CTP button and badge |
| `buttonFilledHoverColor` | Hover color for filled button |
| `buttonOutlinedHoverColor` | Hover color for outlined button |
| `buttonDisabledColor` | Color when button is disabled |
| `cardItemActiveColor` | Color of active card item |
| `buttonAndBadgeTextColor` | Text color on button and badge |
| `linkTextColor` | Color of links in the CTP component |
| `accentColor` | Accent color |
| `fontFamily` | Font family |
| `buttonAndInputRadius` | Border radius for buttons and inputs |
| `cardItemRadius` | Border radius for card items |

##### LocaleTextConfig – custom text (since v1.3)

Override labels, placeholders, aria-labels and error messages per locale. Pass a dictionary keyed by locale string (e.g. `"en"`, `"de"`, `"fr"`, `"cs"`) as `customTextConfig` in `CreditcardTokenizerConfig`.

When Click-to-Pay is enabled, additional fields (`email`, `country`, `firstName`, `lastName`, `mobileNumber`, `addresslevel1`, `stateProvince`, `city`, `zipCode`) can also be customized in the same structure.

```swift
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
    )
    // add more locales as needed
]
```

> [!NOTE]
> The iOS SDK `LocaleTextConfig` exposes the typed core card fields (`cardNumber`, `cardholderName`, `expiryDate`, `securityCode`). Additional CTP-related fields shown in the JavaScript SDK are not an arbitrary raw-JSON passthrough in this API.

#### 6. PCI DSS & Security

- The SDK uses a JWT from your backend for secure initialization.
- Card entry is handled in the hosted iframe. Callbacks return the card token and service-provided metadata. Opt-in detailed diagnostics can additionally expose submitted card data and authorization headers to application code; the SDK leaves this mode disabled by default.

#### 7. Migration Note

**Migrating from classic PAYONE Hosted IFrames:** Update your integration to use the Hosted Tokenization SDK as shown above. The old `fields`, `defaultStyle`, and related config are no longer used.

**Migrating from iOS SDK v1.3 to v1.4:**

- `jwtToken` is no longer a separate parameter of `CreditcardTokenizerView` / `CreditcardTokenizerViewController`. It is now `token` inside `CreditcardTokenizerConfig`.
- `environment` has been renamed to `mode`.
- The `tokenizationSuccessCallback` signature changed: the third argument is now a typed `CardDetails` object (instead of `[String: Any]`), and a fourth `inputMode: String` argument has been added.
- `iframeConfig` and `submitButtonConfig` are now non-optional.
- New optional parameters: `email`, `showCardholderName`, `customIconsConfig`.
- `UIConfig` gained `formMarginLeft`, `formMarginRight`, `iconWidth`, `iconPaddingRight` and `fontSizeMobile` on `FontStyle`.
- `IframeConfig` already had `zIndex` since the underlying JS SDK v1.0.2.

**For more details, see the [demo project](Examples/) folder.**

**[back to top](#table-of-contents)**

### Fingerprint Tokenizer

To detect and prevent fraud at an early stage for the secured payment methods, the Fingerprint Tokenizer is an essential component for handling PAYONE Buy Now, Pay Later (BNPL) payment methods on the PAYONE Commerce Platform. During the checkout process, it securely collects three different IDs to generate a snippetToken in the format `<partner_id>_<merchant_id>_<session_id>`. This token must be sent from your server via the API parameter `paymentMethodSpecificInput.customerDevice.deviceToken`. Without this token, the server cannot perform the transaction. The tokenizer sends these IDs via a code snippet to Payla for later server-to-Payla authorization, ensuring the necessary device information is captured to facilitate secure and accurate payment processing.

To integrate the Fingerprint Tokenizer feature into your application, follow these steps:

#### 1. Import PCPClient Modules

**Swift**

```swift
import PCPClient
```

**Objective-C**

```objectivec
@import PCPClient;
@import PCPClientBridge;
```

#### 2. Create a new Fingerprint Tokenizer instance

Create an instance with the payla partner ID, partner merchant ID and the environment (test or production).

<details>
  <summary>Swift Example:</summary>

```swift
private let fingerprintTokenizer = FingerprintTokenizer(
    paylaPartnerId: "YOUR_PARTNER_ID",
    partnerMerchantId: "YOUR_MERCHANT_ID",
    environment: .test
)
```

</details>

<details>
  <summary>Objective-C Example:</summary>

```objectivec
self.tokenizerWrapper = [[FingerprintTokenizerWrapper alloc]
  initWithPaylaPartnerId:@"YOUR_PARTNER_ID"
  partnerMerchantId:@"YOUR_MERCHANT_ID"
  environment:PCPEnvironmentTest sessionId:nil
];
```

</details>

#### 3. Get the snippet token

In order to retrieve the snippet token you call the following method:

<details>
  <summary>Swift Example:</summary>

```swift
fingerprintTokenizer.getSnippetToken { result in
    switch result {
    case let .success(token):
        print(token)
    case let .failure(error):
        print(error.localizedDescription)
    }
}

```

</details>

<details>
  <summary>Objective-C Example:</summary>

```objectivec
[self.tokenizerWrapper getSnippetTokenWithSuccess:^(NSString *token) {
    NSLog(@"token: %@", token);
  } failure:^(enum FingerprintErrorWrapper error) {
    NSLog(@"%@", [NSString stringWithFormat:@"%ld", (long)error]);
  }
];
```

</details>

This snippet token is automatically generated when the `FingerprintTokenizer` instance is created and is also stored by Payla for payment verification. You need to send this snippet token to your server so that it can be included in the payment request. Add the token to the property `paymentMethodSpecificInput.customerDevice.deviceToken`.

For further information see: https://docs.payone.com/pcp/commerce-platform-payment-methods/payone-bnpl/payone-secured-invoice

**[back to top](#table-of-contents)**

### Apple Pay Session Integration

`ApplePayHandler` supports both native PassKit payment flows: **Standard**, with precollected order contacts and fixed shipping/totals, and **Express**, with sheet contact/shipping selection and asynchronous recalculation. Both use merchant-defined authorization.

- **[Standard versus Express](docs/apple-pay.md):** flow selection and integration responsibilities.
- **[Standard integration guide](docs/apple-pay-standard.md):** precollected order parameters, fixed payment request, authorization and backend processing.

- **[SDK integration guide](docs/apple-pay-express.md):** prerequisites, signing/entitlements, request configuration, Swift/Objective-C integration, callback/lifecycle reference, errors/timeouts and migration from the URL transport.
- **[Runnable examples](Examples/ApplePayDemoSupport/README.md):** SwiftUI and Objective-C apps sharing a small merchant-backend adapter, configuration, exact demo HTTP contract and device checks.

The examples' backend **simulates checkout and does not authorize a PAYONE payment**. Real payment processing remains the responsibility of the merchant backend and its agreed PAYONE integration. Native PassKit does not require Apple Pay JS or web-domain merchant validation.

**[back to top](#table-of-contents)**

## PayPal Web Payments Integration

This section explains how to integrate PayPal Web Payments with the PAYONE Commerce Platform in your iOS application using the PayPal iOS SDK.

### 1. Add PayPal dependencies

First, add the PayPal SDK to your project. You can use Swift Package Manager or CocoaPods.

#### Swift Package Manager

```swift
// Add to your Package.swift dependencies
.package(url: "https://github.com/paypal/paypal-ios", .upToNextMajor(from: "2.0.0"))

// Add these dependencies to your target
.product(name: "PayPalWebPayments", package: "paypal-ios"),
.product(name: "CorePayments", package: "paypal-ios"),
.product(name: "PaymentButtons", package: "paypal-ios")
```

#### CocoaPods

```ruby
# Add to your Podfile
pod 'PayPal/PayPalWebPayments'
pod 'PayPal/PaymentButtons'
```

### 2. Create the PayPal view and view model

Create a view model that will handle the PayPal payment logic and a view to present the payment UI to the user.

#### PayPal View Model (Swift)

```swift
import Foundation
import CorePayments
import PayPalWebPayments

public class PayPalViewModel: ObservableObject {
  @Published public var selectedAmountIndex: Int = 0

  private let amounts = ["5.00", "10.00", "25.00"]
  private var payPalWebCheckoutClient: PayPalWebCheckoutClient?
  private var completion: ((Result<String, Error>) -> Void)?

  public func initiatePayment(completion: @escaping (Result<String, Error>) -> Void) {
    self.completion = completion

    // Setup continues in next steps...
  }
}
```

#### PayPal Payment Button (Swift)

Use the official PayPal button directly from the PaymentButtons module for a native look and feel:

```swift
import SwiftUI
import PaymentButtons

// In your SwiftUI view
struct PayPalPaymentView: View {
  var body: some View {
    VStack {
      // Create the button using the official PayPal button component
      PayPalButton.Representable(edges:.softEdges) {
        // Insert your payment code here
        initiatePayPalPayment()
      }
      .frame(height: 44)
      .accessibility(label: Text("Pay with PayPal"))
    }
  }

  func initiatePayPalPayment() {
    // Implementation for initiating PayPal payment
  }
}

// You can customize the button appearance using different button shapes:
// .rectangle - Sharp corners
// .rounded - Rounded corners (recommended, default style)
// .pill - Fully rounded ends
// .custom(CGFloat) - Custom corner radius
```

### 3. Initialize and configure PayPal client

Configure the PayPal client with your credentials and environment settings:

```swift
// 1. Create CoreConfig with client ID
let config = CoreConfig(
  clientID: "YOUR_PAYPAL_CLIENT_ID",  // Replace with your actual client ID
  environment: .sandbox  // Use .production for live environment
)

// 2. Create PayPalWebCheckoutClient
let payPalClient = PayPalWebCheckoutClient(config: config)
self.payPalWebCheckoutClient = payPalClient
```

> [!IMPORTANT]
> Replace `YOUR_PAYPAL_CLIENT_ID` with your actual PayPal client ID from the PayPal Developer Dashboard.

### 4. Create order on your server

The order must be created on your server using the PCP Server SDK, which will communicate with PayPal's API:

```swift
// Implementation in the view model
private func getOrderIdFromServer(completion: @escaping (Result<String, Error>) -> Void) {
  // In a real implementation, make a network request to your backend:

  let url = URL(string: "https://your-server.com/create-paypal-order")!
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")

  let amount = self.amounts[self.selectedAmountIndex]
  let body: [String: Any] = [
    "amount": amount,
    "currency": "EUR"
  ]

  request.httpBody = try? JSONSerialization.data(withJSONObject: body)

  URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response and extract order ID (or payPalTransactionId)
    // Call completion with the result
  }.resume()
}
```

> [!NOTE]
> On your server side, use the PAYONE Commerce Platform Server SDK to create the PayPal order by integrating with the PayPal Orders API.

### 5. Process the PayPal payment

Once you have the order ID, initiate the PayPal payment flow:

```swift
// Create web checkout request
let payPalWebRequest = PayPalWebCheckoutRequest(
  orderID: orderId,
  fundingSource: .paypal  // Can also be .payLater or .payPalCredit
)

// Start checkout with completion handler
payPalClient.start(request: payPalWebRequest) { [weak self] result in
  guard let self = self else { return }

  switch result {
  case .success(let payPalResult):
    // Order was approved and is ready to be captured/authorized
    self.authorizeOrCaptureOrder(orderId: payPalResult.orderID)
  case .failure(let error):
    // Handle errors including cancellation
    if PayPalError.isCheckoutCanceled(error) {
      // Handle cancellation specifically
      self.completion?(.failure(customCancelError))
    } else {
      // Handle other errors
      self.completion?(.failure(error))
    }
  }
}
```

### 6. Handle the payment result

After the payment is completed, you need to either authorize or capture the payment on your server:

```swift
private func authorizeOrCaptureOrder(orderId: String) {
  // Make a request to your server to authorize or capture the order
  let url = URL(string: "https://your-server.com/capture-paypal-order")!
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")

  let body: [String: Any] = [
    "orderId": orderId
  ]

  request.httpBody = try? JSONSerialization.data(withJSONObject: body)

  URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
    // Process the response and inform the user about the result
    DispatchQueue.main.async {
      if let error = error {
        self?.completion?(.failure(error))
      } else {
        self?.completion?(.success("Payment successful! Order ID: \(orderId)"))
      }
    }
  }.resume()
}
```

> [!NOTE]
> Your server should use the PAYONE Commerce Platform Server SDK to authorize or capture the PayPal order, depending on your payment flow.

For a complete implementation example, refer to the [PCPClientSwiftDemo](./Examples/PCPClientSwiftDemo) project in this repository.

**[back to top](#table-of-contents)**

## Demonstration Projects

You can find a demonstration project for each language including all features in the corresponding directories:

- **Swift**: Check out the [PCPClientSwiftDemo](./Examples/PCPClientSwiftDemo) folder.
- **Objective-C**: See the [PCPClientObjcDemo](./Examples/PCPClientObjcDemo) folder.

> [!IMPORTANT]
> Be aware that you will need to provide your own properties, for example AID, MID, PortalKey or Apple Pay server URL at all places which are prefixed with "YOUR\_".

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

**[back to top](#table-of-contents)**

## Releasing the library

- Checkout develop branch.
- Do the required changes.
- Use the version script to update to new version, e.g:
  ```sh
  # from the root folder
  sh version.sh 1.2.3
  ```
- Create a pull-request into main branch.
- After merging the develop branch create a Git tag with the version.

**[back to top](#table-of-contents)**

## License

This project is licensed under the MIT License. For more details, see the [LICENSE](./LICENSE) file.

**[back to top](#table-of-contents)**
