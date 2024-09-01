//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

// swiftlint:disable one_declaration_per_file
@objc public class Field: NSObject {
    internal let selector: String
    internal let style: String?
    internal let type: String
    internal let size: String?
    internal let maxlength: String?
    internal let length: [String: Int]
    internal let iframe: [String: String]

    @objc public init(
        selector: String,
        style: String?,
        type: String,
        size: String?,
        maxlength: String?,
        length: [String: Int],
        iframe: [String: String]
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
    internal let htmlElementName: String
    internal let styles: [String: String]

    @objc public init(htmlElementName: String, styles: [String: String]) {
        self.htmlElementName = htmlElementName
        self.styles = styles
    }
}

@objc public enum PayoneLanguage: Int {
    case english
    case german

    internal var configValue: String {
        switch self {
        case .english:
            return "Payone.ClientApi.Language.en"
        case .german:
            return "Payone.ClientApi.Language.de"
        }
    }
}

public class CreditcardTokenizerConfig: NSObject {
    internal let submitButtonId: String
    internal let cardPan: Field
    internal let cardCvc2: Field
    internal let cardExpireMonth: Field
    internal let cardExpireYear: Field
    internal let defaultStyles: [String: String]
    internal let language: PayoneLanguage
    internal let error: String
    internal let creditCardCheckCallback: ((Result<CCTokenizerResponse, CCTokenizerError>) -> Void)

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
// swiftlint:enable one_declaration_per_file
