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

  func test_localHTMLWithHTTPSBaseLoadsBundledContentsWithoutRequestingHostedHTML() throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".html")
    let html = "<html><body><div id='payment-IFrame'></div></body></html>"
    try html.write(to: file, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: file) }
    let baseURL = URL(string: "https://merchant.example/checkout/")!
    let sut = makeSUT(webView: webView, url: file)
    sut.localHTMLBaseURL = baseURL

    sut.viewWillAppear(false)

    XCTAssertEqual(webView.invokedLoadHTML.count, 1)
    XCTAssertEqual(webView.invokedLoadHTML.first?.html, html)
    XCTAssertEqual(webView.invokedLoadHTML.first?.baseURL, baseURL)
    XCTAssertTrue(webView.invokedLoadWithRequestList.isEmpty)
    XCTAssertTrue(webView.invokedLoadFileURLs.isEmpty)
  }

  private func makeSUT(
    webView: WKWebView? = nil,
    config: CreditcardTokenizerConfig? = nil,
    url: URL? = nil,
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
        tokenizerUrl: url ?? tokenizerURL,
        config: testConfig,
      )
    }
    return CreditcardTokenizerViewController(
      tokenizerUrl: url ?? tokenizerURL,
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
    XCTAssertEqual(webView.invokedLoadWithRequestList.last?.url, tokenizerURL)
    XCTAssertTrue(webView.invokedLoadFileURLs.isEmpty)
  }

  func test_reappearingDoesNotReloadPageOrDuplicateConstraintsAndScripts() {
    sut.beginAppearanceTransition(true, animated: false)
    sut.endAppearanceTransition()
    let constraints = sut.view.constraints.count
    let scripts = webView.configuration.userContentController.userScripts.count
    sut.beginAppearanceTransition(false, animated: false)
    sut.endAppearanceTransition()
    sut.beginAppearanceTransition(true, animated: false)
    sut.endAppearanceTransition()
    XCTAssertEqual(webView.invokedLoadWithRequestList.count, 1)
    XCTAssertEqual(sut.view.constraints.count, constraints)
    XCTAssertEqual(webView.configuration.userContentController.userScripts.count, scripts)
  }

  func test_sensitiveNetworkInstrumentationIsInstalledDuringActualSetup() {
    sut.includeSensitiveDiagnosticData = true
    XCTAssertTrue(webView.configuration.userContentController.userScripts.isEmpty)
    sut.beginAppearanceTransition(true, animated: false)
    sut.endAppearanceTransition()
    let scripts = webView.configuration.userContentController.userScripts
    XCTAssertEqual(scripts.count, 1)
    XCTAssertEqual(scripts.first?.source, CreditcardTokenizerDiagnosticScript.source)
    XCTAssertEqual(scripts.first?.injectionTime, .atDocumentStart)
    XCTAssertEqual(scripts.first?.isForMainFrameOnly, false)
  }

  func test_retainedWebViewDoesNotRetainControllerThroughMessageHandlers() {
    weak var weakController: CreditcardTokenizerViewController?
    autoreleasepool {
      var controller: CreditcardTokenizerViewController? = makeSUT(webView: webView)
      weakController = controller
      controller?.beginAppearanceTransition(true, animated: false)
      controller?.endAppearanceTransition()
      controller = nil
    }
    XCTAssertNil(weakController)
    XCTAssertNotNil(webView)
  }

  func test_quotedConfigurationReachesHostedSDKUnchangedInWebKit() {
    let received = expectation(description: "Quoted merchant configuration")
    let credential = "synthetic'\"\\\ncredential"
    let email = "quote\"\\@example.test"
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame"), uiConfig: nil, locale: "de_DE",
      token: credential, mode: " TEST ", allowedCardSchemes: nil, customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "[id='submit']"), email: email,
      tokenizationFailureCallback: { status, body in
        XCTAssertEqual(status, 422)
        XCTAssertEqual(body["token"] as? String, credential)
        XCTAssertEqual(body["email"] as? String, email)
        XCTAssertEqual(body["mode"] as? String, "test")
        received.fulfill()
      }
    )
    let browser = WKWebView()
    let controller = makeSUT(webView: browser, config: config)
    browser.navigationDelegate = controller
    browser.loadHTMLString("""
      <html><head><script>
      window.HostedTokenizationSdk = {
        init: function() { return Promise.resolve(); },
        getPaymentPage: function(config) {
          window.webkit.messageHandlers.responseReceived.postMessage({statusCode: 422, errorResponse: {
            token: config.token, email: config.email, mode: config.mode
          }});
        }
      };
      document.head.appendChild = function(script) { script.onload(); return script; };
      </script></head><body><button id="submit">Submit</button></body></html>
      """, baseURL: nil)
    wait(for: [received], timeout: 5)
    withExtendedLifetime(controller) {}
  }

  func test_nonSuccessfulStatusWithTokenFieldsCannotBeReportedAsSuccess() {
    var failures = 0
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame"), uiConfig: nil, locale: nil,
      token: "test", mode: "test", allowedCardSchemes: nil, customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#submit"),
      tokenizationSuccessCallback: { _, _, _, _ in XCTFail("Must not accept unsuccessful response") },
      tokenizationFailureCallback: { _, _ in failures += 1 }
    )
    let controller = makeSUT(config: config)
    controller.userContentController(WKUserContentController(), didReceive: MockWKScriptMessage(
      name: "responseReceived", body: [
        "statusCode": 400, "token": "unexpected-token", "inputMode": "manual",
        "cardDetails": ["cardholderName": "Test", "cardNumber": "1234", "expiryDate": "1228", "cardType": "visa"]
      ]
    ))
    XCTAssertEqual(failures, 1)
  }

  func test_localHTMLLoadsWithReadAccessToContainingDirectory() throws {
    let url = URL(fileURLWithPath: "/demo/resources/creditcard-tokenizer-example.html")
    let sut = makeSUT(webView: webView, url: url)
    sut.viewWillAppear(false)
    let load = try XCTUnwrap(webView.invokedLoadFileURLs.last)
    XCTAssertEqual(load.url, url)
    XCTAssertEqual(load.readAccessURL, url.deletingLastPathComponent())
    XCTAssertTrue(webView.invokedLoadWithRequestList.isEmpty)
  }

  func test_initialize_injectsScriptAndAddsMessageHandlers() {
    let sut = makeSUT(webView: webView)
    // Simulate navigation finished to trigger initialize()
    sut.webView(sut.webView!, didFinish: mockNavigation)
    // Should add user script and evaluate JS
    XCTAssertFalse(webView.invokedEvaluateJavaScriptParametersList.isEmpty)
  }

  func test_defaultConfigurationHasVisibleFormAndForwardsLoadingFailureInWebView() {
    let failed = expectation(description: "Payment-page loading callback")
    let config = CreditcardTokenizerConfig(
      iframeConfig: IframeConfig(iframeWrapperId: "payment-IFrame"),
      uiConfig: nil,
      locale: "de_DE",
      token: "synthetic-test-token",
      mode: "test",
      allowedCardSchemes: nil,
      customTextConfig: nil,
      submitButtonConfig: SubmitButtonConfig(selector: "#submit"),
      tokenizationFailureCallback: { statusCode, response in
        XCTAssertEqual(statusCode, 422, "Unexpected WebKit result: \(response)")
        XCTAssertEqual(response["error"] as? String, "PaymentPageLoadingFailed")
        failed.fulfill()
      }
    )
    let browser = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    let sut = makeSUT(webView: browser, config: config)
    browser.navigationDelegate = sut
    // Execute our actual injected script in WebKit, without contacting PAYONE.
    // The stub enforces the hosted SDK's non-null CTPConfig requirement.
    browser.loadHTMLString("""
      <html><head><script>
      window.HostedTokenizationSdk = {
        init: function() { return Promise.resolve(); },
        getPaymentPage: function(config, callback) {
          if (!config.CTPConfig || typeof config.CTPConfig !== 'object') {
            throw new Error('CTPConfig must be an object');
          }
          var frame = document.createElement('iframe');
          frame.style.height = (config.iframe.height || 0) + 'px';
          frame.style.border = 'none';
          document.getElementById('payment-IFrame').appendChild(frame);
          if (frame.getBoundingClientRect().height !== 400) {
            window.webkit.messageHandlers.responseReceived.postMessage({
              statusCode: 499,
              errorResponse: {height: frame.getBoundingClientRect().height, configuredHeight: config.iframe.height}
            });
            return;
          }
          callback('Simulated payment-page failure', 422);
        }
      };
      document.head.appendChild = function(script) { script.onload(); return script; };
      </script></head><body><div id="payment-IFrame"></div></body></html>
      """, baseURL: nil)
    wait(for: [failed], timeout: 5)
    withExtendedLifetime(sut) {}
  }

  func test_navigationDelegate_callsInitializeOnDidFinishNavigation() {
    let sut = makeSUT(webView: webView)
    sut.webView(sut.webView!, didFinish: mockNavigation)
    XCTAssertFalse(webView.invokedEvaluateJavaScriptParametersList.isEmpty)
  }

  func test_diagnosticsFollowSDKCallsWithoutExposingTokenOrCardInput() {
    let completed = expectation(description: "Tokenization diagnostic response")
    let browser = WKWebView()
    let sut = makeSUT(webView: browser)
    var events: [(String, [String: Any])] = []
    sut.onDiagnosticEvent = { name, details in
      events.append((name, details))
      if name == "Response · submitForm" { completed.fulfill() }
    }
    browser.navigationDelegate = sut
    browser.loadHTMLString("""
      <html><head><script>
      window.HostedTokenizationSdk = {
        init: function() { return Promise.resolve(); },
        getPaymentPage: function(config, callback) {
          callback('Loaded', 200);
          setTimeout(function() { document.getElementById('submit').click(); }, 0);
        },
        submitForm: function(success, failure) {
          success(201, 'secret-result-token', {
            cardholderName: 'Private Name', cardNumber: '4111111111111111',
            expiryDate: '12/28', cardType: 'visa'
          }, 'manual');
        }
      };
      document.head.appendChild = function(script) { script.onload(); return script; };
      </script></head><body><button id="submit">Submit</button></body></html>
      """, baseURL: nil)
    wait(for: [completed], timeout: 5)
    XCTAssertEqual(events.map(\.0), [
      "Request · loadScript", "Response · loadScript", "Request · init", "Response · init",
      "Request · getPaymentPage", "Response · getPaymentPage", "Request · submitForm", "Response · submitForm"
    ])
    XCTAssertEqual(events.last?.1["statusCode"] as? Int, 201)
    XCTAssertEqual(events.last?.1["tokenReturned"] as? Bool, true)
    let output = String(describing: events)
    for secret in ["test-token", "secret-result-token", "Private Name", "4111111111111111", "12/28"] {
      XCTAssertFalse(output.contains(secret))
    }
    withExtendedLifetime(sut) {}
  }

  func test_diagnosticBridgeDiscardsUnexpectedPayloadFields() {
    var details: [String: Any] = [:]
    sut.onDiagnosticEvent = { _, value in details = value }
    sut.userContentController(WKUserContentController(), didReceive: MockWKScriptMessage(
      name: "tokenizerDiagnostic",
      body: ["operation": "submitForm", "direction": "Response", "details": [
        "statusCode": 400, "token": "secret", "cardNumber": "4111111111111111", "cvv": "123",
        "errorResponse": ["private": "data"]
      ]]
    ))
    XCTAssertEqual(details.count, 1)
    XCTAssertEqual(details["statusCode"] as? Int, 400)
  }

  func test_sensitiveDiagnosticsIncludeActualRequestAndResponsePayloadsWhenEnabled() {
    for transport in ["fetch", "xhr"] {
      assertSensitiveDiagnostics(transport: transport)
    }
  }

  private func assertSensitiveDiagnostics(transport: String) {
    let requests = expectation(description: "HTTP request")
    let responses = expectation(description: "HTTP response")
    let browser = WKWebView()
    let sut = makeSUT(webView: browser)
    sut.includeSensitiveDiagnosticData = true
    var request: [String: Any] = [:]
    var response: [String: Any] = [:]
    sut.onDiagnosticEvent = { name, details in
      if name == "Request · HTTP" { request = details; requests.fulfill() }
      if name == "Response · HTTP" { response = details; responses.fulfill() }
    }
    let content = browser.configuration.userContentController
    content.add(sut, name: "tokenizerDiagnostic")
    defer { content.removeScriptMessageHandler(forName: "tokenizerDiagnostic") }
    content.addUserScript(WKUserScript(source: """
      window.fetch = function() {
        return Promise.resolve(new Response(JSON.stringify({token: 'result-token'}), {status: 201}));
      };
      window.XMLHttpRequest = class extends EventTarget {
        open() {}
        setRequestHeader() {}
        send(payload) {
          this.status = 201;
          this.responseType = '';
          this.responseText = JSON.stringify({token: 'result-token'});
          this.dispatchEvent(new Event('loadend'));
        }
      };
      """, injectionTime: .atDocumentStart, forMainFrameOnly: false))
    content.addUserScript(WKUserScript(
      source: CreditcardTokenizerDiagnosticScript.source, injectionTime: .atDocumentStart, forMainFrameOnly: false
    ))
    browser.loadHTMLString("""
      <html><body><script>
      const url = 'https://api.prelive.pay1-test.de/tokens';
      const options = {
        method: 'POST', headers: {Authorization: 'Bearer test-credential', 'Content-Type': 'application/json'},
        body: JSON.stringify({cardNumber: '4111111111111111', cvv: '123', expiryDate: '1228'})
      };
      if ('\(transport)' === 'fetch') {
        fetch(url, options);
      } else {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', url);
        for (const [key, value] of Object.entries(options.headers)) xhr.setRequestHeader(key, value);
        xhr.send(options.body);
      }
      </script></body></html>
      """, baseURL: URL(string: "https://iframe.preprod.tokenization.secure.payone.com"))
    wait(for: [requests, responses], timeout: 5)
    XCTAssertEqual(request["method"] as? String, "POST")
    XCTAssertEqual((request["headers"] as? [String: String])?["authorization"], "Bearer test-credential")
    XCTAssertEqual((request["body"] as? [String: String])?["cardNumber"], "4111111111111111")
    XCTAssertEqual((request["body"] as? [String: String])?["cvv"], "123")
    XCTAssertEqual((response["body"] as? [String: String])?["token"], "result-token")
    XCTAssertEqual(response["statusCode"] as? Int, 201)
    XCTAssertEqual(request["id"] as? String, response["id"] as? String)
  }

  func test_sensitiveDiagnosticPayloadsAreDisabledByDefault() {
    XCTAssertFalse(sut.includeSensitiveDiagnosticData)
    var called = false
    sut.onDiagnosticEvent = { _, _ in called = true }
    sut.userContentController(WKUserContentController(), didReceive: MockWKScriptMessage(
      name: "tokenizerDiagnostic",
      body: ["operation": "HTTP", "direction": "Request", "details": ["body": ["cvv": "123"]]]
    ))
    XCTAssertFalse(called)
    sut.viewWillAppear(false)
    XCTAssertFalse(webView.configuration.userContentController.userScripts.contains {
      $0.source == CreditcardTokenizerDiagnosticScript.source
    })
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
    XCTAssertTrue(script.contains("\"showCardholderName\":false"), "Expected a JSON Boolean in the encoded configuration")
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
