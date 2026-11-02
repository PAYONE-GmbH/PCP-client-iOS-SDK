# Credit Card Tokenizer integration

`PCPClient` hosts PAYONE's Hosted Tokenization SDK in a native `WKWebView`. The app supplies an HTML container, a fresh merchant authorization token and configuration. PAYONE's hosted form collects card data and returns a **card token**, not a payment authorization. Your backend uses the returned token in the agreed PCP payment flow.

The [Swift and Objective-C examples](../Examples/CreditcardTokenizerDemoSupport/README.md) use the same configurable screen, accept a token at runtime, and show the request/response trace. Example UI/configuration is not part of the `PCPClient` library product.

## Prerequisites and responsibilities

- Install `PCPClient` using the [installation instructions](../README.md#installation). This guide describes the current repository source; use a revision/release containing these APIs. The SDK supports iOS 15+ and uses Swift tools 5.10. The example apps target iOS 17.5+.
- Obtain a valid, unexpired **merchant authorization token** from your backend for the selected `test`/`live` environment. This is distinct from the card token returned after tokenization. Token issuance, merchant configuration, expiry and any origin restrictions belong to your backend/PAYONE contract. Do not put merchant API secrets in the app.
- Supply a trusted HTML page containing the configured container ID and submit-button selector. Use an HTTPS page, or bundled HTML with a merchant-controlled HTTPS base URL as described below.
- Permit normal HTTPS access to PAYONE's hosted script, form and APIs. Bundling the HTML does not make tokenization work offline. The current adapter pins Hosted Tokenization SDK **1.4.0** with a SHA-384 integrity value; no script version override is exposed by this API.
- Swift consumers use `import PCPClient`. Objective-C can use the exposed `@objc` configuration/controller APIs, or the `PCPClientBridge.CreditcardTokenizerConfigWrapper` convenience wrapper used by older integrations.

The SDK handles WebKit setup, script configuration, the submit bridge and callbacks. It does not issue merchant tokens, create an order, authorize/capture a payment or guarantee that a generated card token is reusable indefinitely. Follow your backend contract for how and when the returned token can be used.

## 1. Provide the HTML

```html
<!DOCTYPE html>
<html>
  <head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
  <body>
    <div id="payment-IFrame"></div>
    <button id="submit" type="button">Tokenize card</button>
  </body>
</html>
```

The wrapper and selector must match `IframeConfig.iframeWrapperId` and `SubmitButtonConfig.selector`. The SDK injects the hosted script; the page need not import it itself. Do not initialize a second Hosted SDK instance in the same page. `SubmitButtonConfig.element` is retained for compatibility but is not used by the native HTML bridge.

### Hosted page

For the example's plist, the alternatives are **`pageURL` alone** for a hosted HTTPS page, or **`htmlResourceName` + `localHTMLBaseURL`** for bundled HTML. A nonempty `pageURL` takes precedence; the unused local keys may be omitted. For the local variant, omit `pageURL` or leave it empty and supply both local keys. See the [two concrete plist variants](../Examples/CreditcardTokenizerDemoSupport/README.md#choose-the-html-source). `localHTMLBaseURL` supplies an origin, not HTML content, and cannot replace `htmlResourceName` by itself.

Pass its HTTPS URL as `tokenizerUrl`. Relative assets resolve normally against that page's origin.

### Bundled page

Include the HTML in the app target's **Copy Bundle Resources**. Obtain its file URL with `Bundle.main.url(forResource:withExtension:)`, and configure a merchant-controlled `localHTMLBaseURL` with scheme `https` and a non-empty host.

```swift
let htmlURL = Bundle.main.url(forResource: "creditcard-tokenizer-example", withExtension: "html")!
let origin = URL(string: "https://your-merchant.example/checkout/")!
```

With both values, the SDK reads the UTF-8 HTML and uses `WKWebView.loadHTMLString(_:baseURL:)`. It does **not** upload the HTML or fetch a page from the base URL. Relative assets resolve against that URL. The current PAYONE preproduction form's `frame-ancestors *` policy rejects a `file://` ancestor, so a plain file load can display the HTML shell while leaving the payment frame blank. An HTTPS base URL solves this for the provided example without changing PAYONE's policy.

For compatibility, a file URL without `localHTMLBaseURL` still uses `loadFileURL` with read access to the containing directory. Hosted HTTPS URLs ignore `localHTMLBaseURL`. Use only HTML and HTTPS origins you control; this option is not a replacement for any merchant-origin configuration required by the processor.

## 2. Build an immutable SDK configuration

This factory takes the short-lived token as a parameter; fetch it from your backend before creating the tokenizer:

```swift
import PCPClient

func makeTokenizerConfig(
    merchantToken: String,
    success: @escaping (Int, String, CardDetails, String) -> Void,
    failure: @escaping (Int, [String: Any]) -> Void
) -> CreditcardTokenizerConfig {
    CreditcardTokenizerConfig(
        iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame", height: 400, width: 400),
        uiConfig: nil,
        locale: "de_DE",
        token: merchantToken,
        mode: "test",
        allowedCardSchemes: ["visa", "mastercard", "amex"],
        customTextConfig: nil,
        submitButtonConfig: SubmitButtonConfig(selector: "#submit"),
        tokenizationSuccessCallback: success,
        tokenizationFailureCallback: failure
    )
}
```

All first eight arguments are required in the Swift initializer even when their value may be `nil`. Additional options have defaults. The mode is trimmed and normalized to lowercase: `test` and `live` are accepted, `nil` means `test`; other values fail with `InvalidConfiguration` rather than silently selecting a different environment.

### Configuration reference

| Parameter | Behavior/default |
| --- | --- |
| `iframeConfig` | Required wrapper ID; optional numeric height/width/zIndex. The adapter supplies **400 / 400 / 9999** when omitted. A numeric height avoids an invisible zero-height frame. PAYONE may resize after initialization. |
| `uiConfig` | Optional `UIConfig`; nil is sent as an empty object. |
| `locale` | Optional hosted-form locale; adapter default `de_DE`. |
| `token` | Required current merchant authorization token; no SDK token provider, persistence or automatic refresh. |
| `mode` | `test` or `live`; default `test`, independent of the HTML hosting location. |
| `allowedCardSchemes` | Optional lowercase network names; nil becomes an empty array so the hosted service selects the available networks. Availability also depends on merchant configuration. |
| `customTextConfig` | Optional dictionary of `LocaleTextConfig` by hosted locale key; nil becomes `{}`. |
| `submitButtonConfig` | Required; selector defaults to `#submit` if nil. The selector must resolve to an HTML control. |
| `email` | Optional prefilled email, notably for Click-to-Pay; default nil. |
| `showCardholderName` | Default true. |
| `customIconsConfig` | Optional icon options; nil becomes `{}`. |
| `ctpConfig` | Optional Click-to-Pay configuration; nil becomes **`{}`**, not `null` (Hosted SDK 1.4.0 requires an object). |
| `tokenizationSuccessCallback` | Optional `(Int, String, CardDetails, String) -> Void`. |
| `tokenizationFailureCallback` | Optional `(Int, [String: Any]) -> Void`. |

The [detailed configuration tables](../README.md#creditcardtokenizerconfig-parameters) and [public configuration types](../Sources/PCPClient/CreditcardTokenizer/CreditcardTokenizerConfig.swift) describe styling, custom text/icons and Click-to-Pay. This refactor retains those public models and initializer signatures.

`UIConfig` forwards optional styling values to the hosted SDK: form/field/error colors and borders; `FontStyle` (`fontSize`, `fontWeight`, `fontSizeMobile`); manual-entry/checkbox/terms styles; button/separator colors; padding, spacing, radius and icon dimensions. `LocaleTextConfig` exposes the typed card fields through `LocaleTextLabels`, placeholders, aria labels and per-field errors. Arbitrary additional JavaScript fields are **not** a raw-JSON passthrough in this typed API.

`CustomIconsConfig` carries `useCustomValidationIcons`, `showCardBrandIcons` and success/error icon paths. Icon accessibility, formats and CORS are handled by the hosted service. `CTPConfig` requires `CTPSchemeConfig` and `CTPTransactionAmount` (decimal string plus currency), with optional `CTPUIConfig`; onboarding/enabling flags default true. Visa requires `srcInitiatorId`/`srcDpaId` and can include the supplied encryption parameters; Mastercard requires its corresponding IDs. Enabling Click-to-Pay also requires the merchant's PAYONE/card-scheme onboarding; setting a flag alone is insufficient.

## 3. Display with SwiftUI or UIKit

### SwiftUI

```swift
CreditcardTokenizerView(
    tokenizerUrl: htmlURL,
    config: config,
    localHTMLBaseURL: origin,
    onDiagnosticEvent: { name, details in
        // Optional UI trace; metadata only by default.
    },
    includeSensitiveDiagnosticData: false
)
```

For an HTTPS-hosted page, omit `localHTMLBaseURL`. The last three initializer parameters default to nil/nil/false. `htmlURL`, `config` and `origin` above are the page URL, immutable configuration and base URL prepared in steps 1–2.

The representable creates one UIKit controller. Updates refresh only the diagnostic callback, not page/config/token. To replace an expired token, create a new configuration and controller/view identity. For example, in an app that stores a current config and generation ID, change that ID and apply `.id(generationID)` to `CreditcardTokenizerView`. The [shared example screen](../Examples/CreditcardTokenizerDemoSupport/CreditcardTokenizerDemoViewController.swift) explicitly replaces its child controller each time a new token is loaded.

The example accepts tokens only through its optional plist `token` entry or its input field. A nonblank plist token loads the form automatically and hides the editor behind **Neuen Token benutzen**. Otherwise input is immediately visible. Use `CreditcardTokenizerDemoView()` in SwiftUI or `CreditcardTokenizerDemoViewController(configuration: settings)` in UIKit; neither has a separate token parameter. This does not change the SDK's required `config.token`; see the [example instructions](../Examples/CreditcardTokenizerDemoSupport/README.md).

### UIKit (Swift)

For manual example runs, set the optional `token` string in `Examples/CreditcardTokenizerDemoSupport/CreditcardTokenizerDemoConfiguration.plist`. Changing the bundled plist requires rebuilding the app; replacing the token using the input field does not.

```swift
let controller = CreditcardTokenizerViewController(tokenizerUrl: htmlURL, config: config)
controller.localHTMLBaseURL = origin
controller.onDiagnosticEvent = { name, details in /* update a trace view if needed */ }
controller.includeSensitiveDiagnosticData = false
navigationController?.pushViewController(controller, animated: true)
```

Set page/diagnostic options before presentation. Configure and present on the main thread; WebKit-delivered success/failure/diagnostic callbacks are also delivered on main. Reappearing does not reload the page or add duplicate constraints/scripts. The controller uses a weak message-handler proxy, so retaining a `WKWebView` does not retain the controller through its script handlers. There is no public refresh/cancel/submit method: submission is the configured HTML button. Ordinary parent/controller removal is standard UIKit containment/navigation.

### Objective-C

Import `PCPClient` and, if using its config wrapper, `PCPClientBridge`. The wrapper's `.creditcardTokenizerConfig` is the SDK config supplied to the controller:

```objectivec
CreditcardTokenizerViewController *controller = [[CreditcardTokenizerViewController alloc]
    initWithTokenizerUrl:htmlURL
    config:wrapper.creditcardTokenizerConfig];
controller.localHTMLBaseURL = origin;
controller.includeSensitiveDiagnosticData = NO;
controller.onDiagnosticEvent = ^(NSString *name, NSDictionary<NSString *, id> *details) {
    // Optional UI trace.
};
[self.navigationController pushViewController:controller animated:YES];
```

`htmlURL`, `origin` and `wrapper` are your prepared URL and configuration values, not globals provided by the SDK. The [Objective-C demo](../Examples/PCPClientObjcDemo/PCPClientObjcDemo/ViewController.m) loads example configuration with `loadFromBundle:error:` and pushes the same shared UIKit screen as the Swift app. Its generated app Swift header and `CreditcardTokenizerDemo*` types are **example infrastructure**, not SDK APIs.

## 4. Handle results

Success signature: `(statusCode, cardToken, cardDetails, inputMode)`. The native bridge requires a **2xx** status, non-empty token, decodable `CardDetails` and an input-mode string. Hosted token creation typically reports 201. The fields of `CardDetails` are `cardholderName`, `cardNumber`, `expiryDate` and `cardType`; these are the service's returned card metadata, not an SDK authorization result. `inputMode` is forwarded (for example manual/registration/Click-to-Pay); do not assume the SDK enforces a closed enum.

Pass the card token to your backend under its payment contract, along with the corresponding order/session reference. Do not treat successful tokenization as a successful payment or infer a token lifetime from this callback.

Failure signature: `(statusCode, errorResponse)`. Actual hosted tokenization error dictionaries are forwarded; SDK-generated failures have status **500** and `errorResponse["error"]` naming a stage:

| Error | Meaning/action |
| --- | --- |
| `LocalHTMLLoadingFailed` | Bundled HTML cannot be read as UTF-8 or the supplied base is not an HTTPS URL with host. Fix resource/config. |
| `PageLoadingFailed` | WebKit page/provisional navigation failed. Check URL/network/hosting. |
| `InvalidConfiguration` | Adapter configuration could not be encoded, including an unsupported mode. |
| `LoadingScriptFailed` | External SDK script failed to load/verify, or its expected global was unavailable. |
| `InitializationFailed` | Script evaluation or asynchronous hosted initialization failed. |
| `SubmitButtonNotFound` | The configured CSS selector did not match a submit control. |
| `SubmissionFailed` | A synchronous exception occurred while invoking hosted submission. |
| `InvalidResponse` | Callback shape/status/token/metadata was invalid. No success is reported. |

`PaymentPageLoadingFailed` is returned in a failure dictionary when the hosted SDK reports a payment-page load error; the reported status is forwarded (zero is normalized to 500). It is not proof of a failed payment, because tokenization has not authorized one. Error stages can arise more than once; callbacks are not a single terminal checkout result. There is no SDK timeout for all hosted-script/frame operations and no automatic retry. Diagnose network/service failures, obtain a new token if needed, and recreate the tokenizer deliberately.

## Optional Requests & Responses diagnostics

`onDiagnosticEvent: (String, [String: Any]) -> Void` emits `Request`, `Response` or `Info` for `loadScript`, `init`, `getPaymentPage` and `submitForm`. Script/init responses describe `loaded`/`ready`, not fabricated HTTP status codes. By default only metadata such as mode/locale/status, input mode and token-present/returned flags is emitted.

`includeSensitiveDiagnosticData` defaults to **false**. When explicitly enabled before presentation, it also includes raw merchant/card tokens and callback details, and installs a document-start script in the hosted frames to inspect submitted `fetch`/`XMLHttpRequest` requests and their responses. HTTP events include an ID, URL, request method/headers/body or response status/body; matching IDs join a pair. Individual keystrokes are not logged. It observes text/JSON traffic to the supported PAYONE API hosts, not every browser request or inaccessible/non-text resource. The HTTP script clones fetch streams rather than consuming the originals.

The educational example enables this mode via its plist, shows up to 100 entries in memory, and does not print or persist them. Application code controls what it does with diagnostics. This option is for controlled example/debug usage: it can display authorization headers, tokens and submitted card values. Disabling the option after presentation does not remove an already installed script; recreate the controller to change that mode.

## Compatibility, structure and verification

Public configuration types, existing initializers, SwiftUI entry points and callback signatures remain available. The adapter now safely JSON-encodes merchant-provided strings, normalizes valid modes, rejects unknown modes instead of silently falling back to test, requires valid 2xx success callbacks, avoids repeated appearance reloads and removes the script-handler retain cycle. Nil CTP configuration remains a non-null object, and omitted dimensions remain numeric 400/400/9999. The actual sensitive network diagnostic is now installed before page/frame navigation, rather than in a test-only initializer.

Internals are separated into [controller/lifecycle](../Sources/PCPClient/CreditcardTokenizer/CreditcardTokenizerViewController.swift), [script/configuration builder](../Sources/PCPClient/CreditcardTokenizer/CreditcardTokenizerScriptBuilder.swift), [weak message bridge/diagnostic filtering](../Sources/PCPClient/CreditcardTokenizer/CreditcardTokenizerMessageHandler.swift) and [opt-in HTTP diagnostic script](../Sources/PCPClient/CreditcardTokenizer/CreditcardTokenizerDiagnosticScript.swift). These helpers are not new public integration APIs.

See the [example setup/configuration/source map](../Examples/CreditcardTokenizerDemoSupport/README.md) and [controller tests](../Tests/PCPClientTests/CreditcardTokenizer/CreditcardTokenizerViewControllerTests.swift). Tests cover configuration quoting in real WebKit, default iframe height, lifecycle/ownership, callbacks, local/remote HTML, optional detailed HTTP diagnostics and example configuration. Offline tests use synthetic tokens and Hosted SDK stubs, not bank processing.

```sh
xcodebuild test -scheme PCPClient-Package -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -quiet
xcodebuild build -project Examples/PCPClientSwiftDemo/PCPClientSwiftDemo.xcodeproj -scheme PCPClientSwiftDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet
xcodebuild build -project Examples/PCPClientObjcDemo/PCPClientObjcDemo.xcodeproj -scheme PCPClientObjcDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet
```

Select an installed simulator as needed. On a signed device, verify initial form rendering, a supported PAYONE test card, successful card-token callback, invalid/expired-token handling, validation errors, reload with a fresh token and both examples' UI/trace behavior. A passing build/test does not establish real token creation against your merchant configuration.
