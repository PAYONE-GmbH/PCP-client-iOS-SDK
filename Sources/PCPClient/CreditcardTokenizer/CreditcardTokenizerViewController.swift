//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import UIKit
import WebKit

/// The `UIViewController` to set up the creditcard tokenizer.
@objc public class CreditcardTokenizerViewController: UIViewController {
  private let tokenizerUrl: URL
  private let config: CreditcardTokenizerConfig
  private let jwtToken: String

  internal var webView: WKWebView?

  /// - Parameters:
  ///   - tokenizerUrl: The URL where the HTML for the creditcard tokenizer is hosted. The script will be injected and the logic will run in this page.
  ///   - config: The configuration object containing all options for the tokenizer, including environment, UI, and callbacks.
  ///   - jwtToken: The JWT token received from your backend, used for authentication and authorization.
  @objc public init(
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig,
    jwtToken: String
  ) {
    self.tokenizerUrl = tokenizerUrl
    self.config = config
    self.jwtToken = jwtToken
    super.init(nibName: nil, bundle: nil)
  }

  internal convenience init(
    webView: WKWebView,
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig,
    jwtToken: String
  ) {
    self.init(
      tokenizerUrl: tokenizerUrl,
      config: config,
      jwtToken: jwtToken
    )
    self.webView = webView
  }

  @available(*, unavailable)
  public required init?(coder _: NSCoder) {
    fatalError("\(#function ) has not been implemented")
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    setupWebView()
  }
}

extension CreditcardTokenizerViewController {
  private func setupWebView() {
    PCPLogger.info(
      "Setting up CreditcardTokenizerViewController with URL: \(tokenizerUrl.absoluteString)")
    let webView = self.webView ?? WKWebView(frame: CGRect.zero)
    webView.navigationDelegate = self
    self.webView = webView
    view.addSubview(webView)

    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    let request = URLRequest(url: tokenizerUrl)
    webView.load(request)
    PCPLogger.info(
      "Loading CreditcardTokenizerViewController with URL: \(tokenizerUrl.absoluteString)")
  }

  private func initialize() {
    PCPLogger.info("Initializing CreditcardTokenizerViewController.")
    PCPLogger.info("Adding script message handlers.")
    addScriptMessageHandler(key: CCScriptMessageType.scriptLoaded.rawValue)
    addScriptMessageHandler(key: CCScriptMessageType.scriptError.rawValue)
    PCPLogger.info("CreditcardTokenizerViewController initialized successfully.")
  }

  private func makeScriptToLoadPayoneHostedScript() -> String {
    PCPLogger.info("Creating script to load Payone Hosted Tokenization SDK.")
    let env = config.environment ?? "test"
    let sdkScriptEnv: [String: [String: String]] = [
      "test": [
        "src":
          "https://sdk.preprod.tokenization.secure.payone.com/1.0.1/hosted-tokenization-sdk.js",
        "integrity": "sha384-Ec6OPQvn8poHUzTwcUYWC/pwd5wgVuVB+jKl+Eml5MWou154pm6j2MdhhJb9uqML",
      ],
      "live": [
        "src": "https://sdk.tokenization.secure.payone.com/1.0.1/hosted-tokenization-sdk.js",
        "integrity": "sha384-Ec6OPQvn8poHUzTwcUYWC/pwd5wgVuVB+jKl+Eml5MWou154pm6j2MdhhJb9uqML",
      ],
    ]
    let scriptInfo = sdkScriptEnv[env] ?? sdkScriptEnv["test"]!
    let scriptSrc = scriptInfo["src"]!
    let scriptIntegrity = scriptInfo["integrity"]!
    PCPLogger.info(
      "Using script source: \(scriptSrc) with integrity: \(scriptIntegrity) for environment: \(env)"
    )
    return """
      (function() {
          try {
              console.log('[PayoneSDK] Attempting to inject script:', '\(scriptSrc)');
              if (!document.getElementById('hosted-tokenization-sdk')) {
                  console.log('[PayoneSDK] Script not found, injecting new script.');
                  var script = document.createElement('script');
                  script.type = 'text/javascript';
                  script.src = '\(scriptSrc)';
                  script.id = 'hosted-tokenization-sdk';
                  script.setAttribute('integrity', '\(scriptIntegrity)');
                  script.setAttribute('crossorigin', 'anonymous');
                  script.onload = function() {
                      console.log('[PayoneSDK] Script loaded successfully:', script.src);
                      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.CCScriptMessageType && window.webkit.messageHandlers.CCScriptMessageType.scriptLoaded) {
                          window.webkit.messageHandlers.CCScriptMessageType.scriptLoaded.postMessage('');
                      }
                  };
                  script.onerror = function(e) {
                      console.error('[PayoneSDK] Error loading script:', script.src, e);
                      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.CCScriptMessageType && window.webkit.messageHandlers.CCScriptMessageType.scriptError) {
                          window.webkit.messageHandlers.CCScriptMessageType.scriptError.postMessage('');
                      }
                  };
                  document.head.appendChild(script);
                  console.log('[PayoneSDK] Script appended to head:', script.src);
              } else {
                  console.log('[PayoneSDK] Script already present, skipping injection.');
              }
          } catch (err) {
              console.error('[PayoneSDK] Exception during script injection:', err);
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.CCScriptMessageType && window.webkit.messageHandlers.CCScriptMessageType.scriptError) {
                  window.webkit.messageHandlers.CCScriptMessageType.scriptError.postMessage('');
              }
          }
      })();
      """
  }

