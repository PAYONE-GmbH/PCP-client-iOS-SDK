//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import XCTest
@testable import PCPClient

internal final class CreditcardTokenizerConfigTests: XCTestCase {

  // MARK: - FontStyle Tests
  
  func test_fontStyle_initialization() {
    let fontStyle = FontStyle(
      fontSize: "16px",
      fontWeight: "bold",
      fontSizeMobile: "14px"
    )
    
    XCTAssertEqual(fontStyle.fontSize, "16px")
    XCTAssertEqual(fontStyle.fontWeight, "bold")
    XCTAssertEqual(fontStyle.fontSizeMobile, "14px")
  }
  
  func test_fontStyle_initializationWithNilValues() {
    let fontStyle = FontStyle()
    
    XCTAssertNil(fontStyle.fontSize)
    XCTAssertNil(fontStyle.fontWeight)
    XCTAssertNil(fontStyle.fontSizeMobile)
  }
  
  func test_fontStyle_encoding() throws {
    let fontStyle = FontStyle(
      fontSize: "16px",
      fontWeight: "bold",
      fontSizeMobile: "14px"
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(fontStyle)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
    
    XCTAssertEqual(json?["fontSize"], "16px")
    XCTAssertEqual(json?["fontWeight"], "bold")
    XCTAssertEqual(json?["fontSizeMobile"], "14px")
  }
  
  // MARK: - UIConfig Tests
  
  func test_uiConfig_initialization() {
    let labelStyle = FontStyle(fontSize: "14px")
    let uiConfig = UIConfig(
      formBgColor: "#fff",
      formMarginLeft: "10px",
      fieldBgColor: "#f0f0f0",
      labelStyle: labelStyle
    )
    
    XCTAssertEqual(uiConfig.formBgColor, "#fff")
    XCTAssertEqual(uiConfig.formMarginLeft, "10px")
    XCTAssertEqual(uiConfig.fieldBgColor, "#f0f0f0")
    XCTAssertNotNil(uiConfig.labelStyle)
    XCTAssertEqual(uiConfig.labelStyle?.fontSize, "14px")
  }
  
  func test_uiConfig_encoding() throws {
    let uiConfig = UIConfig(
      formBgColor: "#fff",
      btnBgColor: "#007aff",
      btnTextColor: "#ffffff"
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(uiConfig)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["formBgColor"] as? String, "#fff")
    XCTAssertEqual(json?["btnBgColor"] as? String, "#007aff")
    XCTAssertEqual(json?["btnTextColor"] as? String, "#ffffff")
  }
  
  // MARK: - IframeConfig Tests
  
  func test_iframeConfig_initialization() {
    let config = IframeConfig(
      iframeWrapperId: "payment-frame",
      height: 400.0,
      width: 600.0,
      zIndex: 1000
    )
    
    XCTAssertEqual(config.iframeWrapperId, "payment-frame")
    XCTAssertEqual(config.height, 400.0)
    XCTAssertEqual(config.width, 600.0)
    XCTAssertEqual(config.zIndex, 1000)
  }
  
  func test_iframeConfig_objcConvenienceInit() {
    let config = IframeConfig(
      iframeWrapperId: "payment-frame",
      height: NSNumber(value: 400.0) as NSNumber?,
      width: NSNumber(value: 600.0) as NSNumber?,
      zIndex: NSNumber(value: 1000) as NSNumber?
    )
    
    XCTAssertEqual(config.iframeWrapperId, "payment-frame")
    XCTAssertEqual(config.height, 400.0)
    XCTAssertEqual(config.width, 600.0)
    XCTAssertEqual(config.zIndex, 1000)
  }
  
  func test_iframeConfig_objcConvenienceInitWithNilValues() {
    let config = IframeConfig(
      iframeWrapperId: "payment-frame",
      height: nil as NSNumber?,
      width: nil as NSNumber?,
      zIndex: nil as NSNumber?
    )
    
    XCTAssertEqual(config.iframeWrapperId, "payment-frame")
    XCTAssertNil(config.height)
    XCTAssertNil(config.width)
    XCTAssertNil(config.zIndex)
  }
  
  func test_iframeConfig_encoding() throws {
    let config = IframeConfig(
      iframeWrapperId: "payment-frame",
      height: 400.0,
      width: 600.0,
      zIndex: 1000
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(config)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["iframeWrapperId"] as? String, "payment-frame")
    XCTAssertEqual(json?["height"] as? Double, 400.0)
    XCTAssertEqual(json?["width"] as? Double, 600.0)
    XCTAssertEqual(json?["zIndex"] as? Int, 1000)
  }
  
  func test_iframeConfig_encodingWithNilValues() throws {
    let config = IframeConfig(iframeWrapperId: "payment-frame")
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(config)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["iframeWrapperId"] as? String, "payment-frame")
    XCTAssertNil(json?["height"])
    XCTAssertNil(json?["width"])
    XCTAssertNil(json?["zIndex"])
  }
  
