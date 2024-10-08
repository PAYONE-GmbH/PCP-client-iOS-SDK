//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

/// The environment you want the SDK to run against.
@objc public enum PCPEnvironment: Int {
    case test
    case production
    
    internal var ccTokenizerIdentifier: String {
        switch self {
        case .test:
            return "test"
        case .production:
            return "prod"
        }
    }

    internal var fingerprintTokenizerIdentifier: String {
        switch self {
        case .test:
            return "t"
        case .production:
            return "p"
        }
    }
}
