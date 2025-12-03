//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

// swiftlint:disable one_declaration_per_file

// MARK: - FontStyle
@objc public class FontStyle: NSObject, Encodable {
  public let fontSize: String?
  public let fontWeight: String?
  public let fontSizeMobile: String?

  @objc public init(
    fontSize: String? = nil,
    fontWeight: String? = nil,
    fontSizeMobile: String? = nil
  ) {
    self.fontSize = fontSize
    self.fontWeight = fontWeight
    self.fontSizeMobile = fontSizeMobile
  }
}

// MARK: - UIConfig
@objc public class UIConfig: NSObject, Encodable {
  public let formBgColor: String?
  public let formMarginLeft: String?
  public let formMarginRight: String?
  public let fieldBgColor: String?
  public let fieldBorder: String?
  public let fieldOutline: String?
  public let fieldLabelColor: String?
  public let fieldPlaceholderColor: String?
  public let fieldTextColor: String?
  public let fieldErrorCodeColor: String?
  public let fontFamily: String?
  public let fontUrl: String?
  public let labelStyle: FontStyle?
  public let inputStyle: FontStyle?
  public let errorValidationStyle: FontStyle?
  public let manualEntryFormLabelStyle: FontStyle?
  public let checkboxLabelStyle: FontStyle?
  public let termsTextStyle: FontStyle?
  public let checkboxLabelColor: String?
  public let checkboxSize: String?
  public let btnBgColor: String?
  public let btnTextColor: String?
  public let btnBorderColor: String?
  public let separatorColor: String?
  public let separatorTextColor: String?
  public let termsTextColor: String?
  public let inputBorderRadius: String?
  public let inputBorderColorDefault: String?
  public let inputBorderColorSuccess: String?
  public let inputBorderColorError: String?
  public let inputFocusOutline: String?
  public let inputPadding: String?
  public let fieldSpacingVertical: String?
  public let labelMarginBottom: String?
  public let inputMarginBottom: String?
  public let errorMarginBottom: String?
  public let buttonMarginBottom: String?
  public let separatorTextMarginBottom: String?
  public let checkboxTextMarginBottom: String?
  public let termsTextMarginBottom: String?
  public let iconWidth: String?
  public let iconPaddingRight: String?

  @objc public init(
    formBgColor: String? = nil,
    formMarginLeft: String? = nil,
    formMarginRight: String? = nil,
    fieldBgColor: String? = nil,
    fieldBorder: String? = nil,
    fieldOutline: String? = nil,
    fieldLabelColor: String? = nil,
    fieldPlaceholderColor: String? = nil,
    fieldTextColor: String? = nil,
    fieldErrorCodeColor: String? = nil,
    fontFamily: String? = nil,
    fontUrl: String? = nil,
    labelStyle: FontStyle? = nil,
    inputStyle: FontStyle? = nil,
    errorValidationStyle: FontStyle? = nil,
    manualEntryFormLabelStyle: FontStyle? = nil,
    checkboxLabelStyle: FontStyle? = nil,
    termsTextStyle: FontStyle? = nil,
    checkboxLabelColor: String? = nil,
    checkboxSize: String? = nil,
    btnBgColor: String? = nil,
    btnTextColor: String? = nil,
    btnBorderColor: String? = nil,
    separatorColor: String? = nil,
    separatorTextColor: String? = nil,
    termsTextColor: String? = nil,
    inputBorderRadius: String? = nil,
    inputBorderColorDefault: String? = nil,
    inputBorderColorSuccess: String? = nil,
    inputBorderColorError: String? = nil,
    inputFocusOutline: String? = nil,
    inputPadding: String? = nil,
    fieldSpacingVertical: String? = nil,
    labelMarginBottom: String? = nil,
    inputMarginBottom: String? = nil,
    errorMarginBottom: String? = nil,
    buttonMarginBottom: String? = nil,
    separatorTextMarginBottom: String? = nil,
    checkboxTextMarginBottom: String? = nil,
    termsTextMarginBottom: String? = nil,
    iconWidth: String? = nil,
    iconPaddingRight: String? = nil
  ) {
    self.formBgColor = formBgColor
    self.formMarginLeft = formMarginLeft
    self.formMarginRight = formMarginRight
    self.fieldBgColor = fieldBgColor
    self.fieldBorder = fieldBorder
    self.fieldOutline = fieldOutline
    self.fieldLabelColor = fieldLabelColor
    self.fieldPlaceholderColor = fieldPlaceholderColor
    self.fieldTextColor = fieldTextColor
    self.fieldErrorCodeColor = fieldErrorCodeColor
    self.fontFamily = fontFamily
    self.fontUrl = fontUrl
    self.labelStyle = labelStyle
    self.inputStyle = inputStyle
    self.errorValidationStyle = errorValidationStyle
    self.manualEntryFormLabelStyle = manualEntryFormLabelStyle
    self.checkboxLabelStyle = checkboxLabelStyle
    self.termsTextStyle = termsTextStyle
    self.checkboxLabelColor = checkboxLabelColor
    self.checkboxSize = checkboxSize
    self.btnBgColor = btnBgColor
    self.btnTextColor = btnTextColor
    self.btnBorderColor = btnBorderColor
    self.separatorColor = separatorColor
    self.separatorTextColor = separatorTextColor
    self.termsTextColor = termsTextColor
    self.inputBorderRadius = inputBorderRadius
    self.inputBorderColorDefault = inputBorderColorDefault
    self.inputBorderColorSuccess = inputBorderColorSuccess
    self.inputBorderColorError = inputBorderColorError
    self.inputFocusOutline = inputFocusOutline
    self.inputPadding = inputPadding
    self.fieldSpacingVertical = fieldSpacingVertical
    self.labelMarginBottom = labelMarginBottom
    self.inputMarginBottom = inputMarginBottom
    self.errorMarginBottom = errorMarginBottom
    self.buttonMarginBottom = buttonMarginBottom
    self.separatorTextMarginBottom = separatorTextMarginBottom
    self.checkboxTextMarginBottom = checkboxTextMarginBottom
    self.termsTextMarginBottom = termsTextMarginBottom
    self.iconWidth = iconWidth
    self.iconPaddingRight = iconPaddingRight
  }
}