  // MARK: - SubmitButtonConfig Tests
  
  func test_submitButtonConfig_initialization() {
    let config = SubmitButtonConfig(selector: "#submit-btn", element: nil)
    
    XCTAssertEqual(config.selector, "#submit-btn")
    XCTAssertNil(config.element)
  }
  
  func test_submitButtonConfig_initializationWithNilValues() {
    let config = SubmitButtonConfig()
    
    XCTAssertNil(config.selector)
    XCTAssertNil(config.element)
  }
  
  // MARK: - FieldErrors Tests
  
  func test_fieldErrors_initialization() {
    let errors = FieldErrors(
      isRequired: "Required field",
      isInvalid: "Invalid input",
      isTooShort: "Too short",
      notSupported: "Not supported"
    )
    
    XCTAssertEqual(errors.isRequired, "Required field")
    XCTAssertEqual(errors.isInvalid, "Invalid input")
    XCTAssertEqual(errors.isTooShort, "Too short")
    XCTAssertEqual(errors.notSupported, "Not supported")
  }
  
  func test_fieldErrors_encoding() throws {
    let errors = FieldErrors(
      isRequired: "Required",
      isInvalid: "Invalid"
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(errors)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["isRequired"] as? String, "Required")
    XCTAssertEqual(json?["isInvalid"] as? String, "Invalid")
  }
  
  // MARK: - LocaleText Classes Tests
  
  func test_localeTextLabels_initialization() {
    let labels = LocaleTextLabels(
      cardNumber: "Card Number",
      cardholderName: "Cardholder Name"
    )
    
    XCTAssertEqual(labels.cardNumber, "Card Number")
    XCTAssertEqual(labels.cardholderName, "Cardholder Name")
  }
  
  func test_localeTextPlaceholders_initialization() {
    let placeholders = LocaleTextPlaceholders(
      cardNumber: "1234 5678 9012 3456",
      cardholderName: "John Doe"
    )
    
    XCTAssertEqual(placeholders.cardNumber, "1234 5678 9012 3456")
    XCTAssertEqual(placeholders.cardholderName, "John Doe")
  }
  
  func test_localeTextAriaLabels_initialization() {
    let ariaLabels = LocaleTextAriaLabels(
      cardNumber: "Enter card number",
      cardholderName: "Enter cardholder name"
    )
    
    XCTAssertEqual(ariaLabels.cardNumber, "Enter card number")
    XCTAssertEqual(ariaLabels.cardholderName, "Enter cardholder name")
  }
  
  func test_localeTextErrors_initialization() {
    let cardErrors = CardNumberErrors(isRequired: "Card number required")
    let errors = LocaleTextErrors(
      cardNumber: cardErrors,
      cardholderName: nil
    )
    
    XCTAssertNotNil(errors.cardNumber)
    XCTAssertEqual(errors.cardNumber?.isRequired, "Card number required")
    XCTAssertNil(errors.cardholderName)
  }
  
  // MARK: - LocaleTextConfig Tests
  
  func test_localeTextConfig_initialization() {
    let labels = LocaleTextLabels(cardNumber: "Card Number")
    let placeholders = LocaleTextPlaceholders(cardNumber: "0000 0000 0000 0000")
    let config = LocaleTextConfig(
      labels: labels,
      placeholders: placeholders,
      arialabels: nil,
      errors: nil
    )
    
    XCTAssertNotNil(config.labels)
    XCTAssertNotNil(config.placeholders)
    XCTAssertNil(config.arialabels)
    XCTAssertNil(config.errors)
  }
  
