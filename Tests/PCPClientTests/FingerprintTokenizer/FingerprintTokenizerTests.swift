//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import XCTest
import WebKit

extension FingerprintError: Equatable {
    public static func == (lhs: PCPClient.FingerprintError, rhs: PCPClient.FingerprintError) -> Bool {
        switch (lhs, rhs) {
        case (.scriptError, .scriptError):
            return true
        case (.undefined, .undefined):
            return true
        default:
            return false
        }
    }
}

internal final class FingerprintTokenizerTests: XCTestCase {

    // MARK: - Properties

    private let mockNavigation = WKNavigation()

    // MARK: - Tests

    internal func test_getSnippetToken_afterInitWithIds_setsUpCorrectScript() {
        let expectation = expectation(description: #function)
        let paylaPartnerId = "PAYparId"
        let merchId = "merch"
        let sut = FingerprintTokenizer(
            paylaPartnerId: paylaPartnerId,
            partnerMerchantId: merchId,
            environment: .test
        )
        let expectedScript = "\n<script id=\"paylaDcs\" type=\"text/javascript\" " +
            "src=\"https://d.payla.io/dcs/\(paylaPartnerId)/\(merchId)/dcs.js\"></script>"
        sut.getSnippetToken { _ in
            sut.webView?.evaluateJavaScript("document.body.innerHTML", completionHandler: { html, _ in
                XCTAssertEqual(html as? String, expectedScript)
                expectation.fulfill()
            })
        }

        wait(for: [expectation], timeout: 3.0)
    }

    internal func test_successfulJSEvaluation_afterDidFinishNavigation_completesWithToken() {
        var receivedResults = [Result<String, FingerprintError>]()
        let expectation = expectation(description: #function)
        let paylaPartnerId = "PAYparId"
        let merchId = "merch"
        let sessionId = "sessionId"
        let expectedString = "\(paylaPartnerId)_\(merchId)_\(sessionId)"
        let mockWKWebView = MockWKWebView(evaluateJavaScriptResult: (nil, nil))
        let sut = FingerprintTokenizer(
            paylaPartnerId: paylaPartnerId,
            partnerMerchantId: merchId,
            environment: .test,
            sessionId: sessionId
        )
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
        let paylaPartnerId = "PAYparId"
        let merchId = "merch"
        let sessionId = "sessionId"
        let mockWKWebView = MockWKWebView(evaluateJavaScriptResult: (nil, FakeError.test))
        let sut = FingerprintTokenizer(
            paylaPartnerId: paylaPartnerId,
            partnerMerchantId: merchId,
            environment: .test,
            sessionId: sessionId
        )
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
        let sut = FingerprintTokenizer(
            paylaPartnerId: "paylaPartnerId",
            partnerMerchantId: "partnerMerchantId",
            environment: .test
        )

        sut.webView(mockWKWebView, didFinish: mockNavigation)

        XCTAssertEqual(mockWKWebView.invokedEvaluateJavaScriptParametersList, [ #"paylaDcs.init("p", "pcp_init");"#])
    }
}
