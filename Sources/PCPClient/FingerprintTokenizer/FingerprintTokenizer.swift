//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import WebKit

public final class FingerprintTokenizer: NSObject {
    private let paylaPartnerId: String
    private let partnerMerchantId: String
    private let environment: PCPEnvironment
    private let snippetToken: String

    private var webView: WKWebView?
    private var onCompletion: ((Result<String, FingerprintError>) -> Void)?

    public init(
        paylaPartnerId: String,
        partnerMerchantId: String,
        environment: PCPEnvironment,
        sessionId: String? = nil
    ) {
        self.paylaPartnerId = paylaPartnerId
        self.partnerMerchantId = partnerMerchantId
        self.environment = environment

        let uniqueId = sessionId ?? UUID().uuidString
        self.snippetToken = "\(paylaPartnerId)_\(partnerMerchantId)_\(uniqueId)"
        super.init()
    }

    public func getSnippetToken(onCompletion: @escaping (Result<String, FingerprintError>) -> Void) {
        self.onCompletion = onCompletion
        let script = makeScript()
        self.webView = makeInjectedWebView(withScript: script)
        webView?.loadHTMLString(makeHTML(), baseURL: nil)
    }

    private func makeHTML() -> String {
        """
        <!doctype html>
        <html lang="en">
          <body></body>
        </html>
        """
    }

    private func makeScript() -> String {
        """
        window.paylaDcs = window.paylaDcs || {};
        var script = document.createElement('script');
        script.id = 'paylaDcs';
        script.type = 'text/javascript';
        script.src = 'https://d.payla.io/dcs/\(paylaPartnerId)/\(partnerMerchantId)/dcs.js';
        script.onload = function() {
            if (typeof window.paylaDcs !== 'undefined' && window.paylaDcs.init) {
                window.paylaDcs.init('\(environment.environmentKey)', '\(snippetToken)');
            }
            else {
                throw new Error('paylaDcs is not defined or does not have an init method.');
            }
        };
        document.body.appendChild(script);
        """
    }

    private func makeInjectedWebView(withScript script: String) -> WKWebView {
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        return webView
    }
}

extension FingerprintTokenizer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let invokeInitFunction = #"paylaDcs.init("p", "pcp_init");"#
        webView.evaluateJavaScript(invokeInitFunction) { [weak self] (result, error) in
            if let error = error {
                PCPLogger.error("Fingerprinting script failed with error: \(error.localizedDescription).")
                self?.onCompletion?(.failure(.scriptError(error: error)))
            } else if let snippetToken = self?.snippetToken {
                PCPLogger.info("Successfully loaded snippet token.")
                self?.onCompletion?(.success(snippetToken))
            } else {
                PCPLogger.error("Fingerprinting script because snippet token was nil.")
                self?.onCompletion?(.failure(.undefined))
            }
        }
    }
}
