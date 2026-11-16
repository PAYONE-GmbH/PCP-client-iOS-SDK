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
  internal let localHTMLBaseURL: URL?
  internal let onDiagnosticEvent: ((String, [String: Any]) -> Void)?
  internal let includeSensitiveDiagnosticData: Bool

  public init(
    tokenizerUrl: URL,
    config: CreditcardTokenizerConfig,
    localHTMLBaseURL: URL? = nil,
    onDiagnosticEvent: ((String, [String: Any]) -> Void)? = nil,
    includeSensitiveDiagnosticData: Bool = false
  ) {
    self.tokenizerUrl = tokenizerUrl
    self.config = config
    self.localHTMLBaseURL = localHTMLBaseURL
    self.onDiagnosticEvent = onDiagnosticEvent
    self.includeSensitiveDiagnosticData = includeSensitiveDiagnosticData
  }

  public func makeUIViewController(context _: Context) -> CreditcardTokenizerViewController {
    let controller = CreditcardTokenizerViewController(
      tokenizerUrl: tokenizerUrl,
      config: config
    )
    controller.localHTMLBaseURL = localHTMLBaseURL
    controller.onDiagnosticEvent = onDiagnosticEvent
    controller.includeSensitiveDiagnosticData = includeSensitiveDiagnosticData
    return controller
  }

  public func updateUIViewController(_ controller: CreditcardTokenizerViewController, context _: Context) {
    controller.onDiagnosticEvent = onDiagnosticEvent
  }
}
