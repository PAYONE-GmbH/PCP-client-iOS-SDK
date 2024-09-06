//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

/// Supported card types that can be passed via the identifier property to the `CreditcardTokenizerConfig`.
@objc public enum SupportedCardType: Int {
    case visa
    case mastercard
    case americanExpress
    case dinersClub
    case jcb
    case maestroInternational
    case chinaUnionPay
    case uatp
    case girocard

    /// The identifier that can be passed to the `CreditcardTokenizerConfig`.
    public var identifier: String {
        switch self {
        case .visa:
            return "V"
        case .mastercard:
            return "M"
        case .americanExpress:
            return "A"
        case .dinersClub:
            return "D"
        case .jcb:
            return "J"
        case .maestroInternational:
            return "O"
        case .chinaUnionPay:
            return "P"
        case .uatp:
            return "U"
        case .girocard:
            return "G"
        }
    }
}
