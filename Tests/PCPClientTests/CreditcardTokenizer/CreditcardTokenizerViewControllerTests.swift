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

    internal func test_didReceiveScriptErrorMessage_shouldTriggerScriptFailureCompletion() {
        var receivedResults = [Result<CCTokenizerResponse, CCTokenizerError>]()
        let config = makeConfig { result in
            receivedResults.append(result)
        }
        sut = makeSUT(webView: MockWKWebView(evaluateJavaScriptResult: (nil, nil)), config: config)

        sut.userContentController(
            webView.configuration.userContentController,
            didReceive: MockWKScriptMessage(name: CCScriptMessageType.scriptError.rawValue)
        )

        XCTAssertEqual(receivedResults, [.failure(.loadingScriptFailed)])
    }

    internal func test_didReceiveScriptLoadedMessage_shouldAddMessageHandler() {
        let mockUserContentController = MockUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = mockUserContentController
        webView = MockWKWebView(evaluateJavaScriptResult: (nil, nil), configuration: configuration)
        sut = makeSUT(webView: webView)

        sut.userContentController(
            webView.configuration.userContentController,
            didReceive: MockWKScriptMessage(name: CCScriptMessageType.scriptLoaded.rawValue)
        )

        XCTAssert(mockUserContentController.addedHandlers.contains(CCScriptMessageType.submitButtonClicked.rawValue))
    }

    internal func test_didReceiveScriptLoadedMessage_shouldInjectScriptAndOnFailureCompleteWithHTMLFailed() {
        let mockUserContentController = MockUserContentController()
        let webViewConfiguration = WKWebViewConfiguration()
        var receivedResults = [Result<CCTokenizerResponse, CCTokenizerError>]()
        let config = makeConfig { result in
            receivedResults.append(result)
        }
        webViewConfiguration.userContentController = mockUserContentController
        webView = MockWKWebView(evaluateJavaScriptResult: (nil, FakeError.test), configuration: webViewConfiguration)
        sut = makeSUT(webView: webView, config: config)

        sut.userContentController(
            webView.configuration.userContentController,
            didReceive: MockWKScriptMessage(name: CCScriptMessageType.scriptLoaded.rawValue)
        )

        XCTAssertEqual(receivedResults, [.failure(.populatingHTMLFailed)])
    }

    internal func test_didReceiveSubmitButtonClickedMessage_shouldInjectScriptAndAddMessageHandler() throws {
        let mockUserContentController = MockUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = mockUserContentController
        webView = MockWKWebView(evaluateJavaScriptResult: (nil, nil), configuration: configuration)
        sut = makeSUT(webView: webView)

        sut.userContentController(
            webView.configuration.userContentController,
            didReceive: MockWKScriptMessage(name: CCScriptMessageType.submitButtonClicked.rawValue)
        )

        XCTAssert(mockUserContentController.addedHandlers.contains(CCScriptMessageType.responseReceived.rawValue))
        let lastScript = try XCTUnwrap(webView.invokedEvaluateJavaScriptParametersList.last)
        XCTAssert(lastScript.contains("iframes.creditCardCheck('payCallback');"))
    }

    internal func test_didReceiveResponseMessage_withInvalidResponse_shouldTriggerWithInvalidResponseCompletion() {
        var receivedResults = [Result<CCTokenizerResponse, CCTokenizerError>]()
        let config = makeConfig { result in
            receivedResults.append(result)
        }
        webView = MockWKWebView(evaluateJavaScriptResult: (nil, nil))
        sut = makeSUT(webView: webView, config: config)

        sut.userContentController(
            webView.configuration.userContentController,
            didReceive: MockWKScriptMessage(
                name: CCScriptMessageType.responseReceived.rawValue,
                body: ["wrong": "value"]
            )
        )

        XCTAssertEqual(receivedResults, [.failure(.invalidResponse)])
    }

    internal func test_didReceiveResponseMessage_withValidResponse_shouldTriggerSuccessWithResponseCompletion() {
        var receivedResults = [Result<CCTokenizerResponse, CCTokenizerError>]()
        let expectedStatus = "VALID"
        let expectedCardType = "V"
        let expectedPseudoCardPan = "mockPseudoCardPan"
        let expectedTruncatedCardPan = "mockTruncatedCardPan"
        let expectedExpireDate = "2026-01-10"
        let config = makeConfig { result in
            receivedResults.append(result)
        }
        webView = MockWKWebView(evaluateJavaScriptResult: (nil, nil))
        sut = makeSUT(webView: webView, config: config)

        sut.userContentController(
            webView.configuration.userContentController,
            didReceive: MockWKScriptMessage(
                name: CCScriptMessageType.responseReceived.rawValue,
                body: [
                    "cardexpiredate": expectedExpireDate,
                    "cardtype": expectedCardType,
                    "pseudocardpan": expectedPseudoCardPan,
                    "truncatedcardpan": expectedTruncatedCardPan,
                    "status": expectedStatus
                ]
            )
        )

        XCTAssertEqual(receivedResults.count, 1)
        let receivedResult = receivedResults.first
        guard case let .success(receivedResponse) = receivedResult else {
            XCTFail("Expected response result, got \(String(describing: receivedResult))")
            return
        }
        XCTAssertEqual(receivedResponse.status, expectedStatus)
        XCTAssertEqual(receivedResponse.cardExpireDate, expectedExpireDate)
        XCTAssertEqual(receivedResponse.cardType, expectedCardType)
        XCTAssertNil(receivedResponse.errorCode)
        XCTAssertNil(receivedResponse.errorMessage)
        XCTAssertEqual(receivedResponse.pseudoCardpan, expectedPseudoCardPan)
        XCTAssertEqual(receivedResponse.truncatedCardpan, expectedTruncatedCardPan)
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

    private func makeConfig(
        creditcardCheckCallback: ((Result<CCTokenizerResponse, CCTokenizerError>) -> Void)? = nil
    ) -> CreditcardTokenizerConfig {
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
            creditCardCheckCallback: creditcardCheckCallback ?? { _ in
                // Not implemented yet
            }
        )
    }

    private func makeSUT(
        webView: WKWebView?,
        config: CreditcardTokenizerConfig? = nil
    ) -> CreditcardTokenizerViewController {
        if let webView {
            return CreditcardTokenizerViewController(
                webView: webView,
                tokenizerUrl: tokenizerURL,
                request: makeTokenizerRequest(),
                supportedCardTypes: ["M", "J"],
                config: config ?? makeConfig()
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
