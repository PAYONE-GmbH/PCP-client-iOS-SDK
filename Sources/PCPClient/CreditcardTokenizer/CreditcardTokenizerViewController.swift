//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import UIKit
import WebKit

@objc public class CreditcardTokenizerViewController: UIViewController {
    private let tokenizerUrl: URL
    private let supportedCardTypes: [String]
    private let config: CreditcardTokenizerConfig
    private let request: CCTokenizerRequest

    var webView: WKWebView?

    @objc public init(
        tokenizerUrl: URL,
        request: CCTokenizerRequest,
        supportedCardTypes: [String],
        config: CreditcardTokenizerConfig
    ) {
        self.tokenizerUrl = tokenizerUrl
        self.supportedCardTypes = supportedCardTypes
        self.request = request
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("\(#function ) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupWebView()
    }

    private func setupWebView() {
        let webView = makeInjectedWebView()
        self.webView = webView
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let request = URLRequest(url: tokenizerUrl)
        webView.load(request)
    }

    private func makeInjectedWebView() -> WKWebView {
        let webView = WKWebView(frame: CGRect.zero)
        webView.navigationDelegate = self
        return webView
    }

    private func initialize() {
        checkRequiredElements(onCheckResult: { [weak self] isSetUpCorrectly in
            guard let self else {
                return
            }
            let js = makeScriptToLoadPayoneHostedScript()
            let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            self.addScriptMessageHandler(key: CCScriptMessageType.scriptLoaded.rawValue)
            self.addScriptMessageHandler(key: CCScriptMessageType.scriptError.rawValue)
            self.webView?.configuration.userContentController.addUserScript(script)
            self.webView?.evaluateJavaScript(js)
        })
    }

    private func generateKeyValuePairs(from field: Field) -> String {
        var result = "selector: \"\(field.selector)\", type: \"\(field.type)\""

        if let style = field.style {
            result += ", style: \"\(style)\""
        }

        if let size = field.size {
            result += ", size: \"\(size)\""
        }

        if let maxlength = field.maxlength {
            result += ", maxlength: \"\(maxlength)\""
        }

        if let length = field.length {
            let lengthString = length.map { "\($0.key): \"\($0.value)\"" }.joined(separator: ", ")
            result += ", length: { \(lengthString) }"
        }

        if let iframe = field.iframe {
            let iframeString = iframe.map { "\($0.key): \"\($0.value)\"" }.joined(separator: ", ")
            result += ", iframe: { \(iframeString) }"
        }

        return "{ \(result) }"
    }

    private func generateDefaultStyleKeyValuePairs() -> String {
        config.defaultStyles.map { "\($0.key): \"\($0.value)\""}.joined(separator: ",\n")
    }

    private func makeScriptToLoadPayoneHostedScript() -> String {
        """
        if (!document.getElementById('payone-hosted-script')) {
            const script = document.createElement('script');
            script.type = 'text/javascript';
            script.src = 'https://secure.prelive.pay1-test.de/client-api/js/v1/payone_hosted_min.js';
            script.id = 'payone-hosted-script';
            script.onload = function() {
                \(CCScriptMessageType.responseReceived.makeWebkitMessageString(body: "Script loaded."))
            }
            script.onerror = function() {
                \(CCScriptMessageType.responseReceived.makeWebkitMessageString(body: "Failed to load Payone script."))
            }
            document.head.appendChild(script);
        }
        null
        """
    }

    private func makeScriptToPopulateHTML() -> String {
        """
        var supportedCardtypes = \(supportedCardTypes.map { "\($0)" })
        var config = {
            fields: {
                cardpan: \(generateKeyValuePairs(from: config.cardPan)),
                cardcvc2: \(generateKeyValuePairs(from: config.cardCvc2)),
                cardexpiremonth: \(generateKeyValuePairs(from: config.cardExpireMonth)),
                cardexpireyear: \(generateKeyValuePairs(from: config.cardExpireYear))
            },
            defaultStyle: {
                \(generateDefaultStyleKeyValuePairs())
            },
            autoCardtypeDetection: {
                supportedCardtypes: supportedCardtypes,
                callback: function(detectedCardtype) {
                    // For the output container below.
                    document.getElementById('autodetectionResponsePre').innerHTML = detectedCardtype;

                    if (detectedCardtype === 'V') {
                        document.getElementById('visa').style.borderColor = '#00F';
                        document.getElementById('mastercard').style.borderColor = '#FFF';
                    } else if (detectedCardtype === 'M') {
                        document.getElementById('visa').style.borderColor = '#FFF';
                        document.getElementById('mastercard').style.borderColor = '#00F';
                    } else {
                        document.getElementById('visa').style.borderColor = '#FFF';
                        document.getElementById('mastercard').style.borderColor = '#FFF';
                    }
                } //,
                // deactivate: true // To turn off automatic card type detection.
            },
            language: \(config.language.configValue),
            error: "\(config.error)"
        };
        var request = {
            request: 'creditcardcheck',
            responsetype: 'JSON',
            mode: '\(request.environment.ccTokenizerIdentifier)',
            mid: '\(request.mid)',
            aid: '\(request.aid)',
            portalid: '\(request.portalId)',
            encoding: 'UTF-8',
            storecarddata: 'yes',
            hash: '\(request.generatedHash)'
        };
        document.getElementById('\(config.submitButtonId)').onclick = function() {
            \(CCScriptMessageType.responseReceived.makeWebkitMessageString(body: ""))
        };

        var iframes = new window.Payone.ClientApi.HostedIFrames(config, request);
        window.payoneIFrames = iframes;
        ;null
       """
    }

    private func makeScriptToInitiateAndHandleCheck() -> String {
        """
       var iframes = window.payoneIFrames;

       function payCallback(response) {
           \(CCScriptMessageType.responseReceived.makeWebkitMessageString(body: "response"))
       }

       iframes.creditCardCheck('payCallback');
       """
    }

    private func checkRequiredElements(onCheckResult: @escaping (Bool) -> Void) {
        var hasSubmitButton: Bool = true

        checkIfElementExists(elementId: config.submitButtonId) {
            hasSubmitButton = $0
            onCheckResult(hasSubmitButton)
        }
    }

    private func checkIfElementExists(elementId: String, onCheckResult: @escaping (Bool) -> Void) {
        let script = "document.querySelector('#\(elementId)') !== null"
        guard let webView else {
            onCheckResult(false)
            return
        }
        webView.evaluateJavaScript(script) { (result, error) in
            if let exists = result as? Bool {
                onCheckResult(exists)
            } else {
                onCheckResult(false)
            }
        }
    }
}

extension CreditcardTokenizerViewController: WKNavigationDelegate, WKScriptMessageHandler {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        initialize()
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case CCScriptMessageType.scriptLoaded.rawValue:
            webView?.evaluateJavaScript(
                self.makeScriptToPopulateHTML(),
                completionHandler: { [weak self] _, error in
                    if let error {
                        PCPLogger.error("Populating HTML with inputs failed.")
                        self?.config.creditCardCheckCallback(.failure(.populatingHTMLFailed))
                    }
                }
            )
            addScriptMessageHandler(key: CCScriptMessageType.submitButtonClicked.rawValue)
        case CCScriptMessageType.scriptError.rawValue:
            PCPLogger.error("Loading Payone Script failed.")
            config.creditCardCheckCallback(.failure(.loadingScriptFailed))
        case CCScriptMessageType.submitButtonClicked.rawValue:
            webView?.evaluateJavaScript(makeScriptToInitiateAndHandleCheck())
            addScriptMessageHandler(key: CCScriptMessageType.responseReceived.rawValue)
        case CCScriptMessageType.responseReceived.rawValue:
            guard let dictionary = message.body as? [String: String?],
                  let data = try? JSONEncoder().encode(dictionary),
                  let response = try? JSONDecoder().decode(CCTokenizerResponse.self, from: data) else {
                PCPLogger.error("Invalid response received.")
                config.creditCardCheckCallback(.failure(.invalidResponse))
                return
            }
            config.creditCardCheckCallback(.success(response))
        default:
            PCPLogger.warning("Unknown message send from WebView \(message.name).")
        }
    }

    private func addScriptMessageHandler(key: String) {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: key)
        webView?.configuration.userContentController.add(self, name: key)
    }
}
