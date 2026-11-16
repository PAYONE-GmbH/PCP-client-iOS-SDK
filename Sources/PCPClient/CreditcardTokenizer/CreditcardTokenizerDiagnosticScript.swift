//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

/// Opt-in inspection of requests made by the hosted payment frame, for examples/debugging.
internal enum CreditcardTokenizerDiagnosticScript {
  internal static let source = """
    (function() {
      const frameHosts = ['iframe.preprod.tokenization.secure.payone.com', 'iframe.tokenization.secure.payone.com'];
      if (!frameHosts.includes(location.hostname) || window.__pcpNetworkDiagnostics) return;
      window.__pcpNetworkDiagnostics = true;
      const apiHosts = ['api.prelive.pay1-test.de', 'api.pay1.de', 'api.hoth.pay1-test.de', 'apigw01.yavin.pay1-test.de'];
      let sequence = 0;
      function target(value) {
        try {
          const url = new URL(value, location.href);
          return url.protocol === 'https:' && apiHosts.includes(url.hostname) ? url.href : null;
        } catch (_) { return null; }
      }
      function body(value) {
        if (typeof value !== 'string') return value == null ? null : String(value);
        try { return JSON.parse(value); } catch (_) { return value; }
      }
      function emit(direction, details) {
        try {
          window.webkit.messageHandlers.tokenizerDiagnostic.postMessage({operation: 'HTTP', direction, details});
        } catch (_) { /* Diagnostics must not interrupt payment requests. */ }
      }
      const open = XMLHttpRequest.prototype.open;
      const setHeader = XMLHttpRequest.prototype.setRequestHeader;
      const send = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function(method, url) {
        this.__pcpRequest = {method, url: target(url), headers: {}};
        return open.apply(this, arguments);
      };
      XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
        if (this.__pcpRequest) this.__pcpRequest.headers[name.toLowerCase()] = value;
        return setHeader.apply(this, arguments);
      };
      XMLHttpRequest.prototype.send = function(payload) {
        const request = this.__pcpRequest;
        if (request?.url) {
          const id = 'xhr-' + (++sequence);
          emit('Request', {...request, id, body: body(payload)});
          this.addEventListener('loadend', function() {
            let response;
            try { response = this.responseType === 'json' ? this.response : body(this.responseText); }
            catch (_) { response = '[non-text response]'; }
            emit('Response', {id, url: request.url, statusCode: this.status, body: response});
          }, {once: true});
        }
        return send.apply(this, arguments);
      };
      const fetch = window.fetch;
      window.fetch = function(input, options) {
        const url = target(typeof input === 'string' || input instanceof URL ? input : input.url);
        if (!url) return fetch.apply(this, arguments);
        const id = 'fetch-' + (++sequence);
        const request = new Request(input instanceof Request ? input.clone() : input, options);
        const headers = Object.fromEntries(request.headers.entries());
        // Read a clone; the original request/response streams remain untouched.
        request.clone().text().then(value => emit('Request', {id, url, method: request.method, headers, body: body(value)})).catch(() => {});
        return fetch.apply(this, arguments).then(response => {
          response.clone().text().then(value => emit('Response', {id, url, statusCode: response.status, body: body(value)})).catch(() => {});
          return response;
        }, error => {
          emit('Response', {id, url, statusCode: 0, error: String(error)});
          throw error;
        });
      };
    })();
    """
}
