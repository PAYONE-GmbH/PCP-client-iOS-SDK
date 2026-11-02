# Apple Pay Express integration

`PCPClient.ApplePayHandler` presents a **native PassKit** payment sheet and supports asynchronous shipping/contact recalculation and merchant-defined authorization. Express means starting checkout directly from the cart and collecting the order's contacts and shipping selection in Apple Pay. It uses the existing handler, not a second Express SDK or a web view.

This guide describes the SDK contract. The [runnable Swift and Objective-C examples](../Examples/ApplePayDemoSupport/README.md) demonstrate a concrete merchant-backend adapter. Their server **simulates checkout and does not authorize a PAYONE/bank payment**.

## Responsibilities

| SDK | App and merchant backend |
| --- | --- |
| Present/dismiss PassKit; forward contacts, shipping selection and `PKPayment`. | Configure the merchant and payment request; obtain authoritative cart totals and available shipping. |
| Complete async PassKit callbacks once on main, with a 25-second fallback. | Recalculate on contact/method changes; invalidate stale quotes; complete callbacks within the deadline. |
| Report authorization attempts and final session outcome. | Send the encrypted token and final order data to the backend; perform/verify the real payment; provide idempotency and reconciliation. |

The SDK does not define a PCP Express endpoint, create an order, decrypt tokens, calculate shipping/tax, store contacts, or infer payment success from token generation. Your backend contract determines how PAYONE processing, certificate ownership and order creation are performed.

## Prerequisites

- Install the `PCPClient` library using the repository's [installation instructions](../README.md#installation). This guide describes the current repository source; use a release/source revision containing these async APIs. The examples reference the local SDK. The package uses Swift tools 5.10 and supports iOS 15+. Apple Pay APIs are available in Swift and Objective-C; this integration does not require `PCPClientBridge`.
- Use a supported iPhone/iPad with Apple Pay available and an eligible card/region. Test devices must be correctly paired and signed; the examples target iOS 17.5+.
- In the correct Apple Developer team, register an explicit App ID and a Merchant ID. Enable Apple Pay for the App ID and associate that merchant. Apple requires the appropriate team permissions to configure these resources.
- Add **Signing & Capabilities → Apple Pay** to your app target. Select the merchant and ensure the generated provisioning profile includes it. Wildcard profiles cannot provide this entitlement.
- `PKPaymentRequest.merchantIdentifier` must match `com.apple.developer.in-app-payments` and the merchant permitted by the profile. For example:

  ```xml
  <key>com.apple.developer.in-app-payments</key>
  <array><string>merchant.com.example.shop</string></array>
  ```

