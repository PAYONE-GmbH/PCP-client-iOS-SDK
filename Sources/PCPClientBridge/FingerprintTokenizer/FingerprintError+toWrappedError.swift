//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

extension FingerprintError {
    func toWrappedError() -> FingerprintErrorWrapper {
        switch self {
        case .scriptError:
            return .scriptError
        case .undefined:
            return .undefined
        }
    }
}
