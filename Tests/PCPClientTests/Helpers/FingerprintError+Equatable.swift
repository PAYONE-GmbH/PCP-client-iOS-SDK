//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PCPClient

extension FingerprintError: Equatable {
    public static func == (lhs: PCPClient.FingerprintError, rhs: PCPClient.FingerprintError) -> Bool {
        switch (lhs, rhs) {
        case (.scriptError, .scriptError):
            return true
        case (.undefined, .undefined):
            return true
        default:
            return false
        }
    }
}
