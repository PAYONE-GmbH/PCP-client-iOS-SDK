# Apple Pay: Standard and Express

The iOS SDK supports **both native payment flows through the same `ApplePayHandler`**. Choose the request configuration and the source of order data; there is no separate Express payment product or SDK dependency.

| | Standard payment flow | Express payment flow |
| --- | --- | --- |
| Entry point | Final payment step after the merchant checkout | Cart/product checkout shortcut |
| Order contacts | Collected by the merchant **before** Apple Pay | Collected through the Apple Pay sheet |
| Shipping selection | Already selected before presentation | Selected and updated inside the sheet |
| Amount | Fixed, authoritative order total at presentation | Initial total recalculated on contact/shipping changes |
| SDK configuration | Payment request, authorization callback, final-result observer | Same plus async contact/shipping update callbacks |
| Authorization | Encrypted Apple token sent to merchant backend | The same processing flow, with final Apple contacts and current cart quote |

## Integration guides

- **[Standard payment flow](apple-pay-standard.md):** precollected order data, fixed shipping/amount, request construction, Swift/Objective-C wiring and backend token mapping.
- **[Express payment flow](apple-pay-express.md):** sheet contact collection, dynamic shipping/total updates and complete callback/lifecycle reference.
- **[Parameterized Swift and Objective-C examples](../Examples/ApplePayDemoSupport/README.md):** two explicit menu entries sharing a checkout adapter, transport and configuration. Their backend simulates completion, **not a PAYONE payment**.

Both flows require the same merchant identity, Apple Pay capability/provisioning, processing-certificate/backend association, and device eligibility. Native PassKit does not need web merchant validation, Apple Pay JS or a Merchant Identity certificate. See the [shared prerequisites](apple-pay-express.md#prerequisites), [callback reference](apple-pay-express.md#callback-and-lifecycle-reference) and [existing URL-transport contract](apple-pay-express.md#existing-url-transport-and-migration).

The SDK presents/controls the native sheet and forwards callbacks. Your backend creates/verifies the payment and order; backend authentication, actual processing, capture and 3DS/redirect handling are not implemented by the client SDK or by the simulated example server.
