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

internal final class FingerprintTokenizerTests: XCTestCase {

    // MARK: - Properties

    private let mockNavigation = WKNavigation()
    private let paylaPartnerId = "PAYparId"
    private let merchId = "merch"
    private let sessionId = "sessionId"
    // swiftlint:disable implicitly_unwrapped_optional
    private var sut: FingerprintTokenizer!
    // swiftlint:enable implicitly_unwrapped_optional

    // MARK: - Test Lifecycle

    override internal func setUp() {
        super.setUp()

        sut = FingerprintTokenizer(
            paylaPartnerId: paylaPartnerId,
            partnerMerchantId: merchId,
            environment: .test,
            sessionId: sessionId
        )
    }

    override internal func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    internal func test_successfulJSEvaluation_afterDidFinishNavigation_completesWithToken() {
        var receivedResults = [Result<String, FingerprintError>]()
        let expectation = expectation(description: #function)
        let expectedString = "\(paylaPartnerId)_\(merchId)_\(sessionId)"
        let mockWKWebView = MockWKWebView(evaluateJavaScriptResult: (nil, nil))
        sut.getSnippetToken { result in
            receivedResults.append(result)
            expectation.fulfill()
        }

        sut.webView(mockWKWebView, didFinish: mockNavigation)

        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(receivedResults, [.success(expectedString)])
    }

    internal func test_failureJSEvaluation_afterDidFinishNavigation_completesScriptError() {
        var receivedResults = [Result<String, FingerprintError>]()
        let expectation = expectation(description: #function)
        let mockWKWebView = MockWKWebView(evaluateJavaScriptResult: (nil, FakeError.test))
        sut.getSnippetToken { result in
            receivedResults.append(result)
            expectation.fulfill()
        }

        sut.webView(mockWKWebView, didFinish: mockNavigation)

        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(receivedResults, [.failure(.scriptError(error: FakeError.test))])
    }

    internal func test_JSEvaluation_afterDidFinishNavigation_sendsCorrectScriptToWebView() {
        let mockWKWebView = MockWKWebView(evaluateJavaScriptResult: (nil, FakeError.test))

        sut.webView(mockWKWebView, didFinish: mockNavigation)

        XCTAssertEqual(mockWKWebView.invokedEvaluateJavaScriptParametersList, [ #"paylaDcs.init("p", "pcp_init");"#])
    }
}
