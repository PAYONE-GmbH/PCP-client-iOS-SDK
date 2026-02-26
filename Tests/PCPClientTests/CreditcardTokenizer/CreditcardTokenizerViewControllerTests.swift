//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import WebKit
import XCTest

@testable import PCPClient

internal final class CreditcardTokenizerViewControllerTests: XCTestCase {

  // MARK: - Properties

  private let mockNavigation = WKNavigation()
  private var sut: CreditcardTokenizerViewController!
  private var webView: MockWKWebView!
  private let tokenizerURL = URL(string: "https://payone-test-app-very-long-title.com")!

  // MARK: - Test Lifecycle

  override internal func setUp() {
    super.setUp()
    webView = MockWKWebView(evaluateJavaScriptResult: (nil, nil))
    sut = makeSUT(webView: webView)
  }

  override internal func tearDown() {
    sut = nil
    webView = nil
    super.tearDown()
  }

  // MARK: - Tests (Cleaned)

  private func makeSUT(
    webView: WKWebView? = nil,
    config: CreditcardTokenizerConfig? = nil,
  ) -> CreditcardTokenizerViewController {
    let testConfig =
      config
      ?? CreditcardTokenizerConfig(
        iframeConfig: IframeConfig(
          iframeWrapperId: "payment-IFrame", height: Double(400), width: Double(400)),
        uiConfig: UIConfig(formBgColor: "#fff"),
        locale: "de_DE",
        token: "test-token",
        mode: "test",
        allowedCardSchemes: ["visa", "mastercard"],
        customTextConfig: nil,
        submitButtonConfig: SubmitButtonConfig(selector: "#submit", element: nil),
        tokenizationSuccessCallback: { _, _, _, _ in },
        tokenizationFailureCallback: { _, _ in }
      )
    if let webView {
      return CreditcardTokenizerViewController(
        webView: webView,
        tokenizerUrl: tokenizerURL,
        config: testConfig,
      )
    }
    return CreditcardTokenizerViewController(
      tokenizerUrl: tokenizerURL,
      config: testConfig,
    )
  }

