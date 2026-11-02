# Apple Pay Standard and Express examples

These are two native PassKit entry points for the [SDK Standard and Express guides](../../docs/apple-pay.md). They share configuration, transport, session and token-processing code. The shared code is compiled into both example apps and the package's `ApplePayDemoTests` target. It is **not included in the `PCPClient` library product**.

The configured server **simulates checkout**. It does not authenticate/decrypt the Apple Pay token or authorize a bank/PAYONE payment. A `demo-order-*` reference demonstrates the app/backend flow only.

## Run

1. Open [the Swift project](../PCPClientSwiftDemo/PCPClientSwiftDemo.xcodeproj) or [the Objective-C project](../PCPClientObjcDemo/PCPClientObjcDemo.xcodeproj).
2. Select your Apple Developer team and an explicit Apple-Pay-enabled App ID. Associate the merchant in the app's `ApplePayDemo.entitlements` file and provisioning profile. The request's merchant must match. See the [prerequisites](../../docs/apple-pay-express.md#prerequisites).
3. Edit [ApplePayDemoConfiguration.plist](ApplePayDemoConfiguration.plist) for your merchant, HTTPS backend, cart, country, currency and initial shipping method. Both apps bundle this resource and pass its values to the coordinator. The bundled server supports DE/EUR only; other values require corresponding backend support.
4. Pair an eligible iPhone/iPad, trust the Mac, enable Developer Mode and select the device in Xcode. For sandbox testing, sign into iCloud with an Apple sandbox tester and provision Apple's sandbox cards in Wallet & Apple Pay. See [Apple's current sandbox instructions](https://developer.apple.com/apple-pay/sandbox-testing/).
5. For Standard, also edit [ApplePayDemoStandardOrder.plist](ApplePayDemoStandardOrder.plist): these are the order contacts and shipping method collected before Apple Pay. They are shown on the Standard page before the Pay button.
6. Build/run either app and select **Go to Apple Pay Standard Checkout** or **Go to Apple Pay Express Checkout**. The examples target iOS 17.5+; the SDK supports iOS 15+.
7. Standard uses the precollected contacts and fixed shipping charge; no address/shipping selection is requested inside the sheet. Express requests a German shipping address, name, email and phone, and billing name/address inside Apple Pay, and recalculates when selection changes. Confirm the explicitly simulated result.

## Source map and configuration

| File | Responsibility |
| --- | --- |
| [ApplePayDemoConfiguration.swift](ApplePayDemoConfiguration.swift) | Explicit constructor parameters and optional validated bundle-resource loader; no embedded merchant/server defaults. |
| [ApplePayDemoConfiguration.plist](ApplePayDemoConfiguration.plist) | Editable example values copied into both apps. |
| [ApplePayDemoStandardOrder.swift](ApplePayDemoStandardOrder.swift) / [.plist](ApplePayDemoStandardOrder.plist) | Explicit precollected shipping/billing contacts and shipping identifier; optional validated resource loader for the Standard example. |
| [ApplePayDemoCheckout.swift](ApplePayDemoCheckout.swift) | Shared session, request/authorization and quote validation; Express updates or fixed Standard order according to constructor parameters. |
| [DemoBackendClient.swift](DemoBackendClient.swift) | JSON POST transport, HTTP validation, 20-second network timeout, delivery on main. |
| [DemoCheckoutModels.swift](DemoCheckoutModels.swift) | Demo quote/receipt decoding, decimal totals, expiry and receipt matching. |
| [ApplePayExpressView.swift](../PCPClientSwiftDemo/PCPClientSwiftDemo/ApplePayExpressView.swift) | Separate Standard/Express SwiftUI entry points sharing a retained checkout screen and busy/result state. |
| [ApplePayDemoViewController.swift](ApplePayDemoViewController.swift) | Shared UIKit checkout screen, initialized with configuration and an optional Standard order. |
| [ApplePayButton.swift](../PCPClientSwiftDemo/PCPClientSwiftDemo/ApplePayButton.swift) | `PKPaymentButton` target/action bridge for SwiftUI. |
| [ViewController.m](../PCPClientObjcDemo/PCPClientObjcDemo/ViewController.m) | Objective-C usage of the same coordinator through the generated Swift header. |
| [ApplePayDemoCheckoutTests.swift](ApplePayDemoCheckoutTests.swift) | Stubbed backend/PassKit checkout tests; no bank transaction. |

The plist contains the example values `merchant.de.nanogiants.payonedemo`, `https://payone-apple-pay-demo-server.nanogiants-services.de`, `demo-cart-1`, DE/EUR and `standard`. The checkout has no no-argument initializer or configuration fallback. If changing merchant, also update the apps' entitlements and provisioning profiles. Merchant availability depends on your Developer team. For a local backend, use device-reachable HTTPS; device `localhost` is not the Mac.

### Standard order data

`ApplePayDemoCheckout(configuration:)` remains the Express constructor. For Standard, pass a precollected order explicitly:

```swift
let configuration = try ApplePayDemoConfiguration.load(from: .main)
let order = try ApplePayDemoStandardOrder.load(from: .main)
let standardCheckout = ApplePayDemoCheckout(configuration: configuration, standardOrder: order)
```

Or create it from your own merchant checkout parameters:

```swift
func standardCheckout(configuration: ApplePayDemoConfiguration,
                      shipping: PKContact, billing: PKContact, selectedShippingID: String) -> ApplePayDemoCheckout {
    let order = ApplePayDemoStandardOrder(shippingContact: shipping, billingContact: billing,
                                         shippingMethodIdentifier: selectedShippingID)
    return ApplePayDemoCheckout(configuration: configuration, standardOrder: order)
}
```

The order file has root keys `shippingMethodIdentifier`, `shippingContact` and `billingContact`. Each contact has `givenName`, `familyName`, `street`, `city`, `postalCode`, `countryCode`, and optional `emailAddress`/`phoneNumber`. Names, street, postcode and country must be present. The loader uppercases country codes. The shared sample uses fictional addresses; no order contacts are embedded in the coordinator. Standard shipping comes from the order, not `initialShippingMethodIdentifier` (which is the initial Express selection).

Standard takes an order-contact snapshot at start, sends it with the initial server quote and final token, and does not replace it with Wallet contacts. The fixed shipping charge is included in the sheet total; no shipping methods or required contact fields are requested in the sheet. Express instead sends the authorized Wallet contacts and the latest dynamic quote. Both revalidate quote expiry at authorization.

In Objective-C, use `initWithConfiguration:standardOrder:` on `ApplePayDemoCheckout`, or open `ApplePayDemoViewController` with a non-nil order for Standard / nil for Express. Both default resource loaders have `loadFromBundle:error:` selectors. The original Express constructor remains source-compatible.

### Pass configuration explicitly

Both apps currently load the editable resource:

```swift
let configuration = try ApplePayDemoConfiguration.load(from: .main)
let checkout = ApplePayDemoCheckout(configuration: configuration)
```

Instead, construct configuration from your app's own parameters. All six values are required; retain `checkout` throughout the payment sheet's lifetime:

```swift
func makeCheckout(merchantIdentifier: String, backendURL: URL, cartID: String,
                  countryCode: String, currencyCode: String,
                  shippingMethodIdentifier: String) -> ApplePayDemoCheckout {
    let configuration = ApplePayDemoConfiguration(
        merchantIdentifier: merchantIdentifier,
        baseURL: backendURL,
        cartID: cartID,
        countryCode: countryCode,
        currencyCode: currencyCode,
        initialShippingMethodIdentifier: shippingMethodIdentifier
    )
    return ApplePayDemoCheckout(configuration: configuration)
}
```

Objective-C uses the same configuration through the app's generated Swift header:

```objc
NSError *error = nil;
ApplePayDemoConfiguration *configuration =
    [ApplePayDemoConfiguration loadFromBundle:NSBundle.mainBundle error:&error];
if (configuration != nil) {
    self.applePayCheckout = [[ApplePayDemoCheckout alloc] initWithConfiguration:configuration];
} else {
    self.applePayResultLabel.text = error.localizedDescription;
}
```

For programmatic Objective-C configuration, use `initWithMerchantIdentifier:baseURL:cartID:countryCode:currencyCode:initialShippingMethodIdentifier:`. The resource loader requires an HTTPS URL, merchant identifier prefix, nonempty cart/shipping identifiers and uppercase two-/three-letter country/currency codes. Programmatic callers supply valid values themselves. Changing these parameters does not add countries, currencies, carts or shipping methods to the backend.

## Demo HTTP contract

These endpoints and JSON keys belong to this example backend, **not to the SDK or a specified PCP payment API**.

### Quote: `POST /checkout/quote`

Before presenting either sheet. Express also calls this on each contact/method change; Standard sends the full precollected contact and fixed shipping identifier once per start:

```json
{
  "cartId": "demo-cart-1",
  "shippingContact": {"countryCode": "DE", "postalCode": "101"},
  "shippingMethodIdentifier": "standard"
}
```

In Express the initial contact contains just `countryCode: DE`; PassKit may subsequently provide a redacted postcode. Standard starts with the full merchant order contact. Response shape:

```json
{
  "cartId": "demo-cart-1",
  "currencyCode": "EUR",
  "quoteId": "server-generated-quote-id",
  "expiresAt": "2099-01-01T00:00:00.000Z",
  "shippingMethods": [
    {"identifier": "standard", "label": "Standard", "detail": "Standard delivery", "amount": "4.90"},
    {"identifier": "express", "label": "Express", "detail": "Express delivery", "amount": "9.90"}
  ],
  "selectedShippingMethodIdentifier": "standard",
  "lineItems": [{"label": "Item", "amount": "19.90"}, {"label": "Shipping", "amount": "4.90"}],
  "total": {"label": "Demo", "amount": "24.80"},
  "errors": []
}
```

The expiry above is illustrative; actual quotes expire after 15 minutes. Item 19.90 EUR includes tax. Standard total is 24.80 EUR; express total is 29.80 EUR. The client verifies decimal amounts and their sum. It invalidates the previous quote *before* recalculation and rejects superseded responses. The selected shipping method is placed first because PassKit selects the first after contact updates.

Unsupported countries return HTTP 200 with `quoteId`/`expiresAt`/selection null, no shipping methods, and errors such as `{"code":"shippingContactInvalid","field":"countryCode","message":"…"}`. The client displays contact errors and cannot authorize without a usable quote.

### Complete: `POST /process-payment`

```json
{
  "cartId": "demo-cart-1",
  "quoteId": "server-generated-quote-id",
  "shippingMethodIdentifier": "standard",
  "token": {"paymentData": {"version": "EC_v1", "data": "encrypted-data", "signature": "signature", "header": {}}},
  "shippingContact": {
    "givenName": "Demo", "familyName": "Customer", "addressLines": ["Teststraße 1"],
    "locality": "Berlin", "administrativeArea": "Berlin", "postalCode": "10115", "countryCode": "DE",
    "emailAddress": "demo@example.com", "phoneNumber": "+49300000000"
  },
  "billingContact": {
    "givenName": "Demo", "familyName": "Customer", "addressLines": ["Teststraße 1"],
    "locality": "Berlin", "postalCode": "10115", "countryCode": "DE"
  }
}
```

The token above is structural illustration, not a usable Apple token. The client decodes the actual `PKPaymentToken.paymentData` into JSON (no base64 transformation), splits street lines, uppercases countries and omits unavailable optional fields. Express includes final contacts from `PKPayment`; earlier redacted contacts are never substituted for them. Standard includes the merchant order contacts collected before Apple Pay, even when `PKPayment` returns no contacts. The simulated backend receives the same envelope in both cases; its quote mechanism does not turn Standard into a sheet-address/Express flow.

The adapter additionally sends `token.paymentMethod.network` (the raw PassKit network string, or empty when unavailable) and `token.transactionIdentifier`. A production backend must validate/map the network to its supported PCP enum; the demo server does not use this metadata to authorize a payment.

HTTP 200 must decode to `success: true`, `mode: demo`, `paymentStatus: simulated`, an `orderId` starting `demo-order-`, and quote ID/cart/currency/method/total matching the authorized quote. See `DemoReceipt.matches` for the exact checks. The backend can also return receipt line items; the client validates the receipt's total, not every receipt line item. Non-200, malformed or mismatched replies fail. There is no fallback to a no-quote endpoint.

Backend error statuses include 400 (validation), 409 (expired/mismatched/already completed quote), 413 (body limit), and 503 (capacity). The demo gives 409 a refresh message. Quotes/idempotency records are in server memory and disappear on restart; the backend reuses the result for the same quote/token during its retention window. This is not a production payment-reconciliation contract.

Shipping-method updates cannot display an errors array in PassKit. On a failed recalculation this demo retains the displayed totals but clears the authorizable quote, so completion is blocked until a valid recalculation. Retry is by selecting contact/shipping again or reopening the sheet.
