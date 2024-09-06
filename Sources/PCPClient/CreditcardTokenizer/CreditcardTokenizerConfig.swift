//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

// swiftlint:disable one_declaration_per_file
/// A customizable field configuration for the required fields that will be injected into the website of the
/// creditcard tokenizer.
@objc public class Field: NSObject {
    internal let selector: String
    internal let style: String?
    internal let type: String
    internal let size: String?
    internal let maxlength: String?
    internal let length: [String: Int]
    internal let iframe: [String: String]
    
    /// Initializer for the `Field` of the creditcard tokenizer.
    /// - Parameters:
    ///   - selector: The selector (HTML ID) in your provided HTML where the input field should be injected.
    ///   - style: Customized style options (CSS).
    ///   - type: The HTML type of the element. Recommended `input`.
    ///   - size: -
    ///   - maxlength: The maximum length of characters allowed.
    ///   - length: The different lengths for card types. For example for a CVC with different lengths.
    ///   - iframe: Different styling options to send to the iframe. Key-value like "width": "40px".
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

/// The language of the creditcard tokenizer. Currently English or German available.
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

/// The configuration object to set up the creditcard tokenizer.
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
