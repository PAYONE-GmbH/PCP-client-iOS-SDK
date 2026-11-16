//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

/// Encodes configuration as JSON; no merchant-provided strings are interpolated as JavaScript.
internal enum CreditcardTokenizerScriptBuilder {
    private static let defaultHeight = 400.0
    private static let defaultWidth = 400.0
    private static let defaultZIndex = 9999

    internal static func make(config: CreditcardTokenizerConfig, sensitive: Bool) throws -> String {
        let encoder = JSONEncoder()
        func object<T: Encodable>(_ value: T) throws -> Any {
            try JSONSerialization.jsonObject(with: encoder.encode(value))
        }
        let mode = (config.mode ?? "test").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard ["test", "live"].contains(mode) else { throw CocoaError(.coderInvalidValue) }
        let domain = mode == "live"
            ? "sdk.tokenization.secure.payone.com" : "sdk.preprod.tokenization.secure.payone.com"
        let settings: [String: Any] = [
            "src": "https://\(domain)/1.4.0/hosted-tokenization-sdk.js",
            "integrity": "sha384-gLgHigakYvqqMAmx6FuAl2EaUoWvG24i0xCyDH8YC7+mWpqgFjuzPM0xD3orrMZ4",
            "selector": config.submitButtonConfig.selector ?? "#submit",
            "sensitive": sensitive,
            "config": [
                "iframe": [
                    "iframeWrapperId": config.iframeConfig.iframeWrapperId,
                    "height": config.iframeConfig.height ?? defaultHeight,
                    "width": config.iframeConfig.width ?? defaultWidth,
                    "zIndex": config.iframeConfig.zIndex ?? defaultZIndex
                ],
                "token": config.token, "mode": mode, "locale": config.locale ?? "de_DE",
                "allowedCardSchemes": config.allowedCardSchemes ?? [],
                "showCardholderName": config.showCardholderName,
                "email": config.email as Any? ?? NSNull(),
                "uiConfig": try config.uiConfig.map { try object($0) } ?? [:],
                "customTextConfig": try config.customTextConfig.map { try object($0) } ?? [:],
                "customIconsConfig": try config.customIconsConfig.map { try object($0) } ?? [:],
                "CTPConfig": try config.ctpConfig.map { try object($0) } ?? [:]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: settings, options: [.sortedKeys])
        guard let json = String(bytes: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return """
          (function(settings) {
            if (document.getElementById('hosted-tokenization-sdk')) return;
            function diagnose(operation, direction, details) {
              window.webkit.messageHandlers.tokenizerDiagnostic.postMessage({operation, direction, details});
            }
            function fail(error) {
              window.webkit.messageHandlers.scriptError.postMessage({statusCode: 500, error});
            }
            const script = document.createElement('script');
            script.id = 'hosted-tokenization-sdk';
            script.src = settings.src;
            script.integrity = settings.integrity;
            script.crossOrigin = 'anonymous';
            script.onload = function() {
              diagnose('loadScript', 'Response', {result: 'loaded'});
              const sdk = window.HostedTokenizationSdk;
              if (!sdk) { fail('LoadingScriptFailed'); return; }
              const config = settings.config;
              diagnose('init', 'Request', {mode: config.mode, locale: config.locale});
              Promise.resolve().then(() => sdk.init()).then(function() {
                diagnose('init', 'Response', {result: 'ready'});
                diagnose('getPaymentPage', 'Request', {mode: config.mode, locale: config.locale,
                  tokenProvided: !!config.token, ...(settings.sensitive ? {token: config.token} : {})});
                sdk.getPaymentPage(config, function(message, statusCode) {
                  diagnose('getPaymentPage', statusCode < 0 ? 'Info' : 'Response', {statusCode});
                  if (statusCode >= 400 || statusCode === 0) {
                    window.webkit.messageHandlers.responseReceived.postMessage({statusCode: statusCode || 500,
                      errorResponse: {error: 'PaymentPageLoadingFailed'}});
                  }
                });
                const button = document.querySelector(settings.selector);
                if (!button) { fail('SubmitButtonNotFound'); return; }
                button.onclick = function(event) {
                  event.preventDefault();
                  diagnose('submitForm', 'Request', {mode: config.mode, tokenProvided: !!config.token});
                  try {
                    sdk.submitForm(function(statusCode, token, cardDetails, inputMode) {
                      diagnose('submitForm', 'Response', {statusCode, tokenReturned: !!token, inputMode,
                        ...(settings.sensitive ? {token, cardDetails} : {})});
                      window.webkit.messageHandlers.responseReceived
                        .postMessage({statusCode, token, cardDetails, inputMode});
                    }, function(statusCode, errorResponse) {
                      diagnose('submitForm', 'Response', {statusCode, error: 'TokenizationFailed',
                        ...(settings.sensitive ? {errorResponse} : {})});
                      window.webkit.messageHandlers.responseReceived
                        .postMessage({statusCode: statusCode || 500, errorResponse});
                    });
                  } catch (_) { fail('SubmissionFailed'); }
                  return false;
                };
              }).catch(function() { fail('InitializationFailed'); });
            };
            script.onerror = function() {
              diagnose('loadScript', 'Response', {statusCode: 500, error: 'LoadingScriptFailed'});
              fail('LoadingScriptFailed');
            };
            diagnose('loadScript', 'Request', {});
            document.head.appendChild(script);
          })(\(json));
          null
          """
    }
}