  func test_localeTextConfig_encoding() throws {
    let labels = LocaleTextLabels(cardNumber: "Card Number")
    let config = LocaleTextConfig(labels: labels)
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(config)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertNotNil(json?["labels"])
  }
  
  // MARK: - CustomTextConfig Tests
  
  func test_customTextConfig_initialization() {
    let enConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Card Number"))
    let deConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Kartennummer"))
    let frConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Numéro de carte"))
    
    let customConfig: [String: LocaleTextConfig] = [
      "en": enConfig,
      "de": deConfig,
      "fr": frConfig
    ]
    
    XCTAssertNotNil(customConfig["en"])
    XCTAssertNotNil(customConfig["de"])
    XCTAssertNotNil(customConfig["fr"])
    XCTAssertEqual(customConfig.count, 3)
  }
  
  func test_customTextConfig_encodingWithEnAndDe() throws {
    let enConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Card Number"))
    let deConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Kartennummer"))
    
    let customConfig: [String: LocaleTextConfig] = [
      "en": enConfig,
      "de": deConfig
    ]
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(customConfig)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertNotNil(json?["en"])
    XCTAssertNotNil(json?["de"])
  }
  
  func test_customTextConfig_encodingWithAdditionalLocales() throws {
    let frConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Numéro de carte"))
    let esConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Número de tarjeta"))
    
    let customConfig: [String: LocaleTextConfig] = [
      "fr": frConfig,
      "es": esConfig
    ]
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(customConfig)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertNotNil(json?["fr"])
    XCTAssertNotNil(json?["es"])
  }
  
  func test_customTextConfig_encodingAllLocales() throws {
    let enConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Card Number"))
    let deConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Kartennummer"))
    let frConfig = LocaleTextConfig(labels: LocaleTextLabels(cardNumber: "Numéro de carte"))
    
    let customConfig: [String: LocaleTextConfig] = [
      "en": enConfig,
      "de": deConfig,
      "fr": frConfig
    ]
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(customConfig)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    // All locales should exist as keys
    XCTAssertNotNil(json?["en"])
    XCTAssertNotNil(json?["de"])
    XCTAssertNotNil(json?["fr"])
  }
  
  // MARK: - CardDetails Tests
  
  func test_cardDetails_initialization() {
    let details = CardDetails(
      cardholderName: "John Doe",
      cardNumber: "1234567890123456",
      expiryDate: "12/25",
      cardType: "visa"
    )
    
    XCTAssertEqual(details.cardholderName, "John Doe")
    XCTAssertEqual(details.cardNumber, "1234567890123456")
    XCTAssertEqual(details.expiryDate, "12/25")
    XCTAssertEqual(details.cardType, "visa")
  }
  
  func test_cardDetails_initFromDictionary() {
    let dict: [String: Any] = [
      "cardholderName": "Jane Smith",
      "cardNumber": "9876543210987654",
      "expiryDate": "06/26",
      "cardType": "mastercard"
    ]
    
    let details = CardDetails(from: dict)
    
    XCTAssertNotNil(details)
    XCTAssertEqual(details?.cardholderName, "Jane Smith")
    XCTAssertEqual(details?.cardNumber, "9876543210987654")
    XCTAssertEqual(details?.expiryDate, "06/26")
    XCTAssertEqual(details?.cardType, "mastercard")
  }
  
  func test_cardDetails_initFromDictionaryWithMissingFields() {
    let dict: [String: Any] = [
      "cardholderName": "Jane Smith",
      "cardNumber": "9876543210987654"
      // Missing expiryDate and cardType
    ]
    
    let details = CardDetails(from: dict)
    
    XCTAssertNil(details)
  }
  
  func test_cardDetails_initFromDictionaryWithWrongTypes() {
    let dict: [String: Any] = [
      "cardholderName": 123, // Wrong type
      "cardNumber": "9876543210987654",
      "expiryDate": "06/26",
      "cardType": "mastercard"
    ]
    
    let details = CardDetails(from: dict)
    
    XCTAssertNil(details)
  }
  
  // MARK: - CreditcardTokenizerConfig Tests
  
