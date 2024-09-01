//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import XCTest

internal final class FingerprintTokenizerTests: XCTestCase {
    
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
}
