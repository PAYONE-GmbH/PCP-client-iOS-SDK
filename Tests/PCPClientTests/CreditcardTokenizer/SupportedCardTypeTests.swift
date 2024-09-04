//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import XCTest

internal final class SupportedCardTypeTests: XCTestCase {

    // MARK: - Tests

    internal func test_identifier_forDifferentCardTypes_returnsCorrectString() {
        XCTAssertEqual(SupportedCardType.visa.identifier, "V")
        XCTAssertEqual(SupportedCardType.mastercard.identifier, "M")
        XCTAssertEqual(SupportedCardType.americanExpress.identifier, "A")
        XCTAssertEqual(SupportedCardType.dinersClub.identifier, "D")
        XCTAssertEqual(SupportedCardType.jcb.identifier, "J")
        XCTAssertEqual(SupportedCardType.maestroInternational.identifier, "O")
        XCTAssertEqual(SupportedCardType.chinaUnionPay.identifier, "P")
        XCTAssertEqual(SupportedCardType.uatp.identifier, "U")
        XCTAssertEqual(SupportedCardType.girocard.identifier, "G")
    }
}
