//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

@testable import PCPClient
import XCTest

internal final class PayoneLanguageTests: XCTestCase {

    // MARK: - Tests

    internal func test_configValue_forDifferentLanguages_returnsCorrectStrings() {
        XCTAssertEqual(PayoneLanguage.german.configValue, "Payone.ClientApi.Language.de")
        XCTAssertEqual(PayoneLanguage.english.configValue, "Payone.ClientApi.Language.en")
    }
}
