//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

@objc
public enum FingerprintErrorWrapper: Int, Error {
    case scriptError
    case undefined

    public var errorDescription: String {
        switch self {
        case .scriptError:
            return "Script error: Loading or execution of fingerprinting script failed."
        case .undefined:
            return "Undefined: Neither error nor result was returned by script."
        }
    }
}
