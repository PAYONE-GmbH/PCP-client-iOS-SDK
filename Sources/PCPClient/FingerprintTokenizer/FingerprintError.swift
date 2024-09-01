//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

/// Errors that could happen during the fingerprint tokenization.
public enum FingerprintError: Error {
    /// An error occurred while running the script. Use the error to get further information.
    case scriptError(error: Error)
    /// Neither an error nor a result were returned by the script. Should not occur.
    case undefined
}
