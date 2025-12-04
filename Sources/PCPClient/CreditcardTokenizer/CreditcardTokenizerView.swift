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

  public init(
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig
  ) {
    self.tokenizerUrl = tokenizerUrl
    self.config = config
  }

  public func makeUIViewController(context _: Context) -> CreditcardTokenizerViewController {
    CreditcardTokenizerViewController(
      tokenizerUrl: tokenizerUrl,
      config: config
    )
  }

  public func updateUIViewController(_: CreditcardTokenizerViewController, context _: Context) {
    // Update the view controller if needed
  }
}