// MARK: - IframeConfig
@objc public class IframeConfig: NSObject, Encodable {
  public let iframeWrapperId: String
  public let height: Double?
  public let width: Double?
  public let zIndex: Int?

  public init(
    iframeWrapperId: String,
    height: Double? = nil,
    width: Double? = nil,
    zIndex: Int? = nil
  ) {
    self.iframeWrapperId = iframeWrapperId
    self.height = height
    self.width = width
    self.zIndex = zIndex
  }

  // Objective-C convenience initializer
  @objc public convenience init(
    iframeWrapperId: String,
    height: NSNumber?,
    width: NSNumber?,
    zIndex: NSNumber?
  ) {
    self.init(
      iframeWrapperId: iframeWrapperId,
      height: height?.doubleValue,
      width: width?.doubleValue,
      zIndex: zIndex?.intValue
    )
  }

  private enum CodingKeys: String, CodingKey {
    case iframeWrapperId, height, width, zIndex
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(iframeWrapperId, forKey: .iframeWrapperId)
    if let height {
      try container.encode(height, forKey: .height)
    }
    if let width {
      try container.encode(width, forKey: .width)
    }
    if let zIndex {
      try container.encode(zIndex, forKey: .zIndex)
    }
  }
}

// MARK: - SubmitButtonConfig
@objc public class SubmitButtonConfig: NSObject {
  public let selector: String?
  // For iOS, element can be a UIView reference, but for now keep as AnyObject?
  public let element: AnyObject?

  @objc public init(
    selector: String? = nil,
    element: AnyObject? = nil
  ) {
    self.selector = selector
    self.element = element
  }
}

// MARK: - FieldErrors
@objc public class FieldErrors: NSObject, Encodable {
  public let isRequired: String?
  public let isInvalid: String?
  public let isTooShort: String?
  public let notSupported: String?

  @objc public init(
    isRequired: String? = nil,
    isInvalid: String? = nil,
    isTooShort: String? = nil,
    notSupported: String? = nil
  ) {
    self.isRequired = isRequired
    self.isInvalid = isInvalid
    self.isTooShort = isTooShort
    self.notSupported = notSupported
  }
}

// MARK: - LocaleTextLabels
@objc public class LocaleTextLabels: NSObject, Encodable {
  public let cardNumber: String?
  public let cardholderName: String?

  @objc public init(
    cardNumber: String? = nil,
    cardholderName: String? = nil
  ) {
    self.cardNumber = cardNumber
    self.cardholderName = cardholderName
  }
}

// MARK: - LocaleTextPlaceholders
@objc public class LocaleTextPlaceholders: NSObject, Encodable {
  public let cardNumber: String?
  public let cardholderName: String?

  @objc public init(
    cardNumber: String? = nil,
    cardholderName: String? = nil
  ) {
    self.cardNumber = cardNumber
    self.cardholderName = cardholderName
  }
}

// MARK: - LocaleTextAriaLabels
@objc public class LocaleTextAriaLabels: NSObject, Encodable {
  public let cardNumber: String?
  public let cardholderName: String?

