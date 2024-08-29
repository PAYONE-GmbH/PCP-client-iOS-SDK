//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

@objc public class CCTokenizerResponse: NSObject, Codable {
    let cardExpireDate: String?
    let cardType: String?
    let errorCode: String?
    let errorMessage: String?
    let pseudoCardpan: String?
    let status: String?
    let truncatedCardpan: String?

    enum CodingKeys: String, CodingKey {
        case cardExpireDate = "cardexpiredate"
        case cardType = "cardtype"
        case errorCode = "errorcode"
        case errorMessage = "errormessage"
        case pseudoCardpan = "pseudocardpan"
        case status
        case truncatedCardpan = "truncatedcardpan"
    }
}
