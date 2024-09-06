# PCPClient SDK iOS

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=PAYONE-GmbH_PCP-client-iOS-SDK&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=PAYONE-GmbH_PCP-client-iOS-SDK)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=PAYONE-GmbH_PCP-client-iOS-SDK&metric=coverage)](https://sonarcloud.io/summary/new_code?id=PAYONE-GmbH_PCP-client-iOS-SDK)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![CocoaPods](https://img.shields.io/cocoapods/v/PCPClient.svg?style=flat)](https://cocoapods.org/pods/PCPClient)
![iOS 10.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)
[![GitHub License](https://img.shields.io/github/license/PAYONE-GmbH/PCP-client-iOS-SDK)](https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK/blob/main/LICENSE)

Welcome to the PAYONE Commerce Platform Client iOS SDK for the PAYONE Commerce Platform. This SDK provides everything a client needs to easily complete payments using Credit or Debit Card, PAYONE Buy Now Pay Later (BNPL) and Apple Pay.

## Table of Contents

- [Supported Languages and iOS Version](#supported-languages-and-ios-versions)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Creditcard Tokenizer](#creditcard-tokenizer)
    - [1. Upload an HTML page](#1-upload-an-html-page)
    - [2. Import PCPClient modules](#2-import-the-pcpclient-modules)
    - [3. Setup the View or ViewController](#3-setup-the-view-or-viewcontroller)
    - [4. Display the View or ViewController](#4-display-the-view-or-viewcontroller)
  - [Fingerprint Tokenizer](#fingerprint-tokenizer)
    - [1. Import PCPClient modules](#1-import-pcpclient-modules)
    - [2. Create a new Fingerprint tokenizer instance](#2-create-a-new-fingerprint-tokenizer-instance)
    - [3. Get the snippet token](#3-get-the-snippet-token)
  - [Apple Pay Session Integration](#apple-pay-session-integration)
    - [1. Create certificates and add capabilities](#1-create-certificates-and-add-capabilities)
    - [2. Setup your server and environment](#2-setup-your-server-and-environment)
    - [3. Import PCPClient modules](#3-import-pcpclient-modules)
    - [4. Create an ApplePayHandler](#4-create-an-applepayhandler)
    - [5. Create an Apple Pay button](#5-create-an-apple-pay-button)
    - [6. Create a PKPaymentRequest](#6-create-a-pkpaymentrequest-and-start-the-payment)
    - [7. Handle different events](#7-handle-different-events)
    - [8. Initiate the payment and handle the result](#8-initiate-the-payment-and-handle-the-result)
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

## Installation

### Swift Package Manager (SPM)

To integrate using Apple's Swift package manager, you have two options.

#### Package.swift
Add the following as a dependency to your `Package.swift`:

```swift
.package(url: "https://https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK.git", .upToNextMajor(from: "1.0.0"))
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
        .package(url: "https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK.git", .upToNextMajor(from: "1.0.0"))
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

```rb
pod 'PCPClient'
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
@import PCPClientBridge;
```

## Usage

### Creditcard Tokenizer

The Credit Card Tokenizer is an essential component for handling payments on the PAYONE Commerce Platform. It securely collects and processes credit or debit card information to generate a `paymentProcessingToken`, which is required for the Server-SDK to complete the payment process. Without this token, the server cannot perform the transaction. The tokenizer ensures that sensitive card details are handled securely and is PCI DSS (Payment Card Industry Data Security Standard) compliant.

To integrate the Creditcard Tokenizer feature into your application, follow these steps:

#### 1. Upload an HTML page

The Creditcard tokenizer injects code and PCI DSS conform input fields into a webpage. To assure this process works, you need to setup the correct containers and submit button.

```html
  <div id="cardpanInput"></div>
  <div id="cardcvc2Input"></div>
  <div id="cardExpireMonthInput"></div>
  <div id="cardExpireYearInput"></div>
  <button id="submit">Submit</button>
  ```

For a more sophisticated example, see this [index.html](./Sources/PCPClient/CreditcardTokenizer/index.html).

#### 2. Import the PCPClient modules

**Swift**
```swift
import PCPClient
```

**Objective-C**
```objectivec
@import PCPClient;
@import PCPClientBridge;
```

#### 3. Setup the View or ViewController

##### SwiftUI

For SwiftUI use the `CreditcardTokenizerView`.

```swift
CreditcardTokenizerView(
  tokenizerUrl: URL(...),
  request: CCTokenizerRequest(...),
  supportedCardTypes: [...],
  config: CreditcardTokenizerConfig(...)
)
```

##### UIKit

For UIKit use the `CreditcardTokenizerViewController`.

**Swift**
```swift
CreditcardTokenizerViewController(
  tokenizerUrl: URL(...),
  request: CCTokenizerRequest(...),
  supportedCardTypes: [...],
  config: CreditcardTokenizerConfig(...)
)
```

**Objective-C**
```objectivec
CreditcardTokenizerViewController *viewController = [
  [CreditcardTokenizerViewController alloc]
      initWithTokenizerUrl:[URL ...]
      request:[CCTokenizerRequest...]
      supportedCardTypes:@[...]
      config:[CreditcardTokenizerConfigWrapper ...]
];
```

##### Tokenizer URL

This is the URL where your HTML code can be found and this should include a valid HTML with the later specified fields and submit button.

<details>
  <summary>Example:</summary>

```swift
URL(string: "https://github.com")!
```
</details>

> [!CAUTION]  
> Do not use local HTML since this won't work. The scripts that are used need a valid origin to send updates to, Therefore, it's currently a limitation that the HTML must be hosted.

##### Request

The `CCTokenizerRequest` object includes several configuration keys and settings. These are your AID, MID, Portal ID, PMI Portal Key and lastly the environment to run your code against (test or production).

<details>
  <summary>Example:</summary>
  
```swift
CCTokenizerRequest(
  mid: "123",
  aid: "456",
  portalId: "789",
  environment: .test,
  pmiPortalKey: "a1b2"
)
```
</details>

##### Supported Card Types

A `String` array of supported card types. You should use the `SupportedCardType` enum and it's identifier property to receive valid values.

<details>
  <summary>Example:</summary>

```swift
[SupportedCardType.visa.identifier, SupportedCardType.mastercard.identifier]
```
</details>

##### Config

The config including the different required [fields](#fields), the callback(s), certain CSS styles, submit button ID, and the used language.

> [!Important]
> For Objective-C you must use the `CreditcardTokenizerConfigWrapper` since Swift completion handlers are not supported by Objective-C.

<details>
  <summary>Swift Example:</summary>
  
```swift
CreditcardTokenizerConfig(
  cardPan: Field(
      selector: "cardpan",
      style: "font-size: 14px; border: 1px solid #000;",
      type: "input",
      size: nil,
      maxlength: nil,
      length: nil,
      iframe: nil
  ),
  cardCvc2: Field(
      selector: "cardcvc2",
      style: "font-size: 14px; border: 1px solid #000;",
      type: "password",
      size: "4",
      maxlength: "4",
      length: [
          "V": 3,
          "M": 3
      ],
      iframe: nil
  ),
  cardExpireMonth: Field(
      selector: "cardexpiremonth",
      style: "font-size: 14px; width: 30px; border: solid 1px #000; height: 22px;",
      type: "text",
      size: "2",
      maxlength: "2",
      length: nil,
      iframe: [
          "width": "40px"
      ]
  ),
  cardExpireYear: Field(
      selector: "cardexpireyear",
      style: nil,
      type: "text",
      size: nil,
      maxlength: nil,
      length: nil,
      iframe: [
          "width": "50px"
      ]
  ),
  defaultStyles: [
      "input": "font-size: 1em; border: 1px solid #000; width: 175px;",
      "select": "font-size: 1em; border: 1px solid #000;",
      "iframe": "height: 22px, width: 180px"
  ],
  language: .german,
  error: "error",
  submitButtonId: "submit",
  creditCardCheckCallback: { result in
      switch result {
      case let .success(response):
          print(response)
      case let .failure(error):
          print("\(error.localizedDescription)")
      }
  }
)
```
</details>

<details>
  <summary>Objective-C Example:</summary>
  
```objectivec
CreditcardTokenizerConfigWrapper *config = [
  [CreditcardTokenizerConfigWrapper alloc]
  initWithCardPan:[
      [Field alloc]
      initWithSelector:@"cardpan"
      style:@"font-size: 14px; border: 1px solid #000;"
      type:@"input" 
      size:NULL
      maxlength:NULL
      length:NULL
      iframe:NULL
  ]
  cardCvc2:[
      [Field alloc]
      initWithSelector:@"cardcvc2"
      style:@"font-size: 14px; border: 1px solid #000;"
      type:@"password"
      size:@"4"
      maxlength:@"4"
      length:@{@"V": @3, @"M": @4}
      iframe:NULL
  ]
  cardExpireMonth:[
      [Field alloc]
      initWithSelector:@"cardexpiremonth"
      style:@"font-size: 14px; width: 30px; border: solid 1px #000; height: 22px;"
      type:@"text"
      size:@"2"
      maxlength:@"2"
      length:NULL
      iframe:@{@"width": @"40px"}
  ]
  cardExpireYear:[
      [Field alloc]
      initWithSelector:@"cardexpireyear"
      style:NULL
      type:@"text"
      size:NULL
      maxlength:NULL
      length:NULL
      iframe:@{@"width": @"50px"}
  ]
  defaultStyles:@{
      @"input": @"font-size: 1em; border: 1px solid #000; width: 175px;",
      @"select": @"font-size: 1em; border: 1px solid #000;",
      @"iframe": @"height: 22px, width: 180px"
  }
  language:PayoneLanguageGerman
  error:@"error"
  submitButtonId:@"submit"
  success:^(CCTokenizerResponse *response) {
      NSLog(@"%@", response);
  }
  failure:^(enum CCTokenizerError error) {
      NSLog(@"%@", [NSString stringWithFormat:@"%ld", (long)error]);
  }
];
```
</details>

##### Fields

Defines the various input fields for credit card details.

| Property          | Type                             | Description                                        |
| ----------------- | -------------------------------- | -------------------------------------------------- |
| `cardpan`         | `Field`                    | Configuration for the card number field.           |
| `cardcvc2`        | `Field`                    | Configuration for the card CVC2 field.             |
| `cardexpiremonth` | `Field`                    | Configuration for the card expiration month field. |
| `cardexpireyear`  | `Field`                    | Configuration for the card expiration year field.  |

##### Field properties

- **selector**: `String`  
  The CSS selector for the input element.

- **element**: `String` (optional)  
  The actual DOM element if not using a selector.

- **size**: `String` (optional)  
  The size attribute for the input element.

- **maxlength**: `String` (optional)  
  The maximum length of input allowed.

- **length**: `[String: Int]` 
  Specifies the length for various card types (e.g., `[V: 3, M: 3, A: 4, J: 0 ]`).

- **type**: `String`  
  The type attribute for the input element (e.g., `text`, `password`).

- **style**: `String` (optional)  
  CSS styles applied to the input element.

- **iframe**: `[String: String]` 
  Dimensions for the iframe if used (pass only width and height properties).

##### Other configurations fields

| Property                           | Type                                                                                                                                                       | Description                                                                                                                                            |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `language`                         | `PayoneLanguage`                                                                                                                                                   | The language for the SDK (`.german` or `.english` for now).                                                                                                               |
| `submitButtonId`                     | `String`                                                                                                                                       | HTML ID of the  submit button.                                                                                                                 
| `error`                            | `String`                                                                                                                                        | HTML ID of the div-container where error messages should be displayed.                                                                                |
| `creditCardCheckCallback`          | `@escaping ((Result<CCTokenizerResponse, CCTokenizerError>) -> Void)`  | Callback function for credit card check responses (Swift only).                                                                                                     |
| `success`          | `@escaping (CCTokenizerResponse) -> Void` | Callback function for credit card check success (Objective-C Wrapper only).                                                                                                     |
| `success`          | `@escaping (CCTokenizerError) -> Void`  | Callback function for credit card check failure (Objective-C Wrapper only).                                                                                                     |

#### 4. Display the View or ViewController

This will heavily depend on your the platform and navigation technique your are using.

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

This section guides you through integrating Apple Pay into your iOS app using the `pcp-client-ios-sdk`. The integration involves handling the Apple Pay session.

#### 1. Create certificates and add capabilities

There are some steps to perform before your app can handle Apple Pay. Follow the guidelines in the following resources:

[Apple Pay for Apps](https://developer.apple.com/documentation/passkit_apple_pay_and_wallet/apple_pay)

#### 2. Setup Your Server and Environment

Make sure that your server is set up and your environment is configured correctly according to the Apple Developer documentation. Follow the guidelines in the following resources:

[Setting Up Your Server](https://developer.apple.com/documentation/apple_pay_on_the_web/setting_up_your_server)

#### 3. Import PCPClient Modules

**Swift**
```swift
import PCPClient
```

**Objective-C**
```objectivec
@import PCPClient;
@import PCPClientBridge;
```

#### 4. Create an ApplePayHandler

The `ApplePayHandler` expects a `processPaymentServerUrl` which will be used to process the payment to your server.

**Swift**
```swift
private let applePayHandler = ApplePayHandler(processPaymentServerUrl: url)
```

**Objective-C**
```objectivec
self.applePayHandler = [[ApplePayHandler alloc] initWithProcessPaymentServerUrl:url];
```

#### 5. Create an Apple Pay button

Add a button to initiate the Apple Pay payment. You can use the method `supportsApplePay` to check whether Apple Pay is supported on the device and then conditionally display the button.

<details>
  <summary>SwiftUI Example:</summary>

```swift
@State private var shouldShowApplePay = false

...

VStack {
  if shouldShowApplePay {
    ApplePayButton()
      .onTapGesture {
        startPayment()
      }
      .frame(height: 30)
  }
}
.onAppear {
  shouldShowApplePay = applePayHandler.supportsApplePay()
}

```
</details>

<details>
  <summary>Objective-C Example:</summary>

```objectivec
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self.applePayHandler supportsApplePay]) {
        PKPaymentButton *applePayButton = [PKPaymentButton buttonWithType: PKPaymentButtonTypePlain style:PKPaymentButtonStyleBlack];
        [self.view addSubview:applePayButton];

        [applePayButton addTarget:self action:@selector(startApplePay:) forControlEvents:UIControlEventTouchUpInside];
    }
}
```
</details>


#### 6. Create a PKPaymentRequest

The `PKPaymentRequest` is highly customizable and, therefore, needs to be created by you to keep the same flexibility. Decide what values are needed for your use case.

<details>
  <summary>Swift Example:</summary>

```swift
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
```
</details>

<details>
  <summary>Objective-C Example:</summary>

```objectivec
-(PKPaymentRequest *)makeRequest {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"YOUR_MERCHANT_IDENTIFIER";
    request.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkGirocard];
    request.merchantCapabilities = PKMerchantCapability3DS;
    request.countryCode = @"DE";
    request.currencyCode = @"EUR";

    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem summaryItemWithLabel:@"Item 1" amount:[NSDecimalNumber decimalNumberWithString:@"33.99"]];
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem summaryItemWithLabel:@"Item 2" amount:[NSDecimalNumber decimalNumberWithString:@"2.99"]];
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"Total" amount:[NSDecimalNumber decimalNumberWithString:@"36.98"]];
    request.paymentSummaryItems = @[item1, item2, total];

    request.requiredBillingContactFields = [NSSet setWithArray:@[PKContactFieldPostalAddress, PKContactFieldEmailAddress, PKContactFieldName]];
    request.requiredShippingContactFields = [NSSet setWithArray:@[PKContactFieldPostalAddress, PKContactFieldEmailAddress, PKContactFieldName]];

    PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"Free Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]];
    freeShipping.identifier = @"free";
    freeShipping.detail = @"Arrives in 1-3 business days.";

    PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    expressShipping.identifier = @"express";
    expressShipping.detail = @"Arrives tomorrow";

    request.shippingMethods = @[freeShipping, expressShipping];

    request.applicationData = [NSData data];

    return request;
}
```
</details>

#### 7. Handle different events

There are different events that can happen where you will receive callbacks for from the `ApplePayHandler`. You have to set a completion on the handlers like this:

**Swift**
```swift
applePayHandler.didAuthorizePayment = { result in
    print(result)
}
```

**Objective-C**
```objectivec
self.applePayHandler.didAuthorizePayment = ^(PKPaymentAuthorizationResult *result) {
    NSLog(@"%@", result);
};
```

> [!IMPORTANT]
> Not all of these events have to be handled. It depends on the request you create and the options you give to the user.

##### Different event callbacks

| Callback  |  Note |
|----------|------|
| didAuthorizePayment | Sent after the user has acted on the payment request. |
| didSelectShippingContact | Sent when the user has selected a new shipping method. |
| onShippingMethodDidChange | Sent when the user has selected a new shipping method. |
| onDidSelectPaymentMethod | Sent when the user has selected a new payment card. | 
| onChangeCouponCode | Sent when the user has selected a new coupon code. |

#### 8. Initiate the payment and handle the result

This will ultimately initiate the payment, you should see Apple Pay open up and the callbacks should be called when a change was made. Lastly when the user concludes the payment, a request will be sent to your provided `processPaymentServerUrl`.

**Swift**
```swift
applePayHandler.startPayment(
    request: request,
    onDidSelectPaymentMethod: { _ in
      // Do a proper implementation here like adding the shipping costs if needed.
      PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: request.paymentSummaryItems)
     }
) { success in
    print("Payment did work \(success)")
}
```
**Objective-C**
```objectivec 
[self.applePayHandler startPaymentWithRequest:request onDidSelectPaymentMethod:^PKPaymentRequestPaymentMethodUpdate * _Nonnull(PKPaymentMethod *paymentMethod) {
    return [[PKPaymentRequestPaymentMethodUpdate alloc] initWithPaymentSummaryItems:request.paymentSummaryItems];
} completion:^(BOOL success) {
    NSLog(@"%d", success);
}];
```

**[back to top](#table-of-contents)**

## Demonstration Projects

You can find a demonstration project for each language including all features in the corresponding directories:

- **Swift**: Check out the [PCPClientSwiftDemo](./Examples/PCPClientSwiftDemo) folder.
- **Objective-C**: See the [PCPClientObjcDemo](./Examples/PCPClientObjcDemo) folder.

> [!IMPORTANT]
>Be aware that you will need to provide your own properties, for example AID, MID, PortalKey or Apple Pay server URL at all places which are prefixed with "YOUR_".

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

**[back to top](#table-of-contents)**

## Releasing the library

- Checkout develop branch.
- Do the required changes.
- Create a pull-request into main branch.
- After merging the develop branch create a Git tag with the version.

**[back to top](#table-of-contents)**

## License

This project is licensed under the MIT License. For more details, see the [LICENSE](./LICENSE) file.

**[back to top](#table-of-contents)**






