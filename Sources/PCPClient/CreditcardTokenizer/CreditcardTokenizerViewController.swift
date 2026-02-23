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

  internal var webView: WKWebView?

  /**
   - Parameters:
     - tokenizerUrl: The URL where the HTML for the creditcard tokenizer is hosted.
       The script will be injected and the logic will run in this page.
     - config: The configuration object containing all options for the tokenizer,
       including mode, UI, and callbacks.
   */
  @objc public init(
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig
  ) {
    self.tokenizerUrl = tokenizerUrl
    self.config = config
    super.init(nibName: nil, bundle: nil)
  }

  internal convenience init(
    webView: WKWebView,
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig
  ) {
    self.init(
      tokenizerUrl: tokenizerUrl,
      config: config
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
    let webView = self.webView ?? WKWebView(frame: CGRect.zero)
    webView.navigationDelegate = self
    self.webView = webView
    view.addSubview(webView)

    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    if #available(iOS 16.4, *) {
      webView.isInspectable = true
    } else {
      // Fallback on earlier versions
    }

    let request = URLRequest(url: tokenizerUrl)
    webView.load(request)
  }

  private func initialize() {
    let script = makeScriptToLoadPayoneHostedScript()
    let userScript = WKUserScript(
      source: script,
      injectionTime: .atDocumentEnd,
      forMainFrameOnly: true
    )
    addScriptMessageHandler(key: CCScriptMessageType.scriptError.rawValue)
    addScriptMessageHandler(key: CCScriptMessageType.responseReceived.rawValue)
    webView?.configuration.userContentController.addUserScript(userScript)
    webView?.evaluateJavaScript(script)
  }

  private func makeScriptToLoadPayoneHostedScript() -> String {
    let env = config.mode ?? "test"
    let sdkScriptEnv: [String: [String: String]] = [
      "test": [
        "src":
          "https://sdk.preprod.tokenization.secure.payone.com/1.4.0/hosted-tokenization-sdk.js",
        "integrity": "sha384-gLgHigakYvqqMAmx6FuAl2EaUoWvG24i0xCyDH8YC7+mWpqgFjuzPM0xD3orrMZ4"
      ],
      "live": [
        "src": "https://sdk.tokenization.secure.payone.com/1.4.0/hosted-tokenization-sdk.js",
        "integrity": "sha384-gLgHigakYvqqMAmx6FuAl2EaUoWvG24i0xCyDH8YC7+mWpqgFjuzPM0xD3orrMZ4"
      ]
    ]
    let scriptInfo = sdkScriptEnv[env] ?? sdkScriptEnv["test"] ?? [:]
    let scriptSrc = scriptInfo["src"] ?? ""
    let scriptIntegrity = scriptInfo["integrity"] ?? ""

    let encoder = JSONEncoder()
    let uiConfigJson =
      (try? encoder.encode(config.uiConfig)).flatMap { String(data: $0, encoding: .utf8) }
      ?? "{}"

    // Build iframe config with defaults matching Android implementation
    let defaultWidth = 400
    let defaultZIndex = 9999
    let iframeConfigDict: [String: Any] = [
      "iframeWrapperId": config.iframeConfig.iframeWrapperId,
      "height": config.iframeConfig.height ?? "auto",
      "width": config.iframeConfig.width ?? defaultWidth,
      "zIndex": config.iframeConfig.zIndex ?? defaultZIndex
    ]
    let iframeConfigJson = (try? JSONSerialization.data(withJSONObject: iframeConfigDict))
      .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

    let customTextConfigJson =
      (try? encoder.encode(config.customTextConfig)).flatMap { String(data: $0, encoding: .utf8) }
      ?? "null"

    let allowedCardSchemesJson =
      (try? JSONSerialization.data(withJSONObject: config.allowedCardSchemes ?? []))
      .flatMap { String(data: $0, encoding: .utf8) } ?? "null"

    let customIconsConfigJson =
      (try? encoder.encode(config.customIconsConfig)).flatMap { String(data: $0, encoding: .utf8) }
      ?? "null"

    let ctpConfigJson =
      (try? encoder.encode(config.ctpConfig)).flatMap { String(data: $0, encoding: .utf8) }
      ?? "null"

    let locale = config.locale ?? "de_DE"
    let token = config.token
    let mode = config.mode ?? "test"
    let submitButtonSelector = config.submitButtonConfig.selector ?? "#submit"
    let emailJson = config.email.map { "\"\($0)\"" } ?? "null"
    let showCardholderName = config.showCardholderName ? "true" : "false"

    return """
      if (!document.getElementById('hosted-tokenization-sdk')) {
          var script = document.createElement('script');
          script.type = 'text/javascript';
          script.src = '\(scriptSrc)';
          script.id = 'hosted-tokenization-sdk';
          script.setAttribute('integrity', '\(scriptIntegrity)');
          script.setAttribute('crossorigin', 'anonymous');
          script.onload = function() {
                var sdkConfig = {
                        iframe: \(iframeConfigJson),
                        uiConfig: \(uiConfigJson),
                        locale: '\(locale)',
                        token: '\(token)',
                        mode: '\(mode)',
                        allowedCardSchemes: \(allowedCardSchemesJson),
                        customTextConfig: \(customTextConfigJson),
                        email: \(emailJson),
                        showCardholderName: \(showCardholderName),
                        customIconsConfig: \(customIconsConfigJson),
                        CTPConfig: \(ctpConfigJson)
                      };
                      if (window.HostedTokenizationSdk) {
                        window.HostedTokenizationSdk.init().then(function() {
                          window.HostedTokenizationSdk.getPaymentPage(sdkConfig);
                          var submitBtn = document.querySelector('\(submitButtonSelector)');
                          if (submitBtn) {
                            submitBtn.onclick = function() {
                              window.HostedTokenizationSdk.submitForm(
                                function(statusCode, token, cardDetails, inputMode) {
                                    window.webkit.messageHandlers.responseReceived.postMessage({
                                      statusCode,
                                      token,
                                      cardDetails,
                                      inputMode
                                    });
                                },
                                function(statusCode, errorResponse) {
                                    window.webkit.messageHandlers.responseReceived
                                      .postMessage({statusCode, errorResponse});
                                }
                              );
                            };
                          }
                        }).catch(function(error) {
                         console.error(error);
                         window.webkit.messageHandlers.scriptError.postMessage({
                           statusCode: 500,
                           error: 'LoadingScriptFailed'
                         });
                        });
                      }
          };
          script.onerror = function(e) {
            console.error(e);
            window.webkit.messageHandlers.scriptError.postMessage({
              statusCode: 500,
              error: 'LoadingScriptFailed'
            });
          };
          document.head.appendChild(script);
      }
      null
      """
  }
}

