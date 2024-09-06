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
    private let supportedCardTypes: [String]
    private let config: CreditcardTokenizerConfig
    private let request: CCTokenizerRequest

    internal var webView: WKWebView?

    /// - Parameters:
    ///   - tokenizerUrl: The URL where the HTML for the creditcard tokenizer is hosted.
    ///   In this page the script will be injected and the logic will run.
    ///   - request: The request object with different IDs and keys.
    ///   - supportedCardTypes: The supported card types to pay. Use the `SupportedCardType` identifier property.
    ///   - config: The config object with information regarding the HTML and styling.
    ///   Also includes the callback that you can use on to get the result.
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

    internal convenience init(
        webView: WKWebView,
        tokenizerUrl: URL,
        request: CCTokenizerRequest,
        supportedCardTypes: [String],
        config: CreditcardTokenizerConfig
    ) {
        self.init(
            tokenizerUrl: tokenizerUrl,
            request: request,
            supportedCardTypes: supportedCardTypes,
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

        let request = URLRequest(url: tokenizerUrl)
        webView.load(request)
    }

    private func initialize() {
        checkRequiredElements(onCheckResult: { [weak self] isSetUpCorrectly in
            guard let self else {
                PCPLogger.fault("Self already released before completion block was executed.")
                return
            }

            guard isSetUpCorrectly else {
                PCPLogger.error("Not all required elements are available.")
                return
            }

            let script = makeScriptToLoadPayoneHostedScript()
            let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            addScriptMessageHandler(key: CCScriptMessageType.scriptLoaded.rawValue)
            addScriptMessageHandler(key: CCScriptMessageType.scriptError.rawValue)
            webView?.configuration.userContentController.addUserScript(userScript)
            webView?.evaluateJavaScript(script)
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

        if !field.length.isEmpty {
            let lengthString = field.length.map { "\($0.key): \"\($0.value)\"" }.joined(separator: ", ")
            result += ", length: { \(lengthString) }"
        }

        if !field.iframe.isEmpty {
            let iframeString = field.iframe.map { "\($0.key): \"\($0.value)\"" }.joined(separator: ", ")
            result += ", iframe: { \(iframeString) }"
        }

        return "{ \(result) }"
    }

    private func generateDefaultStyleKeyValuePairs() -> String {
        config.defaultStyles.map { "\($0.key): \"\($0.value)\"" }.joined(separator: ",\n")
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

        checkIfElementExists(elementId: config.submitButtonId) { isSubmitButtonAvailable in
            hasSubmitButton = isSubmitButtonAvailable
            onCheckResult(hasSubmitButton)
        }
    }

    private func checkIfElementExists(elementId: String, onCheckResult: @escaping (Bool) -> Void) {
        let script = "document.querySelector('#\(elementId)') !== null"
        guard let webView else {
            onCheckResult(false)
            return
        }
        webView.evaluateJavaScript(script) { result, _ in
            if let exists = result as? Bool {
                onCheckResult(exists)
            } else {
                onCheckResult(false)
            }
        }
    }
}

extension CreditcardTokenizerViewController: WKNavigationDelegate, WKScriptMessageHandler {
    // swiftlint:disable implicitly_unwrapped_optional
    public func webView(_: WKWebView, didFinish _: WKNavigation!) {
        initialize()
    }
    // swiftlint:enable implicitly_unwrapped_optional

    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case CCScriptMessageType.scriptLoaded.rawValue:
            webView?.evaluateJavaScript(
                self.makeScriptToPopulateHTML(),
                completionHandler: { [weak self] _, error in
                    if let error {
                        PCPLogger.error("Populating HTML with inputs failed with \(error.localizedDescription).")
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
