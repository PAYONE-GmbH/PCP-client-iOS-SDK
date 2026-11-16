//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import UIKit
import WebKit

/// Hosts the tokenizer page in WebKit. Configure and present on the main thread.
/// To replace an expired token, create a new controller with a new immutable configuration.
@objc public class CreditcardTokenizerViewController: UIViewController {
    private let tokenizerUrl: URL
    private let config: CreditcardTokenizerConfig
    private let messageHandler = CreditcardTokenizerMessageHandler()
    private var prepared = false
    private static let errorStatus = 500
    private static let successStatuses = 200..<300
    internal var webView: WKWebView?

    /// HTTPS origin under merchant control for bundled HTML. Set before presentation.
    @objc public var localHTMLBaseURL: URL?
    /// Optional in-memory diagnostics; metadata only unless the explicit sensitive option is enabled.
    @objc public var onDiagnosticEvent: ((String, [String: Any]) -> Void)?
    /// Includes tokens, submitted card data and hosted-frame HTTP payloads. Off by default.
    /// Set before presentation; intended for example/debug integrations only.
    @objc public var includeSensitiveDiagnosticData = false

    /// - Parameters:
    ///   - tokenizerUrl: Hosted page URL or bundled HTML file URL containing the configured form and submit button.
    ///   - config: Immutable Hosted SDK configuration, including a current merchant authorization token.
    @objc public init(tokenizerUrl: URL, config: CreditcardTokenizerConfig) {
        self.tokenizerUrl = tokenizerUrl
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    internal convenience init(webView: WKWebView, tokenizerUrl: URL, config: CreditcardTokenizerConfig) {
        self.init(tokenizerUrl: tokenizerUrl, config: config)
        self.webView = webView
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) { fatalError("init(coder:) is unavailable") }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !prepared else {
            return
        }
        prepared = true
        let browser = webView ?? WKWebView(frame: .zero)
        webView = browser
        browser.navigationDelegate = self
        registerHandlers()
        if includeSensitiveDiagnosticData {
            browser.configuration.userContentController.addUserScript(WKUserScript(
                source: CreditcardTokenizerDiagnosticScript.source,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            ))
        }
        view.addSubview(browser)
        browser.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browser.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browser.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            browser.topAnchor.constraint(equalTo: view.topAnchor),
            browser.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        if #available(iOS 16.4, *) { browser.isInspectable = true }
        loadPage(in: browser)
    }

    private func loadPage(in browser: WKWebView) {
        guard tokenizerUrl.isFileURL else {
            browser.load(URLRequest(url: tokenizerUrl))
            return
        }
        guard let localHTMLBaseURL else {
            browser.loadFileURL(tokenizerUrl, allowingReadAccessTo: tokenizerUrl.deletingLastPathComponent())
            return
        }
        guard localHTMLBaseURL.scheme == "https", localHTMLBaseURL.host?.isEmpty == false,
              let html = try? String(contentsOf: tokenizerUrl, encoding: .utf8) else {
            fail("LocalHTMLLoadingFailed")
            return
        }
        browser.loadHTMLString(html, baseURL: localHTMLBaseURL)
    }

    private func registerHandlers() {
        messageHandler.receiver = self
        for name in CreditcardTokenizerMessageHandler.names {
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: name)
            webView?.configuration.userContentController.add(messageHandler, name: name)
        }
    }

    private func fail(_ error: String) {
        config.tokenizationFailureCallback?(Self.errorStatus, ["error": error])
    }
}

extension CreditcardTokenizerViewController: WKNavigationDelegate, WKScriptMessageHandler {
    public func webView(_ webView: WKWebView, didFinish _: WKNavigation?) {
        registerHandlers()
        do {
            let script = try CreditcardTokenizerScriptBuilder.make(
                config: config, sensitive: includeSensitiveDiagnosticData
            )
            webView.evaluateJavaScript(script) { [weak self] _, error in
                if error != nil { self?.fail("InitializationFailed") }
            }
        } catch { fail("InvalidConfiguration") }
    }

    public func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation?, withError _: Error) {
        fail("PageLoadingFailed")
    }

    public func webView(_: WKWebView, didFail _: WKNavigation?, withError _: Error) {
        fail("PageLoadingFailed")
    }

    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "tokenizerDiagnostic":
            if let (name, details) = CreditcardTokenizerMessageHandler.diagnostic(
                message.body, sensitive: includeSensitiveDiagnosticData
            ) { onDiagnosticEvent?(name, details) }
        case "scriptError":
            let error = (message.body as? [String: Any])?["error"] as? String ?? "LoadingScriptFailed"
            fail(error)
        case "responseReceived":
            guard let body = message.body as? [String: Any], let status = body["statusCode"] as? Int else {
                fail("InvalidResponse")
                return
            }
            if Self.successStatuses.contains(status), let token = body["token"] as? String, !token.isEmpty,
               let details = body["cardDetails"] as? [String: Any], let card = CardDetails(from: details),
               let inputMode = body["inputMode"] as? String {
                config.tokenizationSuccessCallback?(status, token, card, inputMode)
            } else if let error = body["errorResponse"] as? [String: Any] {
                config.tokenizationFailureCallback?(status, error)
            } else { fail("InvalidResponse") }
        default:
            break
        }
    }
}