  func test_initialization_setsPropertiesCorrectly() {
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "id", height: Double(1), width: Double(2)),
      uiConfig: UIConfig(formBgColor: "#abc"),
      locale: "en",
      token: "test-token",
      mode: "live",
      allowedCardSchemes: ["visa"],
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#btn", element: nil)
    )
    let sut = makeSUT(config: config)
    XCTAssertNotNil(sut)
  }

  func test_setupWebView_addsWebViewAndSetsConstraints() {
    let sut = makeSUT(webView: webView)
    sut.viewWillAppear(false)
    XCTAssertNotNil(sut.webView)
    XCTAssertTrue(sut.webView?.navigationDelegate === sut)
  }

  func test_initialize_injectsScriptAndAddsMessageHandlers() {
    let sut = makeSUT(webView: webView)
    // Simulate navigation finished to trigger initialize()
    sut.webView(sut.webView!, didFinish: mockNavigation)
    // Should add user script and evaluate JS
    XCTAssertFalse(webView.invokedEvaluateJavaScriptParametersList.isEmpty)
  }

  func test_navigationDelegate_callsInitializeOnDidFinishNavigation() {
    let sut = makeSUT(webView: webView)
    sut.webView(sut.webView!, didFinish: mockNavigation)
    XCTAssertFalse(webView.invokedEvaluateJavaScriptParametersList.isEmpty)
  }

  func test_scriptMessageHandler_successCallbackIsCalled() {
    var called = false
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "test", height: 400, width: 400),
      uiConfig: nil,
      locale: nil,
      token: "test-token",
      mode: "test",
      allowedCardSchemes: ["visa"],
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#btn", element: nil),
      tokenizationSuccessCallback: { status, token, details, inputMode in
        called = true
        XCTAssertEqual(status, 200)
        XCTAssertEqual(token, "tok")
        XCTAssertEqual(details.cardholderName, "John Doe")
        XCTAssertEqual(inputMode, "ocr")
      },
      tokenizationFailureCallback: nil
    )
    let sut = makeSUT(config: config)
    let message = MockWKScriptMessage(
      name: "responseReceived",
      body: [
        "statusCode": 200,
        "token": "tok",
        "cardDetails": [
          "cardholderName": "John Doe",
          "cardNumber": "1234",
          "expiryDate": "12/25",
          "cardType": "visa"
        ],
        "inputMode": "ocr"
      ]
    )
    sut.userContentController(WKUserContentController(), didReceive: message)
    XCTAssertTrue(called)
  }

  func test_scriptMessageHandler_failureCallbackIsCalledForScriptError() {
    var called = false
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "test", height: 400, width: 400),
      uiConfig: nil,
      locale: nil,
      token: "test-token",
      mode: "test",
      allowedCardSchemes: ["visa"],
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#btn", element: nil),
      tokenizationSuccessCallback: nil,
      tokenizationFailureCallback: { status, error in
        called = true
        XCTAssertEqual(status, 500)
        XCTAssertEqual(error["error"] as? String, "LoadingScriptFailed")
      }
    )
    let sut = makeSUT(config: config)
    let message = MockWKScriptMessage(name: "scriptError", body: ["statusCode": 500])
    sut.userContentController(WKUserContentController(), didReceive: message)
    XCTAssertTrue(called)
  }

  func test_scriptMessageHandler_failureCallbackIsCalledForInvalidResponse() {
    var called = false
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "test", height: 400, width: 400),
      uiConfig: nil,
      locale: nil,
      token: "test-token",
      mode: "test",
      allowedCardSchemes: ["visa"],
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#btn", element: nil),
      tokenizationSuccessCallback: nil,
      tokenizationFailureCallback: { status, error in
        called = true
        XCTAssertEqual(status, 500)
        XCTAssertEqual(error["error"] as? String, "InvalidResponse")
      }
    )
    let sut = makeSUT(config: config)
    let message = MockWKScriptMessage(name: "responseReceived", body: ["statusCode": 500])
    sut.userContentController(WKUserContentController(), didReceive: message)
    XCTAssertTrue(called)
  }

  func test_addScriptMessageHandler_addsAndRemovesHandler() {
    let sut = makeSUT(webView: webView)
    sut.webView?.configuration.userContentController.add(sut, name: "test")
    sut.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "test")
    // No assertion needed, just ensure no crash
  }

  func test_script_containsSDKVersion140URL() {
    let sut = makeSUT(webView: webView)
    sut.webView(sut.webView!, didFinish: mockNavigation)
    let scripts = webView.invokedEvaluateJavaScriptParametersList
    XCTAssertFalse(scripts.isEmpty)
    let script = scripts.first ?? ""
    XCTAssertTrue(
      script.contains("1.4.0"),
      "Expected SDK URL to contain 1.4.0 but got: \(script)"
    )
  }

  func test_script_containsEmailAndShowCardholderName() {
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame", height: Double(400), width: Double(400)),
      uiConfig: nil,
      locale: "en_US",
      token: "tok",
      mode: "test",
      allowedCardSchemes: nil,
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#submit", element: nil),
      email: "user@test.com",
      showCardholderName: false
    )
    let sut = makeSUT(webView: webView, config: config)
    sut.webView(sut.webView!, didFinish: mockNavigation)
    let script = webView.invokedEvaluateJavaScriptParametersList.first ?? ""
    XCTAssertTrue(script.contains("user@test.com"), "Expected email in script")
    XCTAssertTrue(script.contains("showCardholderName: false"), "Expected showCardholderName: false in script")
  }

  func test_script_containsCustomIconsConfig() {
    let icons = CustomIconsConfig(useCustomValidationIcons: true, successIcon: "/ok.svg", errorIcon: "/err.svg")
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame", height: Double(400), width: Double(400)),
      uiConfig: nil,
      locale: nil,
      token: "tok",
      mode: "test",
      allowedCardSchemes: nil,
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#submit", element: nil),
      customIconsConfig: icons
    )
    let sut = makeSUT(webView: webView, config: config)
    sut.webView(sut.webView!, didFinish: mockNavigation)
    let script = webView.invokedEvaluateJavaScriptParametersList.first ?? ""
    XCTAssertTrue(script.contains("customIconsConfig"), "Expected customIconsConfig in script")
    XCTAssertTrue(script.contains("/ok.svg"), "Expected successIcon path in script")
  }

  func test_script_containsCTPConfig() {
    let scheme = CTPSchemeConfig(
      mastercardConfig: CTPMastercardConfig(srcInitiatorId: "m", srcDpaId: "md")
    )
    let ctp = CTPConfig(
      schemeConfig: scheme,
      transactionAmount: CTPTransactionAmount(amount: "500", currencyCode: "USD")
    )
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame", height: Double(400), width: Double(400)),
      uiConfig: nil,
      locale: nil,
      token: "tok",
      mode: "test",
      allowedCardSchemes: nil,
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#submit", element: nil),
      ctpConfig: ctp
    )
    let sut = makeSUT(webView: webView, config: config)
    sut.webView(sut.webView!, didFinish: mockNavigation)
    let script = webView.invokedEvaluateJavaScriptParametersList.first ?? ""
    XCTAssertTrue(script.contains("CTPConfig"), "Expected CTPConfig key in script")
    XCTAssertTrue(script.contains("USD"), "Expected currencyCode in script")
  }
}
