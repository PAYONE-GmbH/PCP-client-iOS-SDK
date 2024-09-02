//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import WebKit

final class MockWKWebView: WKWebView {
    internal var invokedEvaluateJavaScriptParametersList = [String]()
    internal var evaluateJavaScriptResult: ((Any?, (any Error)?))

    internal init(evaluateJavaScriptResult: (Any?, (any Error)?)) {
        self.evaluateJavaScriptResult = evaluateJavaScriptResult
        super.init(frame: CGRect.zero, configuration: WKWebViewConfiguration())
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("\(#function ) has not been implemented")
    }

    override public func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: ((Any?, (any Error)?) -> Void)? = nil
    ) {
        invokedEvaluateJavaScriptParametersList.append(javaScriptString)
        completionHandler?(evaluateJavaScriptResult.0, evaluateJavaScriptResult.1)
    }
}