- For real payments, arrange a valid **Payment Processing certificate** and merchant association with your payment processor. Confirm who generates the CSR, holds the private key and decrypts/processes tokens. Provision the corresponding backend environment; never embed those keys or merchant API credentials in the app.
- Provide a device-reachable merchant backend that calculates the cart and confirms payment outcomes. Its HTTP contract is app-specific; the [example's endpoints](../Examples/ApplePayDemoSupport/README.md#demo-http-contract) are not a PCP API specification.

Native PassKit does **not** require Apple Pay JS, a Merchant Identity certificate, web-domain verification or `/validate-merchant`. Those belong to the web integration. See Apple's [Apple Pay configuration](https://developer.apple.com/help/account/capabilities/configure-apple-pay/) and [sandbox testing](https://developer.apple.com/apple-pay/sandbox-testing/) instructions. For sandbox testing, use a sandbox tester signed into iCloud on the device and Apple's sandbox cards; use matching test processing credentials on the backend.

## Integration sequence

1. Retain one `ApplePayHandler` for the checkout and configure its callbacks on main.
2. Fetch the initial cart quote from your backend **before** presenting. Include shipping and tax in the returned total and ensure at least one usable shipping method for a shipping checkout.
3. Construct `PKPaymentRequest` and start the sheet on main from a `PKPaymentButton` action.
4. On contact/method selection, invalidate the previous quote, recalculate on your backend and reply with the new PassKit update. Accept only the latest quote response.
5. On authorization, verify that the quote is still current, then send the complete `PKPayment` token and **final** contacts to your backend. Reply `.success` only after verifying its business-level payment result.
6. Use `didFinish` for the final UI state after dismissal. Keep attempt errors and backend payment references in your own checkout state for retry/reconciliation.

### 1. Create and retain the handler

```swift
import PassKit
import PCPClient

// Store on your view model/controller, rather than as a temporary local variable.
let applePayHandler = ApplePayHandler()
```

For Objective-C, use `@import PassKit; @import PCPClient;` and retain `[[ApplePayHandler alloc] init]` in a strong property. Retain your backend adapter as well. Use weak captures where a callback would otherwise retain its owning controller/coordinator.

`supportsApplePay()` checks basic device capability before a session, and also the current request's networks/capabilities during a session. To check card eligibility for a specific request before presentation, use:

```swift
let eligible = PKPaymentAuthorizationController.canMakePayments(
    usingNetworks: request.supportedNetworks,
    capabilities: request.merchantCapabilities
)
```

A capability check does not guarantee successful presentation, valid provisioning or payment authorization. Disable repeated starts while a checkout is active.

### 2. Construct the request from your quote

The following factory is app code. `summaryItems` and `shippingMethods` must come from your backend's current cart quote:

```swift
func makeExpressRequest(
    merchantIdentifier: String,
    summaryItems: [PKPaymentSummaryItem],
    shippingMethods: [PKShippingMethod]
) -> PKPaymentRequest {
    let request = PKPaymentRequest()
    request.merchantIdentifier = merchantIdentifier
    request.countryCode = "DE"
    request.currencyCode = "EUR"
    request.supportedNetworks = [.visa, .masterCard, .amex]
    request.merchantCapabilities = .threeDSecure
    request.requiredShippingContactFields = [.postalAddress, .name, .emailAddress, .phoneNumber]
    request.requiredBillingContactFields = [.postalAddress, .name]
    request.shippingType = .shipping
    request.shippingMethods = shippingMethods
    request.paymentSummaryItems = summaryItems
    return request
}
```

Use the country, currency, networks and capabilities supported by your merchant/processor. The contact fields above are the example's Express configuration; the SDK does not enforce them. Choose required fields to match your order requirements. Give each shipping method a stable backend identifier. Put the selected/default method first, including in contact updates.

The **last** summary item is the merchant total; earlier entries represent the items/charges that comprise it. Include shipping exactly once. Use `NSDecimalNumber`/decimal strings, not binary floating-point calculations. See [`makeRequest`, `DemoQuote.summaryItems` and `DemoQuote.methods`](../Examples/ApplePayDemoSupport/README.md#source-map-and-configuration).

### 3. Connect the async callbacks and start

This complete wiring function accepts your app's backend callbacks. It deliberately does not impose endpoint names or receipt formats:

```swift
func presentExpressCheckout(
    handler: ApplePayHandler,
    request: PKPaymentRequest,
    updateContact: @escaping (PKContact, @escaping ApplePayHandler.ShippingContactCompletion) -> Void,
    updateMethod: @escaping (PKShippingMethod, @escaping ApplePayHandler.ShippingMethodCompletion) -> Void,
    authorize: @escaping (PKPayment, @escaping (PKPaymentAuthorizationResult) -> Void) -> Void,
    finished: @escaping (ApplePayCompletionStatus) -> Void
) {
    handler.updateShippingContact = updateContact
    handler.updateShippingMethod = updateMethod
    handler.authorizePayment = authorize
    handler.didFinish = finished
    handler.startPayment(
        request: request,
        onDidSelectPaymentMethod: { _ in
            PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: request.paymentSummaryItems)
        },
        completion: { _ in } // Rich final status is handled by didFinish.
    )
}
```

Call this on main after obtaining a valid initial quote. The empty Boolean observer above is intentional: do not complete your UI twice by treating the Boolean observer and `didFinish` as independent checkouts. Reject repeated button actions in your app.

Use native `PKPaymentButton` target/action. The example's [SwiftUI button bridge](../Examples/PCPClientSwiftDemo/PCPClientSwiftDemo/ApplePayButton.swift) forwards `.touchUpInside`; its [checkout screen](../Examples/PCPClientSwiftDemo/PCPClientSwiftDemo/ApplePayExpressView.swift) retains the coordinator and disables the button while busy.

### 4. Implement contact and shipping updates

| Callback | Input and required reply |
| --- | --- |
| `updateShippingContact` | Input `PKContact` may be partially redacted. Recalculate available shipping/totals, then return `PKPaymentRequestShippingContactUpdate` with `paymentSummaryItems`, `shippingMethods`, and any `errors`. |
| `updateShippingMethod` | Use `PKShippingMethod.identifier` for backend selection. Recalculate totals, then return `PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: ...)`. |

For a contact validation error, create a field-specific error, for example:

```swift
import Contacts

let error = PKPaymentRequest.paymentShippingAddressInvalidError(
    withKey: CNPostalAddressISOCountryCodeKey,
    localizedDescription: "Shipping is not available in this country."
)
let update = PKPaymentRequestShippingContactUpdate(paymentSummaryItems: currentSummaryItems)
update.shippingMethods = availableShippingMethods
update.errors = [error]
// Pass update to the callback's reply block.
```

`currentSummaryItems` and `availableShippingMethods` above refer to your current validated cart. Do not require a full street/name during selection: Apple may withhold them until authorization. Invalidate your authorizable quote before each asynchronous recalculation, and version requests so older responses cannot replace a newer quote.

PassKit's shipping-method update has **no errors array**. If recalculation fails or times out, keeping displayed totals is not proof those totals are valid. Your authorization adapter must reject missing, stale or expired quotes. The [example coordinator](../Examples/ApplePayDemoSupport/ApplePayDemoCheckout.swift) demonstrates both invalidation and revision checks.

### 5. Authorize using the complete payment

`authorizePayment` receives `PKPayment`, including:

| PassKit value | Integration responsibility |
| --- | --- |
| `payment.token.paymentData` | Forward the complete encrypted Apple token in the encoding required by your backend. It contains cryptographic payment material, not an authorization result. |
| `payment.shippingContact` | Use the final authorized shipping contact for the order. |
| `payment.billingContact` | Send the final billing contact required by your processor/order contract. |
| `payment.shippingMethod?.identifier` | Verify the authorized shipping choice against the current quote/backend contract. |
| `payment.token.transactionIdentifier` | Optional transaction metadata, not a substitute for the encrypted token or merchant idempotency key. |

The example uses `JSONSerialization.jsonObject(with: payment.token.paymentData)` and forwards the resulting object as `token.paymentData` without base64 transformation. That JSON envelope is the **example's** contract, not a universal SDK/PCP requirement. [`completionBody(payment:quote:)`](../Examples/ApplePayDemoSupport/ApplePayDemoCheckout.swift) contains the exact mapping of both final contacts and token.

Verify HTTP status **and** the expected business result, cart/quote/amount/currency/selected shipping association and order reference before replying:

```swift
let accepted = PKPaymentAuthorizationResult(status: .success, errors: nil)
let rejected = PKPaymentAuthorizationResult(status: .failure, errors: [backendError])
// Reply with accepted only after verified backend authorization; otherwise reply with rejected.
```

`backendError` is your app's actual backend/validation error. Token creation, HTTP 200 alone, a non-empty response or dismissal of the sheet never proves payment success. A `.failure` reply can allow another attempt in the same sheet; make repeated backend requests idempotent. If the client times out after the backend has started payment, reconcile the order/payment on the backend before retrying. The SDK cannot roll back that payment.

### Objective-C interoperability

The properties are Objective-C-visible nested blocks. For example, a contact block has type:

```objectivec
void (^updateContact)(PKContact *, void (^)(PKPaymentRequestShippingContactUpdate *));
```

Assign your backend blocks to `handler.updateShippingContact`, `handler.updateShippingMethod`, `handler.authorizePayment`, and `handler.didFinish`, then start with:

```objectivec
[handler startPaymentWithRequest:request
      onDidSelectPaymentMethod:^PKPaymentRequestPaymentMethodUpdate *(PKPaymentMethod *method) {
          return [[PKPaymentRequestPaymentMethodUpdate alloc] initWithPaymentSummaryItems:request.paymentSummaryItems];
      }
      completion:^(BOOL success) {
          // Observe only if needed; didFinish already reports the final session status.
      }];
```

The repository's [Objective-C demo](../Examples/PCPClientObjcDemo/PCPClientObjcDemo/ViewController.m) calls the same shared Swift checkout adapter through `PCPClientObjcDemo-Swift.h` rather than duplicating the merchant contract in Objective-C. That generated app header and `ApplePayDemoCheckout` are example infrastructure, not SDK APIs.

## Callback and lifecycle reference

Configure and start on the **main thread**. The handler invokes merchant callbacks on main. Your async reply blocks may be called on a background queue; the SDK marshals delivery to main. Retain the handler until the session finishes. Merchant callbacks remain configured for reuse; the request, controller and per-start card-selection block are released when the session finishes.

| API | Contract |
| --- | --- |
| `init()` | Merchant authorization via `authorizePayment`; no built-in network request. Missing authorization callback fails the attempt. |
| `init(processPaymentServerUrl:urlSession:)` | Optional compatibility transport, described below; not the Express backend adapter. |
| `startPayment(request:onDidSelectPaymentMethod:completion:)` | Presents one session. The card-selection block is mandatory and replaces the property of the same name. Boolean completion is `true` only for final success. A concurrent start immediately calls **its own** Boolean completion with `false`, without replacing or finishing the active session and without `didFinish` for the rejected start. |
| `updateShippingContact` | `(PKContact, @escaping ShippingContactCompletion) -> Void`; alias replies with `PKPaymentRequestShippingContactUpdate`. Overrides `didSelectShippingContact`. |
| `updateShippingMethod` | `(PKShippingMethod, @escaping ShippingMethodCompletion) -> Void`; alias replies with `PKPaymentRequestShippingMethodUpdate`. Overrides `onShippingMethodDidChange`. |
| `authorizePayment` | `(PKPayment, @escaping (PKPaymentAuthorizationResult) -> Void) -> Void`. Overrides the URL transport. |
| `didAuthorizePayment` | Observes each accepted authorization result after its PassKit reply, including failure/timeout. Not a payment-submission hook. |
| `didFinish` | `(ApplePayCompletionStatus) -> Void`. Once per accepted start, after dismissal or failed presentation. Boolean completion runs immediately before this observer. |
| `didSelectShippingContact` | Legacy synchronous contact notification; cannot asynchronously supply new totals/methods. |
| `onShippingMethodDidChange` | Legacy synchronous shipping update returning `PKPaymentRequestShippingMethodUpdate`. |
| `onDidSelectPaymentMethod` | Synchronous card-selection update returning `PKPaymentRequestPaymentMethodUpdate`. |
| `onChangeCouponCode` | Synchronous coupon update returning `PKPaymentRequestCouponCodeUpdate`; asynchronous coupon recalculation is not supplied by this API. |
| `paymentController` | Current PassKit controller, nil after completion. Exposed for compatibility; do not replace it during a session. |

Async replies are accepted **once per callback**, not once per overall sheet. Duplicate replies are ignored. Replies after the session ends cannot affect a new session. Delegate events from unrelated/finished controllers do not invoke merchant update callbacks. Optional unconfigured selection callbacks return the current totals rather than leaving PassKit waiting. Card/coupon/shipping updates become the current request totals.

### Timeouts and results

Each async callback has a **25-second SDK fallback**. Complete your backend operations within that limit; reply exactly once in success and failure paths. Only the optional URL transport and example client impose a 20-second network timeout; the SDK cannot configure/cancel network tasks started in your custom blocks.

| Event | Behavior |
| --- | --- |
| Contact update deadline | Return existing totals/methods and a shipping-address validation error. |
| Shipping-method deadline | Return existing totals; there is no PassKit errors property. Your quote must remain invalid until recalculation succeeds. |
| Authorization deadline / missing authorization / URL-transport failure | Reply `.failure` with an `NSError` in domain `PCPClient.ApplePay`, code `1`, and a generic retry message. Observe it via `didAuthorizePayment`. |
| Presentation failure | Boolean completion `false`, `didFinish(.failure)`; no authorization attempt observer. |
| Close without any authorization attempt | Boolean `false`, `didFinish(.cancelled)`. |
| Close after a failed/timed-out attempt | Boolean `false`, `didFinish(.failure)`. |
| Close after a successful attempt | Boolean `true`, `didFinish(.success)`. |

`didFinish` describes the **session** based on the last authorization attempt. It cannot independently verify your backend's decision or report later capture/refund/settlement. There is no new cancel method or automatic retry; PassKit controls sheet cancellation, and your app/backend controls retry/idempotency.

## Existing URL transport and migration

Existing initializer/start signatures and synchronous callbacks remain available. `ApplePayHandler(processPaymentServerUrl: url)` POSTs:

```json
{
  "token": {"paymentData": {"version": "EC_v1", "data": "encrypted-data", "signature": "signature", "header": {}}},
  "paymentMethod": "Visa",
  "transactionIdentifier": "apple-transaction-id"
}
```

`paymentMethod` is `PKPaymentNetwork.rawValue` or `""` if unavailable. These are illustrative values, not a usable token. `paymentData` must decode to a JSON object. The transport uses JSON `Content-Type`, a 20-second URL request timeout and the supplied `URLSession`. Success requires no transport error, **HTTP 200** and a decodable JSON **Boolean** `{"success":true}`. Numeric `1`, missing/false success, empty/malformed bodies and other status codes fail. Its task is cancelled when the session finishes.

Earlier behavior that accepted arbitrary response data as success is intentionally removed. Update existing servers accordingly. This envelope has **no final contacts, cart or quote**. For Express, use `init()` and `authorizePayment` with your merchant backend adapter; do not point the generic transport at the example's `/process-payment` endpoint expecting it to supply that endpoint's quote/contact fields. Existing URL-based integrations may also override transport with `authorizePayment`.

## Runnable reference and verification

- [Example setup, source map, HTTP contract and device checks](../Examples/ApplePayDemoSupport/README.md).
- [Example configuration parameters and Swift/Objective-C usage](../Examples/ApplePayDemoSupport/README.md#pass-configuration-explicitly): merchant identifier, backend URL, cart ID, country, currency and initial shipping method are injected into the example coordinator. Both apps load their editable values from a bundled plist; the SDK defines none of these defaults.
- [SDK lifecycle/delegate/transport tests](../Tests/PCPClientTests/ApplePayHandler/ApplePayHandlerTests.swift).
- [Checkout contract tests](../Examples/ApplePayDemoSupport/ApplePayDemoCheckoutTests.swift).

```sh
xcodebuild test -scheme PCPClient-Package -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -quiet
xcodebuild build -project Examples/PCPClientSwiftDemo/PCPClientSwiftDemo.xcodeproj -scheme PCPClientSwiftDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet
xcodebuild build -project Examples/PCPClientObjcDemo/PCPClientObjcDemo.xcodeproj -scheme PCPClientObjcDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet
```

Select an installed simulator if necessary. The older `run_test.sh` pins a different destination. Automated tests use synthetic tokens and stubbed controllers/backends; they verify app/SDK behavior, not bank processing. Real Wallet interaction requires signed hardware, and successful simulated checkout is not proof of real PCP authorization. See the example checklist for manual acceptance.
