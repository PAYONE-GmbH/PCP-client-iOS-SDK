//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

internal enum CCScriptMessageType: String {
  case scriptLoaded
  case scriptError
  case responseReceived

  internal func makeWebkitMessageString(body: String) -> String {
    switch self {
    case .scriptLoaded:
      return "window.webkit.messageHandlers.scriptLoaded.postMessage(\(body));"
    case .scriptError:
      return "window.webkit.messageHandlers.scriptError.postMessage(\(body));"
    case .responseReceived:
      return "window.webkit.messageHandlers.responseReceived.postMessage(\(body));"
    }
  }
}