  @objc public init(
    cardNumber: String? = nil,
    cardholderName: String? = nil
  ) {
    self.cardNumber = cardNumber
    self.cardholderName = cardholderName
  }
}

// MARK: - LocaleTextErrors
@objc public class LocaleTextErrors: NSObject, Encodable {
  public let cardNumber: FieldErrors?
  public let cardholderName: FieldErrors?

  @objc public init(
    cardNumber: FieldErrors? = nil,
    cardholderName: FieldErrors? = nil
  ) {
    self.cardNumber = cardNumber
    self.cardholderName = cardholderName
  }
}

// MARK: - LocaleTextConfig
@objc public class LocaleTextConfig: NSObject, Encodable {
  public let labels: LocaleTextLabels?
  public let placeholders: LocaleTextPlaceholders?
  public let arialabels: LocaleTextAriaLabels?
  public let errors: LocaleTextErrors?

  @objc public init(
    labels: LocaleTextLabels? = nil,
    placeholders: LocaleTextPlaceholders? = nil,
    arialabels: LocaleTextAriaLabels? = nil,
    errors: LocaleTextErrors? = nil
  ) {
    self.labels = labels
    self.placeholders = placeholders
    self.arialabels = arialabels
    self.errors = errors
  }
}

// MARK: - CustomTextConfig
@objc public class CustomTextConfig: NSObject, Encodable {
  public let en: LocaleTextConfig?
  public let de: LocaleTextConfig?
  public let locales: [String: LocaleTextConfig]?

  @objc public init(
    en: LocaleTextConfig? = nil,
    de: LocaleTextConfig? = nil,
    locales: [String: LocaleTextConfig]? = nil
  ) {
    self.en = en
    self.de = de
    self.locales = locales
  }

  private enum CodingKeys: String, CodingKey {
    case en, de
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let en {
      try container.encode(en, forKey: .en)
    }
    if let de {
      try container.encode(de, forKey: .de)
    }
    // For additional locales, we need to handle them dynamically
    if let locales {
      for (key, value) in locales where key != "en" && key != "de" {
        try container.encode(value, forKey: CodingKeys(stringValue: key)!)
      }
    }
  }
}

// MARK: - CardDetails
@objc public class CardDetails: NSObject {
  public let cardholderName: String
  public let cardNumber: String
  public let expiryDate: String
  public let cardType: String

  @objc public init(
    cardholderName: String,
    cardNumber: String,
    expiryDate: String,
    cardType: String
  ) {
    self.cardholderName = cardholderName
    self.cardNumber = cardNumber
    self.expiryDate = expiryDate
    self.cardType = cardType
  }

  convenience init?(from dict: [String: Any]) {
    guard let cardholderName = dict["cardholderName"] as? String,
          let cardNumber = dict["cardNumber"] as? String,
          let expiryDate = dict["expiryDate"] as? String,
          let cardType = dict["cardType"] as? String else {
      return nil
    }
    self.init(
      cardholderName: cardholderName,
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      cardType: cardType
    )
  }
}

// MARK: - CreditcardTokenizerConfig
/// The configuration object to set up the creditcard tokenizer.
@objc public class CreditcardTokenizerConfig: NSObject {
  public let iframeConfig: IframeConfig
  public let uiConfig: UIConfig?
  public let locale: String?
  public let token: String
  public let mode: String?  // "test" or "live"
  public let allowedCardSchemes: [String]?
  public let customTextConfig: CustomTextConfig?
  public let submitButtonConfig: SubmitButtonConfig
  public let tokenizationSuccessCallback: ((Int, String, CardDetails, String) -> Void)?
  public let tokenizationFailureCallback: ((Int, [String: Any]) -> Void)?

  @objc public init(
    iframeConfig: IframeConfig,
    uiConfig: UIConfig?,
    locale: String?,
    token: String,
    mode: String?,
    allowedCardSchemes: [String]?,
    customTextConfig: CustomTextConfig?,
    submitButtonConfig: SubmitButtonConfig,
    tokenizationSuccessCallback: ((Int, String, CardDetails, String) -> Void)? = nil,
    tokenizationFailureCallback: ((Int, [String: Any]) -> Void)? = nil
  ) {
    self.iframeConfig = iframeConfig
    self.uiConfig = uiConfig
    self.locale = locale
    self.token = token
    self.mode = mode 
    self.allowedCardSchemes = allowedCardSchemes
    self.customTextConfig = customTextConfig
    self.submitButtonConfig = submitButtonConfig
    self.tokenizationSuccessCallback = tokenizationSuccessCallback
    self.tokenizationFailureCallback = tokenizationFailureCallback
  }
}
// swiftlint:enable one_declaration_per_file
