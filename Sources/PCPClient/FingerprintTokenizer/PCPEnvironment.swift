//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

@objc public enum PCPEnvironment: Int {
    case test
    case production

    var ccTokenizerIdentifier: String {
        switch self {
        case .test:
            return "test"
        case .production:
            return "prod"
        }
    }

    var fingerprintTokenizerIdentifier: String {
        switch self {
        case .test:
            return "t"
        case .production:
            return "p"
        }
    }
}
