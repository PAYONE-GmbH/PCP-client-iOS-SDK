# Apple Pay Express example

This is the runnable native PassKit reference for the [SDK integration guide](../../docs/apple-pay-express.md). The shared code is compiled into both example apps and the package's `ApplePayDemoTests` target. It is **not included in the `PCPClient` library product**.

The configured server **simulates checkout**. It does not authenticate/decrypt the Apple Pay token or authorize a bank/PAYONE payment. A `demo-order-*` reference demonstrates the app/backend flow only.

## Run

1. Open [the Swift project](../PCPClientSwiftDemo/PCPClientSwiftDemo.xcodeproj) or [the Objective-C project](../PCPClientObjcDemo/PCPClientObjcDemo.xcodeproj).
2. Select your Apple Developer team and an explicit Apple-Pay-enabled App ID. Associate the merchant in the app's `ApplePayDemo.entitlements` file and provisioning profile. The request's merchant must match. See the [prerequisites](../../docs/apple-pay-express.md#prerequisites).
3. Edit [ApplePayDemoConfiguration.plist](ApplePayDemoConfiguration.plist) for your merchant, HTTPS backend, cart, country, currency and initial shipping method. Both apps bundle this resource and pass its values to the coordinator. The bundled server supports DE/EUR only; other values require corresponding backend support.
4. Pair an eligible iPhone/iPad, trust the Mac, enable Developer Mode and select the device in Xcode. For sandbox testing, sign into iCloud with an Apple sandbox tester and provision Apple's sandbox cards in Wallet & Apple Pay. See [Apple's current sandbox instructions](https://developer.apple.com/apple-pay/sandbox-testing/).
5. Build/run. In the Swift demo select **Go to Apple Pay Express Checkout**; in the Objective-C demo use the Apple Pay button. The examples target iOS 17.5+; the SDK supports iOS 15+.
6. With the bundled configuration, supply a German shipping address, name, email and phone, and billing name/address. Confirm the explicitly simulated result.

## Source map and configuration

| File | Responsibility |
| --- | --- |
| [ApplePayDemoConfiguration.swift](ApplePayDemoConfiguration.swift) | Explicit constructor parameters and optional validated bundle-resource loader; no embedded merchant/server defaults. |
| [ApplePayDemoConfiguration.plist](ApplePayDemoConfiguration.plist) | Editable example values copied into both apps. |
| [ApplePayDemoCheckout.swift](ApplePayDemoCheckout.swift) | PassKit request, callback wiring, latest-quote/session state, final contact/token mapping and authorization using injected configuration. |
| [DemoBackendClient.swift](DemoBackendClient.swift) | JSON POST transport, HTTP validation, 20-second network timeout, delivery on main. |
| [DemoCheckoutModels.swift](DemoCheckoutModels.swift) | Demo quote/receipt decoding, decimal totals, expiry and receipt matching. |
| [ApplePayExpressView.swift](../PCPClientSwiftDemo/PCPClientSwiftDemo/ApplePayExpressView.swift) | Independent SwiftUI checkout screen, retained coordinator, busy/result state. |
| [ApplePayButton.swift](../PCPClientSwiftDemo/PCPClientSwiftDemo/ApplePayButton.swift) | `PKPaymentButton` target/action bridge for SwiftUI. |
| [ViewController.m](../PCPClientObjcDemo/PCPClientObjcDemo/ViewController.m) | Objective-C usage of the same coordinator through the generated Swift header. |
| [ApplePayDemoCheckoutTests.swift](ApplePayDemoCheckoutTests.swift) | Stubbed backend/PassKit checkout tests; no bank transaction. |

The plist contains the example values `merchant.de.nanogiants.payonedemo`, `https://payone-apple-pay-demo-server.nanogiants-services.de`, `demo-cart-1`, DE/EUR and `standard`. The checkout has no no-argument initializer or configuration fallback. If changing merchant, also update the apps' entitlements and provisioning profiles. Merchant availability depends on your Developer team. For a local backend, use device-reachable HTTPS; device `localhost` is not the Mac.

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

Before presenting the sheet, and on each contact/method change:

```json
{
  "cartId": "demo-cart-1",
  "shippingContact": {"countryCode": "DE", "postalCode": "101"},
  "shippingMethodIdentifier": "standard"
}
```

The initial contact contains just `countryCode: DE`; PassKit may subsequently provide a redacted postcode. Response shape:

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

The token above is structural illustration, not a usable Apple token. The client decodes the actual `PKPaymentToken.paymentData` into JSON (no base64 transformation), includes final contacts from `PKPayment`, splits street lines, uppercases countries and omits unavailable optional fields. Earlier redacted contacts are never substituted for final order contacts.

HTTP 200 must decode to `success: true`, `mode: demo`, `paymentStatus: simulated`, an `orderId` starting `demo-order-`, and quote ID/cart/currency/method/total matching the authorized quote. See `DemoReceipt.matches` for the exact checks. The backend can also return receipt line items; the client validates the receipt's total, not every receipt line item. Non-200, malformed or mismatched replies fail. There is no fallback to a no-quote endpoint.

Backend error statuses include 400 (validation), 409 (expired/mismatched/already completed quote), 413 (body limit), and 503 (capacity). The demo gives 409 a refresh message. Quotes/idempotency records are in server memory and disappear on restart; the backend reuses the result for the same quote/token during its retention window. This is not a production payment-reconciliation contract.

## Device checks

- Standard total 24.80 EUR, final contacts transferred, simulated order shown.
- Express total 29.80 EUR; contact/method changes recalculate totals.
- Unsupported country displays errors and prevents completion with an invalid quote.
- Cancel/reopen/repeat does not reuse success or leave the button disabled.
- Network errors at initial quote, update and authorization fail; retry after restoration.
- Expired/conflicting quote and backend error cannot become success (requires controlled backend/stubs).
- Repeat in both demos; check iPhone and iPad layouts and supported older OS versions separately.

Shipping-method updates cannot display an errors array in PassKit. On a failed recalculation this demo retains the displayed totals but clears the authorizable quote, so completion is blocked until a valid recalculation. Retry is by selecting contact/shipping again or reopening the sheet.
