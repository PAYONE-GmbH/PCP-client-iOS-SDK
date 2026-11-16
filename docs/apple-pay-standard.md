# Apple Pay Standard payment flow

In the Standard flow, the merchant has already collected the shipping/billing data, selected shipping and calculated the order total. Apple Pay supplies the payment credential at the final payment step. Use the same `PCPClient.ApplePayHandler` as [Express](apple-pay-express.md); configure the request without Express address/shipping selection.

See [Standard versus Express](apple-pay.md), the [shared prerequisites](apple-pay-express.md#prerequisites), and the [runnable Standard example](../Examples/ApplePayDemoSupport/README.md#standard-order-data).

## 1. Prepare the order before Apple Pay

Before presenting, your app/backend must have:

- The merchant identifier configured in both the app entitlement/profile and processor setup.
- A current order/cart reference, final currency and amount, including tax and selected shipping.
- The order's shipping and billing contacts, plus the selected shipping identifier.
- An authorization endpoint and a verified backend response contract, including handling of errors, unknown outcomes and any additional actions.

Use backend-calculated decimal amounts, not client floating-point calculations. Snapshot the authorized order context for the session and prevent changes to it behind the sheet. If it expires or changes, close/restart checkout with the refreshed amount and let the customer confirm again. Token generation alone is not payment authorization.

## 2. Create the Standard `PKPaymentRequest`

The following app-side factory takes all merchant/order values as parameters:

```swift
import PassKit
import PCPClient

func makeStandardRequest(
    merchantIdentifier: String,
    countryCode: String,
    currencyCode: String,
    networks: [PKPaymentNetwork],
    summaryItems: [PKPaymentSummaryItem],
    shippingContact: PKContact,
    billingContact: PKContact
) -> PKPaymentRequest {
    let request = PKPaymentRequest()
    request.merchantIdentifier = merchantIdentifier
    request.countryCode = countryCode
    request.currencyCode = currencyCode
    request.supportedNetworks = networks
    request.merchantCapabilities = .threeDSecure
    request.paymentSummaryItems = summaryItems
    request.shippingContact = shippingContact
    request.billingContact = billingContact
    request.requiredShippingContactFields = []
    request.requiredBillingContactFields = []
    request.shippingMethods = []
    return request
}
```

The last summary item is the merchant total. The preceding items can show the chosen shipping charge and tax, but the charge must not be counted twice. Set capabilities/networks according to your merchant's supported processing. The example uses Visa, Mastercard and Girocard rather than treating every Apple-supported network as PAYONE-enabled.

Empty required contact sets and shipping methods are intentional: this example uses order contacts and shipping selected **before** opening Apple Pay, not the sheet's Express selectors. Providing `shippingContact`/`billingContact` does not transfer order responsibility to Apple or PCP. The merchant order remains authoritative. If your application instead requires Apple Pay to collect missing information or dynamically change shipping, use the [Express configuration](apple-pay-express.md#2-construct-the-request-from-your-quote).

Leave `applicationData` unset for this PCP processing path; it is not supported by this integration.

## 3. Configure authorization and present

Retain the handler in your controller/view model for the entire session. Configure/start it on the main thread. The wiring function below accepts your backend integration as a callback; it does not invent a PCP endpoint:

```swift
func presentStandardPayment(
    handler: ApplePayHandler,
    request: PKPaymentRequest,
    authorize: @escaping (PKPayment, @escaping (PKPaymentAuthorizationResult) -> Void) -> Void,
    finished: @escaping (ApplePayCompletionStatus) -> Void
) {
    handler.updateShippingContact = nil
    handler.updateShippingMethod = nil
    handler.didSelectShippingContact = nil
    handler.onShippingMethodDidChange = nil
    handler.authorizePayment = authorize
    handler.didFinish = finished
    handler.startPayment(
        request: request,
        onDidSelectPaymentMethod: { _ in
            PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: request.paymentSummaryItems)
        },
        completion: { _ in } // didFinish handles the final UI outcome.
    )
}
```

Your `authorize` callback closes over the preceding order context. Forward `payment.token.paymentData` **together with that order context and its merchant-collected contacts** to your backend. A Standard request need not return shipping/billing contacts in `PKPayment`; do not silently replace the order with missing or different Wallet contacts. The example snapshots its precollected contact payloads at each start and uses them even when the authorized `PKPayment` has no contacts.

No async shipping callbacks are needed for a fixed Standard order. Card selection still completes with the unchanged total. Use the official `PKPaymentButton` action, with a request-aware eligibility check if needed, and disable repeated starts while active.

### Objective-C

Retain `[[ApplePayHandler alloc] init]`, configure `authorizePayment` and `didFinish`, and set `PKPaymentRequest` contacts, fixed summary items and empty required-contact/shipping selections as above. Start via `startPaymentWithRequest:onDidSelectPaymentMethod:completion:`. Block signatures, threading, callback precedence and outcomes are identical in both flows; see the [Objective-C reference](apple-pay-express.md#objective-c-interoperability).

The [Objective-C example](../Examples/PCPClientObjcDemo/PCPClientObjcDemo/ViewController.m) opens an `ApplePayDemoViewController` initialized with configuration plus a non-nil `ApplePayDemoStandardOrder`. This is example infrastructure, not an additional SDK dependency.

## 4. Token and payment processing

The native Apple token is obtained from `PKPaymentToken.paymentData`. The example deserializes it to JSON and sends the complete encrypted token to its merchant server, along with `paymentMethod.network` and `transactionIdentifier` metadata. Do not send only `transactionIdentifier`, generate a token before customer confirmation, or transform it into an unrelated card-tokenizer credential.

The **server-side PCP mapping** for Apple Pay product **302** is:

| Apple token / payment value | PCP mobile-payment field |
| --- | --- |
| Apple Pay payment product | `mobilePaymentMethodSpecificInput.paymentProductId = 302` |
| `paymentData.data` | `mobilePaymentMethodSpecificInput.encryptedPaymentData` |
| `paymentData.header.publicKeyHash` | `mobilePaymentMethodSpecificInput.publicKeyHash` |
| `paymentData.header.ephemeralPublicKey` | `mobilePaymentMethodSpecificInput.ephemeralKey` |
| Card network mapped to PAYONE's supported enum | `mobilePaymentMethodSpecificInput.paymentProduct302SpecificInput.network` |
| `paymentData.version` | `mobilePaymentMethodSpecificInput.paymentProduct302SpecificInput.token.version` |
| `paymentData.signature` | `mobilePaymentMethodSpecificInput.paymentProduct302SpecificInput.token.signature` |
| `paymentData.header.transactionId` | `mobilePaymentMethodSpecificInput.paymentProduct302SpecificInput.token.header.transactionId` |

This is reference information for your backend, **not a request made automatically by the iOS SDK**. Your backend is responsible for the server API, checkout/order amount and currency, network names, certificates and processing environment. Classic PSP `clearingtype/wallettype` parameters are not substitutes for these PCP fields.

Send live tokens promptly after authorization; their validity window is less than five minutes. Do not assume that a long-lived test-token behavior is a production replay/idempotency mechanism. Associate retries with your merchant order/payment reference.

### Additional actions and error handling

The SDK does not present a 3DS browser, resolve a redirect, or poll a backend payment status. If your processing path requires additional actions, implement that app/backend flow with PAYONE, including return URLs and webhooks where applicable, and account for PassKit's callback deadlines. Do not report an unresolved `requires action`/pending payment as success. The simulated examples do not implement 3DS, real authorization, capture or settlement.

Payment-processing errors include `2700` (amount), `2701` (currency), `2702` (decryption), `2703` (certificate validation) and `2704` (missing token information). Preserve backend error details in your application and map a failed attempt to a failed PassKit authorization result. Do not interpret HTTP 200 alone as business success.

## 5. Completion, cancellation and retry

- Reply to `authorizePayment` once with `PKPaymentAuthorizationResult(status: .success, errors: nil)` **only after** your backend verifies the accepted payment. Otherwise return `.failure` and your error(s).
- Async replies are delivered on main. The SDK fallback is 25 seconds per callback; its optional URL transport uses a 20-second request timeout. Your custom backend calls need their own bounded timeout.
- `didFinish(.cancelled)` means the customer closed without an authorization attempt; `.failure` covers failed presentation or closure after a failed/timed-out attempt; `.success` reflects the last successful attempt reported by your adapter.
- A failed attempt can be retried in the sheet. Reconcile unknown backend outcomes before charging again. If the fixed order/quote has expired, leave/restart with a fresh order quote; Standard has no in-sheet shipping selector to refresh it.

The full [callback/lifecycle reference](apple-pay-express.md#callback-and-lifecycle-reference) applies to Standard as well. The generic [URL initializer](apple-pay-express.md#existing-url-transport-and-migration) sends token/metadata only and does **not** attach your Standard order contacts/reference; use `authorizePayment` for that merchant contract.

## Runnable, parameterized example

```swift
let configuration = try ApplePayDemoConfiguration.load(from: .main)
let order = try ApplePayDemoStandardOrder.load(from: .main)
let checkout = ApplePayDemoCheckout(configuration: configuration, standardOrder: order)
```

Retain `checkout`. These classes belong to the [example source](../Examples/ApplePayDemoSupport/README.md), not the SDK product. You can construct both configuration and order directly from parameters; no merchant/server/contact fallback is embedded in the coordinator. In the apps, edit `ApplePayDemoConfiguration.plist` and `ApplePayDemoStandardOrder.plist`. The order resource represents an earlier merchant checkout and is displayed before the Pay button; it is not an address collected by Apple Pay.

Both example apps offer **Go to Apple Pay Standard Checkout** and **Go to Apple Pay Express Checkout**. The Standard adapter obtains one quote using the precollected address/method, presents fixed totals, and uses the same simulated completion endpoint as Express. That shared server quote is implementation infrastructure, not proof that the Standard sheet collects Express data. See the [exact demo contract and limitations](../Examples/ApplePayDemoSupport/README.md#demo-http-contract).