  func test_creditcardTokenizerConfig_initialization() {
    let iframeConfig = IframeConfig(iframeWrapperId: "payment-frame")
    let submitConfig = SubmitButtonConfig(selector: "#submit")
    
    let config = CreditcardTokenizerConfig(
      iframeConfig: iframeConfig,
      uiConfig: nil,
      locale: "en_US",
      token: "test-token-123",
      mode: "test",
      allowedCardSchemes: ["visa", "mastercard"],
      customTextConfig: nil,
      submitButtonConfig: submitConfig
    )
    
    XCTAssertEqual(config.locale, "en_US")
    XCTAssertEqual(config.token, "test-token-123")
    XCTAssertEqual(config.mode, "test")
    XCTAssertEqual(config.allowedCardSchemes?.count, 2)
    XCTAssertTrue(config.allowedCardSchemes?.contains("visa") ?? false)
    XCTAssertNil(config.tokenizationSuccessCallback)
    XCTAssertNil(config.tokenizationFailureCallback)
  }
  
  func test_creditcardTokenizerConfig_withCallbacks() {
    let iframeConfig = IframeConfig(iframeWrapperId: "payment-frame")
    let submitConfig = SubmitButtonConfig(selector: "#submit")
    
    var successCalled = false
    var failureCalled = false
    
    let config = CreditcardTokenizerConfig(
      iframeConfig: iframeConfig,
      uiConfig: nil,
      locale: "de_DE",
      token: "test-token",
      mode: "live",
      allowedCardSchemes: ["visa"],
      customTextConfig: nil,
      submitButtonConfig: submitConfig,
      tokenizationSuccessCallback: { _, _, _, _ in successCalled = true },
      tokenizationFailureCallback: { _, _ in failureCalled = true }
    )
    
    XCTAssertNotNil(config.tokenizationSuccessCallback)
    XCTAssertNotNil(config.tokenizationFailureCallback)
    
    // Test callbacks
    let cardDetails = CardDetails(
      cardholderName: "Test",
      cardNumber: "1234",
      expiryDate: "12/25",
      cardType: "visa"
    )
    config.tokenizationSuccessCallback?(200, "token", cardDetails, "manual")
    config.tokenizationFailureCallback?(400, [:])
    
    XCTAssertTrue(successCalled)
    XCTAssertTrue(failureCalled)
  }
  
  func test_creditcardTokenizerConfig_withCompleteUIConfig() {
    let uiConfig = UIConfig(
      formBgColor: "#ffffff",
      formMarginLeft: "20px",
      btnBgColor: "#007aff",
      btnTextColor: "#ffffff"
    )
    let iframeConfig = IframeConfig(
      iframeWrapperId: "payment-frame",
      height: 500,
      width: 400
    )
    let submitConfig = SubmitButtonConfig(selector: "#submit")
    
    let config = CreditcardTokenizerConfig(
      iframeConfig: iframeConfig,
      uiConfig: uiConfig,
      locale: "en_US",
      token: "token",
      mode: "test",
      allowedCardSchemes: ["visa", "mastercard", "amex"],
      customTextConfig: nil,
      submitButtonConfig: submitConfig
    )
    
    XCTAssertNotNil(config.uiConfig)
    XCTAssertEqual(config.uiConfig?.formBgColor, "#ffffff")
    XCTAssertEqual(config.uiConfig?.btnBgColor, "#007aff")
    XCTAssertEqual(config.allowedCardSchemes?.count, 3)
  }
  
  func test_creditcardTokenizerConfig_withCustomTextConfig() {
    let enLabels = LocaleTextLabels(cardNumber: "Card Number", cardholderName: "Name")
    let enConfig = LocaleTextConfig(labels: enLabels)
    let customTextConfig: [String: LocaleTextConfig] = ["en": enConfig]
    
    let iframeConfig = IframeConfig(iframeWrapperId: "payment-frame")
    let submitConfig = SubmitButtonConfig(selector: "#submit")
    
    let config = CreditcardTokenizerConfig(
      iframeConfig: iframeConfig,
      uiConfig: nil,
      locale: "en_US",
      token: "token",
      mode: "test",
      allowedCardSchemes: ["visa"],
      customTextConfig: customTextConfig,
      submitButtonConfig: submitConfig
    )
    
    XCTAssertNotNil(config.customTextConfig)
    XCTAssertNotNil(config.customTextConfig?["en"])
    XCTAssertNotNil(config.customTextConfig?["en"]?.labels)
  }
}
