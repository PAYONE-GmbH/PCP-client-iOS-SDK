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
  public let height: Double?
  public let width: Double?

  public init(
    iframeWrapperId: String,
    height: Double? = nil,
    width: Double? = nil
  ) {
    self.iframeWrapperId = iframeWrapperId
    self.height = height
    self.width = width
  }

  // Objective-C convenience initializer
  @objc public convenience init(
    iframeWrapperId: String,
    height: NSNumber?,
    width: NSNumber?
  ) {
    self.init(
      iframeWrapperId: iframeWrapperId,
      height: height?.doubleValue,
      width: width?.doubleValue
    )
  }

  private enum CodingKeys: String, CodingKey {
    case iframeWrapperId, height, width
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

/// The configuration object to set up the creditcard tokenizer.
@objc public class CreditcardTokenizerConfig: NSObject {
  public let iframeConfig: IframeConfig?
  public let uiConfig: UIConfig?
  public let locale: String?
  public let submitButtonConfig: SubmitButtonConfig?
  public let environment: String  // "test" or "live"
  public let tokenizationSuccessCallback: ((Int, String, [String: Any]) -> Void)?
  public let tokenizationFailureCallback: ((Int, [String: Any]) -> Void)?

  @objc public init(
    iframeConfig: IframeConfig?,
    uiConfig: UIConfig?,
    locale: String?,
    submitButtonConfig: SubmitButtonConfig?,
    environment: String,
    tokenizationSuccessCallback: ((Int, String, [String: Any]) -> Void)? = nil,
    tokenizationFailureCallback: ((Int, [String: Any]) -> Void)? = nil
  ) {
    self.iframeConfig = iframeConfig
    self.uiConfig = uiConfig
    self.locale = locale
    self.submitButtonConfig = submitButtonConfig
    self.environment = environment
    self.tokenizationSuccessCallback = tokenizationSuccessCallback
    self.tokenizationFailureCallback = tokenizationFailureCallback
  }
}
// swiftlint:enable one_declaration_per_file