  private func makeScriptToPopulateHTML() -> String {
    PCPLogger.info("Creating script to populate HTML with inputs.")
    let uiConfigJson =
      try? String(data: JSONEncoder().encode(config.uiConfig), encoding: .utf8) ?? "{}"
    let iframeConfigJson =
      try? String(data: JSONEncoder().encode(config.iframeConfig), encoding: .utf8) ?? "{}"
    let locale = config.locale ?? "de_DE"
    let submitButtonSelector = config.submitButtonConfig?.selector ?? "#submit"
    return """
      var sdkConfig = {
        iframe: [iframeConfigJson],
        uiConfig: [uiConfigJson],
        locale: '[locale]',
        token: '[jwtToken]'
      };
      if (window.HostedTokenizationSdk) {
        window.HostedTokenizationSdk.init().then(function() {
          window.HostedTokenizationSdk.getPaymentPage(sdkConfig);
          var submitBtn = document.querySelector('[submitButtonSelector]');
          if (submitBtn) {
            submitBtn.onclick = function() {
              window.HostedTokenizationSdk.submitForm(
                function(statusCode, token, cardDetails) {
                  window.webkit.messageHandlers.CCScriptMessageType.responseReceived.rawValue.postMessage({statusCode: statusCode, token: token, cardDetails: cardDetails});
                },
                function(statusCode, errorResponse) {
                  window.webkit.messageHandlers.CCScriptMessageType.responseReceived.rawValue.postMessage({statusCode: statusCode, errorResponse: errorResponse});
                }
              );
            };
          }
        }).catch(function(error) {
          window.webkit.messageHandlers.CCScriptMessageType.scriptError.rawValue.postMessage('');
        });
      }
      """
  }
}

extension CreditcardTokenizerViewController: WKNavigationDelegate, WKScriptMessageHandler {
  // swiftlint:disable implicitly_unwrapped_optional
  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    PCPLogger.info("WebView did finish loading \(webView.url?.absoluteString ?? "unknown URL").")
    // Inject the script only after the page is fully loaded
    let script = makeScriptToLoadPayoneHostedScript()
    let userScript = WKUserScript(
      source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    webView.configuration.userContentController.addUserScript(userScript)
    PCPLogger.info("Injecting script to load Payone Hosted Tokenization SDK after page load.")
    webView.evaluateJavaScript(script)
    PCPLogger.info("WebView finished loading and initialized successfully.")
  }
  // swiftlint:enable implicitly_unwrapped_optional

  public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage)
  {
    PCPLogger.info("Received message from WebView: \(message.name)")
    switch message.name {
    case CCScriptMessageType.scriptLoaded.rawValue:
      webView?.evaluateJavaScript(
        self.makeScriptToPopulateHTML(),
        completionHandler: { [weak self] _, error in
          if let error {
            PCPLogger.error(
              "Populating HTML with inputs failed with \(error.localizedDescription).")
            self?.config.tokenizationFailureCallback?(500, ["error": "PopulatingHTMLFailed"])
          }
        }
      )
    case CCScriptMessageType.scriptError.rawValue:
      PCPLogger.error("Loading Hosted Tokenization SDK failed.")
      config.tokenizationFailureCallback?(500, ["error": "LoadingScriptFailed"])
    case CCScriptMessageType.responseReceived.rawValue:
      if let dict = message.body as? [String: Any] {
        if let statusCode = dict["statusCode"] as? Int, let token = dict["token"] as? String,
          let cardDetails = dict["cardDetails"] as? [String: Any]
        {
          config.tokenizationSuccessCallback?(statusCode, token, cardDetails)
        } else if let statusCode = dict["statusCode"] as? Int,
          let errorResponse = dict["errorResponse"] as? [String: Any]
        {
          config.tokenizationFailureCallback?(statusCode, errorResponse)
        } else {
          config.tokenizationFailureCallback?(500, ["error": "InvalidResponse"])
        }
      } else {
        config.tokenizationFailureCallback?(500, ["error": "InvalidResponse"])
      }
    default:
      PCPLogger.warning("Unknown message send from WebView \(message.name).")
    }
  }

  private func addScriptMessageHandler(key: String) {
    webView?.configuration.userContentController.removeScriptMessageHandler(forName: key)
    webView?.configuration.userContentController.add(self, name: key)
  }
}
