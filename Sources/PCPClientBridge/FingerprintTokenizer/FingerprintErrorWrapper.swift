//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

/// Wraps `FingerprintError` to a format that can be used by Objective-C apps.
@objc public enum FingerprintErrorWrapper: Int, Error {
    /// An error occurred while running the script. Use the error to get further information.
    case scriptError
    /// Neither an error nor a result were returned by the script. Should not occur.
    case undefined

    /// A description that can be used in Objective-C apps to understand the occuring error.
    public var errorDescription: String {
        switch self {
        case .scriptError:
            return "Script error: Loading or execution of fingerprinting script failed."
        case .undefined:
            return "Undefined: Neither error nor result was returned by script."
        }
    }
}
