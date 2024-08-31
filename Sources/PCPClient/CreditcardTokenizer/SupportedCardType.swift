//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

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