extension CreditcardTokenizerViewController: WKNavigationDelegate, WKScriptMessageHandler {
  private enum ErrorCode {
    static let loadingScriptFailed = 500
  }
  // swiftlint:disable implicitly_unwrapped_optional
  public func webView(_: WKWebView, didFinish _: WKNavigation!) {
    initialize()
  }
  // swiftlint:enable implicitly_unwrapped_optional

  public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage)
  {
    switch message.name {
    case CCScriptMessageType.scriptError.rawValue:
      PCPLogger.error("Loading Hosted Tokenization SDK failed.")
      config.tokenizationFailureCallback?(
        ErrorCode.loadingScriptFailed,
        ["error": "LoadingScriptFailed"]
      )
    case CCScriptMessageType.responseReceived.rawValue:
      if let dict = message.body as? [String: Any] {
        if let statusCode = dict["statusCode"] as? Int, let token = dict["token"] as? String,
          let cardDetailsDict = dict["cardDetails"] as? [String: Any],
          let cardDetails = CardDetails(from: cardDetailsDict),
          let inputMode = dict["inputMode"] as? String
        {
          config.tokenizationSuccessCallback?(statusCode, token, cardDetails, inputMode)
        } else if let statusCode = dict["statusCode"] as? Int,
          let errorResponse = dict["errorResponse"] as? [String: Any]
        {
          config.tokenizationFailureCallback?(statusCode, errorResponse)
        } else {
          config.tokenizationFailureCallback?(
            ErrorCode.loadingScriptFailed,
            ["error": "InvalidResponse"]
          )
        }
      } else {
        config.tokenizationFailureCallback?(
          ErrorCode.loadingScriptFailed,
          ["error": "InvalidResponse"]
        )
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
