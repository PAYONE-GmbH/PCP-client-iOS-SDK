//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import WebKit
import XCTest

internal final class CreditcardTokenizerViewControllerTests: XCTestCase {

    // MARK: - Properties

    private let mockNavigation = WKNavigation()
    // swiftlint:disable implicitly_unwrapped_optional force_unwrapping
    private var sut: CreditcardTokenizerViewController!
    private var webView: MockWKWebView!
    private let tokenizerURL = URL(string: "https://payone-test-app-very-long-title.com")!
    // swiftlint:enable implicitly_unwrapped_optional force_unwrapping

    // MARK: - Test Lifecycle

    override internal func setUp() {
        super.setUp()

        webView = MockWKWebView(evaluateJavaScriptResult: (nil, nil))
        sut = makeSUT(webView: webView)
    }

    override internal func tearDown() {
        sut = nil
        webView = nil
        super.tearDown()
    }

    // MARK: - Tests

    internal func test_viewWillAppear_executesURLRequestOnWebViewWithTokenizerURL() throws {
        sut.viewWillAppear(false)

        XCTAssertEqual(webView.invokedLoadWithRequestList.count, 1)
        let firstRequest = try XCTUnwrap(webView.invokedLoadWithRequestList.first)
        XCTAssertEqual(firstRequest.url, tokenizerURL)
    }

    internal func test_viewWillAppear_createsAWebViewAndSetsItOnInstance() {
        sut = makeSUT(webView: nil)

        sut.viewWillAppear(false)

        XCTAssertNotNil(sut.webView)
    }

    internal func test_viewWillAppear_webViewIsSubviewFromView() {
        sut.viewWillAppear(false)

        XCTAssert(sut.view.subviews.contains(webView))
    }

    internal func test_didFinish_withJSEvaluationSuccessForSubmitCheck_injectsPayoneScript() throws {
        webView = MockWKWebView(evaluateJavaScriptResult: (true, nil))
        webView.loadHTMLString("""
        <html>
        <body><button id="submitButton">Check</button></body>
        </html>
        """, baseURL: nil)
        sut = makeSUT(webView: webView)
        sut.viewWillAppear(false)

        sut.webView(webView, didFinish: mockNavigation)

        XCTAssertEqual(webView.invokedEvaluateJavaScriptParametersList.count, 2)
        let firstScript = try XCTUnwrap(webView.invokedEvaluateJavaScriptParametersList.first)
        XCTAssertEqual(firstScript, "document.querySelector(\'#submitButton\') !== null")
        let secondScript = try XCTUnwrap(webView.invokedEvaluateJavaScriptParametersList.last)
        XCTAssert(
            secondScript.contains(
                "script.src = 'https://secure.prelive.pay1-test.de/client-api/js/v1/payone_hosted_min.js';"
            )
        )
    }

    internal func test_didFinish_withoutSubmitButtonElement_checksForSubmitButtonButInjectsNothingAfter() {
        webView.loadHTMLString("""
        <html>
        <body></body>
        </html>
        """, baseURL: nil)
        sut.viewWillAppear(false)

        sut.webView(webView, didFinish: mockNavigation)

        XCTAssertEqual(
            webView.invokedEvaluateJavaScriptParametersList,
            ["document.querySelector(\'#submitButton\') !== null"]
        )
    }

    internal func test_didFinish_withJSEvaluationSuccessForSubmitCheck_addsMessageHandlerForLoadedAndError() {
        let mockUserContentController = MockUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = mockUserContentController
        webView = MockWKWebView(evaluateJavaScriptResult: (true, nil), configuration: configuration)
        webView.loadHTMLString("""
        <html>
        <body><button id="submitButton">Check</button></body>
        </html>
        """, baseURL: nil)
        sut = makeSUT(webView: webView)
        sut.viewWillAppear(false)

        sut.webView(webView, didFinish: mockNavigation)

        XCTAssert(mockUserContentController.addedHandlers.contains(CCScriptMessageType.scriptLoaded.rawValue))
        XCTAssert(mockUserContentController.addedHandlers.contains(CCScriptMessageType.scriptError.rawValue))
    }

    // MARK: - Helpers

    private func makeTokenizerRequest() -> CCTokenizerRequest {
        CCTokenizerRequest(
            mid: "mid",
            aid: "aid",
            portalId: "portalId",
            environment: .production,
            pmiPortalKey: "portalKey"
        )
    }

    private func makeConfig() -> CreditcardTokenizerConfig {
        CreditcardTokenizerConfig(
            cardPan: Field(
                selector: "cardPan",
                style: nil,
                type: "input",
                size: nil,
                maxlength: nil,
                length: [:],
                iframe: [:]
            ),
            cardCvc2: Field(
                selector: "cardCvc2",
                style: nil,
                type: "input",
                size: nil,
                maxlength: nil,
                length: [:],
                iframe: [:]
            ),
            cardExpireMonth: Field(
                selector: "cardExpireMonth",
                style: nil,
                type: "input",
                size: nil,
                maxlength: nil,
                length: [:],
                iframe: [:]
            ),
            cardExpireYear: Field(
                selector: "cardExpireYear",
                style: nil,
                type: "input",
                size: nil,
                maxlength: nil,
                length: [:],
                iframe: [:]
            ),
            defaultStyles: [:],
            language: .english,
            error: "error",
            submitButtonId: "submitButton",
            creditCardCheckCallback: { _ in
                // Not implemented yet
            }
        )
    }

    private func makeSUT(webView: WKWebView?) -> CreditcardTokenizerViewController {
        if let webView {
            return CreditcardTokenizerViewController(
                webView: webView,
                tokenizerUrl: tokenizerURL,
                request: makeTokenizerRequest(),
                supportedCardTypes: ["M", "J"],
                config: makeConfig()
            )
        }
        return CreditcardTokenizerViewController(
            tokenizerUrl: tokenizerURL,
            request: makeTokenizerRequest(),
            supportedCardTypes: ["M", "J"],
            config: makeConfig()
        )
    }
}
