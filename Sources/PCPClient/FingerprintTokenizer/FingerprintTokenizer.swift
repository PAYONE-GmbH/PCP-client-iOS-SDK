//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import WebKit

/// Responsible for generating a fingerprint token which is required to let your server perform transactions.
///
/// The `FingerprintTokenizer` sends this snippet token to Payla for later server-to-Payla authorization,
/// ensuring the necessary device information is captured to facilitate secure and accurate payment processing.
public final class FingerprintTokenizer: NSObject {
    private let paylaPartnerId: String
    private let partnerMerchantId: String
    private let environment: PCPEnvironment
    private let snippetToken: String

    private var webView: WKWebView?
    private var onCompletion: ((Result<String, FingerprintError>) -> Void)?

    /// Initializes the `FingerprintTokenizer`.
    /// - Parameters:
    ///   - paylaPartnerId: The Payla partner ID.
    ///   - partnerMerchantId: Your partner merchant ID.
    ///   - environment: The `PCPEnvironment` you want to use. Either `test` or `production`.
    ///   - sessionId: An optional session ID that you want created on your own.`
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
    
    /// Attempts to get the snippet token, could fail during the process.
    /// - Parameter onCompletion: Handle the completion of either a `String` token or error.
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
                window.paylaDcs.init('\(environment.fingerprintTokenizerIdentifier)', '\(snippetToken)');
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
    // swiftlint:disable implicitly_unwrapped_optional
    /// Method from `WKNavigationDelegate`. Do not call this method manually!
    public func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        // swiftlint:enable implicitly_unwrapped_optional
        let invokeInitFunction = #"paylaDcs.init("p", "pcp_init");"#
        webView.evaluateJavaScript(invokeInitFunction) { [weak self] _, error in
            if let error {
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
