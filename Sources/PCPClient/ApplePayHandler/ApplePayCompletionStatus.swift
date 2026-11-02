//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

/// Final sheet outcome. Authorization success is determined by the merchant backend.
@objc public enum ApplePayCompletionStatus: Int {
    /// The last authorization attempt succeeded according to the configured backend integration.
    case success
    /// The sheet was closed without an authorization attempt.
    case cancelled
    /// Presentation failed, or the sheet closed after an unsuccessful authorization attempt.
    case failure
}
