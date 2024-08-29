//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

public class CreditcardTokenizerConfig: NSObject {
    let submitButtonId: String
    let cardPan: Field
    let cardCvc2: Field
    let cardExpireMonth: Field
    let cardExpireYear: Field
    let defaultStyles: [String: String]
    let language: PayoneLanguage
    let error: String
    let creditCardCheckCallback: ((Result<CCTokenizerResponse, CCTokenizerError>) -> Void)

    public init(
        cardPan: Field,
        cardCvc2: Field,
        cardExpireMonth: Field,
        cardExpireYear: Field,
        defaultStyles: [String: String],
        language: PayoneLanguage,
        error: String,
        submitButtonId: String,
        creditCardCheckCallback: @escaping ((Result<CCTokenizerResponse, CCTokenizerError>) -> Void)
    ) {
        self.cardPan = cardPan
        self.cardCvc2 = cardCvc2
        self.cardExpireMonth = cardExpireMonth
        self.cardExpireYear = cardExpireYear
        self.defaultStyles = defaultStyles
        self.language = language
        self.error = error
        self.submitButtonId = submitButtonId
        self.creditCardCheckCallback = creditCardCheckCallback
    }
}

@objc public class Field: NSObject {
    let selector: String
    let style: String?
    let type: String
    let size: String?
    let maxlength: String?
    let length: [String: Int]?
    let iframe: [String: String]?

    @objc init(
        selector: String,
        style: String?,
        type: String,
        size: String?,
        maxlength: String?,
        length: [String : Int]?,
        iframe: [String : String]?
    ) {
        self.selector = selector
        self.style = style
        self.type = type
        self.size = size
        self.maxlength = maxlength
        self.length = length
        self.iframe = iframe
    }
}

@objc public class DefaultStyles: NSObject {
    let htmlElementName: String
    let styles: [String: String]

    @objc public init(htmlElementName: String, styles: [String : String]) {
        self.htmlElementName = htmlElementName
        self.styles = styles
    }
}

@objc public enum PayoneLanguage: Int {
    case english
    case german

    var configValue: String {
        switch self {
        case .english:
            return "Payone.ClientApi.Language.en"
        case .german:
            return "Payone.ClientApi.Language.de"
        }
    }
}
