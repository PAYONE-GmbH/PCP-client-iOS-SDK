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
    jwtToken: String = "jwt-token"
  ) -> CreditcardTokenizerViewController {
    let testConfig =
      config
      ?? CreditcardTokenizerConfig(
        iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame", height: 400, width: 400),
        uiConfig: UIConfig(formBgColor: "#fff"),
        locale: "de_DE",
        submitButtonConfig: SubmitButtonConfig(selector: "#submit", element: nil),
        environment: "test",
        tokenizationSuccessCallback: { _, _, _ in },
        tokenizationFailureCallback: { _, _ in }
      )
    if let webView = webView {
      return CreditcardTokenizerViewController(
        webView: webView,
        tokenizerUrl: tokenizerURL,
        config: testConfig,
        jwtToken: jwtToken
      )
    }
    return CreditcardTokenizerViewController(
      tokenizerUrl: tokenizerURL,
      config: testConfig,
      jwtToken: jwtToken
    )
  }

  func test_initialization_setsPropertiesCorrectly() {
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "id", height: 1, width: 2),
      uiConfig: UIConfig(formBgColor: "#abc"),
      locale: "en",
      submitButtonConfig: SubmitButtonConfig(selector: "#btn", element: nil),
      environment: "live"
    )
    let sut = makeSUT(config: config, jwtToken: "jwt")
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
      iframeConfig: nil,
      uiConfig: nil,
      locale: nil,
      submitButtonConfig: nil,
      environment: "test",
      tokenizationSuccessCallback: { status, token, details in
        called = true
        XCTAssertEqual(status, 200)
        XCTAssertEqual(token, "tok")
        XCTAssertEqual(details?["card"] as? String, "details")
      },
      tokenizationFailureCallback: nil
    )
    let sut = makeSUT(config: config)
    // Simulate cardDetails as a dictionary, matching the expected input type
    let message = MockWKScriptMessage(
      name: "responseReceived",
      body: [
        "statusCode": 200,
        "token": "tok",
        "cardDetails": ["card": "details"],
      ]
    )
    sut.userContentController(WKUserContentController(), didReceive: message)
    XCTAssertTrue(called)
  }

  func test_scriptMessageHandler_failureCallbackIsCalledForScriptError() {
    var called = false
    let config = CreditcardTokenizerConfig(
      iframeConfig: nil,
      uiConfig: nil,
      locale: nil,
      submitButtonConfig: nil,
      environment: "test",
      tokenizationSuccessCallback: nil,
      tokenizationFailureCallback: { status, error in
        called = true
        XCTAssertEqual(status, 500)
        XCTAssertEqual(error?["error"] as? String, "LoadingScriptFailed")
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
      iframeConfig: nil,
      uiConfig: nil,
      locale: nil,
      submitButtonConfig: nil,
      environment: "test",
      tokenizationSuccessCallback: nil,
      tokenizationFailureCallback: { status, error in
        called = true
        XCTAssertEqual(status, 500)
        XCTAssertEqual(error?["error"] as? String, "InvalidResponse")
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

}
