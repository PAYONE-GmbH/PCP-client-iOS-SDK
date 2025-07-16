//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import XCTest

internal final class CCScriptMessageTypeTests: XCTestCase {

    // MARK: - Tests

    internal func test_makeWebkitMessageString_withBody_forDifferentCases_makesCorrectScriptMessageStrings() {
        let body = "hello"
        let expectedScriptErrorString = "window.webkit.messageHandlers.scriptError.postMessage(\(body));"
        let expectedResponseReceivedString = "window.webkit.messageHandlers.responseReceived.postMessage(\(body));"

        XCTAssertEqual(
            CCScriptMessageType.scriptError.makeWebkitMessageString(body: body),
            expectedScriptErrorString
        )
        XCTAssertEqual(
            CCScriptMessageType.responseReceived.makeWebkitMessageString(body: body),
            expectedResponseReceivedString
        )
    }
}
