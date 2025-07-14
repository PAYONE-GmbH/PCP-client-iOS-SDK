//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

// swiftlint:disable one_declaration_per_file

@objc public class UIConfig: NSObject, Encodable {
  public let formBgColor: String?
  public let fieldBgColor: String?
  public let fieldBorder: String?
  public let fieldOutline: String?
  public let fieldLabelColor: String?
  public let fieldPlaceholderColor: String?
  public let fieldTextColor: String?
  public let fieldErrorCodeColor: String?

  @objc public init(
    formBgColor: String? = nil,
    fieldBgColor: String? = nil,
    fieldBorder: String? = nil,
    fieldOutline: String? = nil,
    fieldLabelColor: String? = nil,
    fieldPlaceholderColor: String? = nil,
    fieldTextColor: String? = nil,
    fieldErrorCodeColor: String? = nil
  ) {
    self.formBgColor = formBgColor
    self.fieldBgColor = fieldBgColor
    self.fieldBorder = fieldBorder
    self.fieldOutline = fieldOutline
    self.fieldLabelColor = fieldLabelColor
    self.fieldPlaceholderColor = fieldPlaceholderColor
    self.fieldTextColor = fieldTextColor
    self.fieldErrorCodeColor = fieldErrorCodeColor
  }
}

@objc public class IframeConfig: NSObject, Encodable {
  public let iframeWrapperId: String
  public let height: NSNumber?
  public let width: NSNumber?

  @objc public init(
    iframeWrapperId: String,
    height: NSNumber? = nil,
    width: NSNumber? = nil
  ) {
    self.iframeWrapperId = iframeWrapperId
    self.height = height
    self.width = width
  }

  private enum CodingKeys: String, CodingKey {
    case iframeWrapperId, height, width
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(iframeWrapperId, forKey: .iframeWrapperId)
    if let height = height {
      try container.encode(height.doubleValue, forKey: .height)
    }
    if let width = width {
      try container.encode(width.doubleValue, forKey: .width)
    }
  }
}

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
  public let iframeConfig: IframeConfig?
  public let uiConfig: UIConfig?
  public let locale: String?
  public let submitButtonConfig: SubmitButtonConfig?
  public let environment: String  // "test" or "live"
  public let error: String?
  public let tokenizationSuccessCallback: ((Int, String, [String: Any]?) -> Void)?
  public let tokenizationFailureCallback: ((Int, [String: Any]?) -> Void)?

  @objc public init(
    iframeConfig: IframeConfig? = nil,
    uiConfig: UIConfig? = nil,
    locale: String? = nil,
    submitButtonConfig: SubmitButtonConfig? = nil,
    environment: String,
    error: String? = nil,
    tokenizationSuccessCallback: ((Int, String, [String: Any]?) -> Void)? = nil,
    tokenizationFailureCallback: ((Int, [String: Any]?) -> Void)? = nil
  ) {
    self.iframeConfig = iframeConfig
    self.uiConfig = uiConfig
    self.locale = locale
    self.submitButtonConfig = submitButtonConfig
    self.environment = environment
    self.error = error
    self.tokenizationSuccessCallback = tokenizationSuccessCallback
    self.tokenizationFailureCallback = tokenizationFailureCallback
  }
}
// swiftlint:enable one_declaration_per_file
