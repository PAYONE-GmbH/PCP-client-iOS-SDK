//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import WebKit

// swiftlint:disable all
internal final class MockWKWebView: WKWebView {
    internal var invokedEvaluateJavaScriptParametersList = [String]()
    internal var evaluateJavaScriptResult: ((Any?, (any Error)?))

    internal init(evaluateJavaScriptResult: (Any?, (any Error)?)) {
        self.evaluateJavaScriptResult = evaluateJavaScriptResult
        super.init(frame: CGRect.zero, configuration: WKWebViewConfiguration())
    }

    @available(*, unavailable)
    internal required init?(coder _: NSCoder) {
        fatalError("\(#function ) has not been implemented")
    }

    override internal func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: ((Any?, (any Error)?) -> Void)? = nil
    ) {
        invokedEvaluateJavaScriptParametersList.append(javaScriptString)
        completionHandler?(evaluateJavaScriptResult.0, evaluateJavaScriptResult.1)
    }

    internal var invokedLoadWithRequestList = [URLRequest]()

    override internal func load(_ request: URLRequest) -> WKNavigation? {
        invokedLoadWithRequestList.append(request)
        return nil
    }
}
// swiftlint:enable all
