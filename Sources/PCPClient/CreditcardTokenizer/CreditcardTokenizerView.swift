//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import SwiftUI
import UIKit

/// `UIViewControllerRepresentable` to use the `CreditcardTokenizerViewController` with SwiftUI.
public struct CreditcardTokenizerView: UIViewControllerRepresentable {
  internal let tokenizerUrl: URL
  internal let config: CreditcardTokenizerConfig
  internal let jwtToken: String

  public init(
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig,
    jwtToken: String
  ) {
    self.tokenizerUrl = tokenizerUrl
    self.config = config
    self.jwtToken = jwtToken
  }

  public func makeUIViewController(context _: Context) -> CreditcardTokenizerViewController {
    CreditcardTokenizerViewController(
      tokenizerUrl: tokenizerUrl,
      config: config,
      jwtToken: jwtToken
    )
  }

  public func updateUIViewController(_: CreditcardTokenizerViewController, context _: Context) {
    // Update the view controller if needed
  }
}
