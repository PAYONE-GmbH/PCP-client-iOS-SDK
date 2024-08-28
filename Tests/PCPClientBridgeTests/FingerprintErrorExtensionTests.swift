//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PCPClient
import XCTest
@testable import PCPClientBridge

final class FingerprintErrorExtensionTests: XCTestCase {

    // MARK: - Tests

    func test_scriptError_toWrappedError_returnsWrappedFingerprintScriptError() {
        let sut = FingerprintError.scriptError(error: FakeError.test)

        let result = sut.toWrappedError()

        XCTAssertEqual(result, .scriptError)
    }

    func test_undefinedError_toWrappedError_returnsWrappedUndefindError() {
        let sut = FingerprintError.undefined

        let result = sut.toWrappedError()

        XCTAssertEqual(result, .undefined)
    }
}
