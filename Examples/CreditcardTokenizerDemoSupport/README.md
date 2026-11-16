# Credit Card Tokenizer example

Both example apps use this shared UIKit screen. It is example infrastructure, not part of the `PCPClient` library product. See the [SDK integration guide](../../docs/creditcard-tokenizer.md).

## Run and configure

1. Open the Swift or Objective-C project under `Examples/` and run on a Simulator or signed device.
2. Open **Go to Creditcard Tokenizer** (Swift) or the Creditcard Tokenizer action (Objective-C).
3. Paste a freshly issued merchant authorization token from your backend into the token input.
4. Tap **Formular mit diesem Token laden**. Enter a supported test card and press the HTML submit button.
5. Check the visible result and the **Requests & Responses** section. Replace an expired token in the input and load again; no rebuild is needed.

The demo has exactly two token sources:

- **Plist:** Enter a fresh token in the optional `token` string in `CreditcardTokenizerDemoConfiguration.plist` and rebuild. A nonblank value loads the form automatically and hides the editor. **Neuen Token benutzen** reveals an empty input for a replacement; loading it creates a fresh form and hides the editor again.
- **Input field:** With a missing, empty or whitespace-only plist token, the editor is immediately visible. Paste a token and load the form without rebuilding.

There is no separate token parameter on the example screen or its SwiftUI wrapper. A plist token is bundled with the app; do not commit real token values. Runtime replacements and the latest 100 diagnostic events are held in memory only; **Protokoll leeren** removes the events. Regular SDK integrations obtain their token from their backend and pass it through `CreditcardTokenizerConfig.token`.

Both app targets copy the same [CreditcardTokenizerDemoConfiguration.plist](CreditcardTokenizerDemoConfiguration.plist) and root [HTML example](../../creditcard-tokenizer-example.html). The optional token is empty in the checked-in example:

| Parameter | Meaning |
| --- | --- |
| `pageURL` | HTTPS page URL. Leave empty to use the bundled HTML. |
| `htmlResourceName` | Bundle resource name without `.html`, used when `pageURL` is empty. |
| `localHTMLBaseURL` | Merchant-controlled HTTPS origin for the bundled page. The HTML is not uploaded or fetched from this URL. |
| `mode` | `test` or `live`. Must match the token/backend environment. |
| `token` | Optional initial token; missing, empty or whitespace-only means manual input. Rebuild after changing the plist. |
| `locale` | Hosted form locale, for example `de_DE`. |
| `iframeWrapperID` | Element ID present in the HTML. |
| `submitButtonSelector` | CSS selector for the HTML submit control. |
| `iframeHeight`, `iframeWidth` | Positive initial dimensions in CSS pixels. |
| `allowedCardSchemes` | Hosted SDK card-network names. Empty array delegates selection to PAYONE. |
| `showCardholderName` | Whether the form requests the name field. |
| `includeSensitiveDiagnosticData` | This educational example enables full payload inspection. The SDK default is **false**. |

The bundled example currently uses the existing merchant demo server as its HTTPS base; that server does **not** issue PCP card authorization tokens. Supply your own token provider and merchant-controlled origin for another integration.

### Choose the HTML source

Configure exactly one of these two variants in `CreditcardTokenizerDemoConfiguration.plist`. The snippets show only the HTML-source keys; keep the other configuration fields listed above.

**Local file + HTTPS base URL:**

```xml
<key>htmlResourceName</key>
<string>creditcard-tokenizer-example</string>
<key>localHTMLBaseURL</key>
<string>https://your-merchant.example/checkout/</string>
```

`pageURL` may be omitted or empty. The named `.html` file must be included in Copy Bundle Resources. Both `htmlResourceName` and `localHTMLBaseURL` are required for this variant: the former selects the file, the latter supplies its HTTPS origin and resolves relative assets. The base URL does not fetch or upload the HTML. Without a suitable HTTPS origin, PAYONE's current frame security policy blocks the embedded card form even though the local page itself loads. Use an origin controlled by your integration, not an arbitrary third-party domain.

**Hosted HTML page:**

```xml
<key>pageURL</key>
<string>https://your-merchant.example/creditcard-tokenizer-example.html</string>
```

`htmlResourceName` and `localHTMLBaseURL` may both be omitted: the page is fetched from `pageURL` and already has an HTTPS origin. It must contain the configured iframe wrapper and submit control. A nonempty `pageURL` takes precedence over the local-file settings; `localHTMLBaseURL` alone is not a hosted-page address. Rebuild the app after editing the bundled plist. Both variants still require network access to PAYONE's hosted services and a valid token.

Programmatic configuration is equally possible: construct `CreditcardTokenizerDemoConfiguration` with all parameters, then `CreditcardTokenizerDemoViewController(configuration:)`. Objective-C uses `initWithConfiguration:` and can load the resource using `loadFromBundle:error:`. Both apps use the same implementation.

## Source map

- [Configuration](CreditcardTokenizerDemoConfiguration.swift): required initializer parameters, plist validation and creation of the SDK configuration from a runtime token.
- [Screen](CreditcardTokenizerDemoViewController.swift): token input, reloadable child controller, results and event history.
- [SwiftUI wrapper](../PCPClientSwiftDemo/PCPClientSwiftDemo/CreditcardTokenizerDemoView.swift): navigation integration only.
- SDK `CreditcardTokenizerViewController`: WebKit lifecycle, not a token provider or payment backend.

## Diagnostics and limits

Metadata describes `loadScript`, `init`, `getPaymentPage` and `submitForm` calls/callbacks. In sensitive mode, additional request/response entries inspect `fetch` and `XMLHttpRequest` traffic to the supported PAYONE API hosts inside the hosted frame. Matching IDs connect each HTTP pair. It records submitted payloads, not keystrokes. Authorization headers, tokens and submitted card values are visible with this option; nothing is printed to the console or persisted by the example.

This flow produces a **card token**, not a payment authorization. Actual tokenization requires a valid, unexpired PCP token, reachable hosted PAYONE services, an eligible card and correct merchant configuration. Automated tests use synthetic tokens and offline Hosted SDK stubs. A successful build/test does not replace checking token creation against your merchant test backend.
