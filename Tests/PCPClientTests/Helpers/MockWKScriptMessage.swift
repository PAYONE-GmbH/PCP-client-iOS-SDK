//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import WebKit

internal final class MockWKScriptMessage: WKScriptMessage {
  private var mockName: String
  private var mockBody: [String: Any]

  override internal var name: String {
    mockName
  }

  override internal var body: Any {
    mockBody
  }

  internal init(name: String, body: [String: Any] = [:]) {
    mockName = name
    mockBody = body
    super.init()
  }
}
