//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import XCTest

internal final class PCPEnvironmentTests: XCTestCase {

    // MARK: - Tests

    internal func test_ccTokenizerIdentifier_forTest_isCorrect() {
        XCTAssertEqual(PCPEnvironment.test.ccTokenizerIdentifier, "test")
    }

    internal func test_ccTokenizerIdentifier_forProduction_isCorrect() {
        XCTAssertEqual(PCPEnvironment.production.ccTokenizerIdentifier, "prod")
    }

    internal func test_fingerprintTokenizerIdentifier_forTest_isCorrect() {
        XCTAssertEqual(PCPEnvironment.test.fingerprintTokenizerIdentifier, "t")
    }

    internal func test_fingerprintTokenizerIdentifier_forProduction_isCorrect() {
        XCTAssertEqual(PCPEnvironment.production.fingerprintTokenizerIdentifier, "p")
    }
}
