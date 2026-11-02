//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import WebKit

/// WKUserContentController retains its handler; this proxy prevents retaining the view controller.
internal final class CreditcardTokenizerMessageHandler: NSObject, WKScriptMessageHandler {
    internal static let names = ["scriptError", "responseReceived", "tokenizerDiagnostic"]
    internal weak var receiver: WKScriptMessageHandler?

    internal func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        receiver?.userContentController(userContentController, didReceive: message)
    }

    internal static func diagnostic(_ body: Any, sensitive: Bool) -> (String, [String: Any])? {
        let operations = ["loadScript", "init", "getPaymentPage", "submitForm"]
        guard let body = body as? [String: Any], let operation = body["operation"] as? String,
              operations.contains(operation) || (sensitive && operation == "HTTP"),
              let direction = body["direction"] as? String, ["Request", "Response", "Info"].contains(direction),
              let details = body["details"] as? [String: Any] else { return nil }
        let keys = ["mode", "locale", "statusCode", "tokenProvided", "tokenReturned", "inputMode", "error", "result"]
        return ("\(direction) · \(operation)", sensitive ? details : details.filter { entry in
            keys.contains(entry.key) && (entry.value is String || entry.value is NSNumber)
        })
    }
}
