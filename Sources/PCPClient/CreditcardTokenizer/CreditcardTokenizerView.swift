//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import SwiftUI
import UIKit

public struct CreditcardTokenizerView: UIViewControllerRepresentable {
    let tokenizerUrl: URL
    let request: CCTokenizerRequest
    let supportedCardTypes: [String]
    let config: CreditcardTokenizerConfig

    public init(tokenizerUrl: URL, request: CCTokenizerRequest, supportedCardTypes: [String], config: CreditcardTokenizerConfig) {
        self.tokenizerUrl = tokenizerUrl
        self.request = request
        self.supportedCardTypes = supportedCardTypes
        self.config = config
    }

    public func makeUIViewController(context: Context) -> CreditcardTokenizerViewController {
        CreditcardTokenizerViewController(
            tokenizerUrl: tokenizerUrl,
            request: request,
            supportedCardTypes: supportedCardTypes,
            config: config
        )
    }

    public func updateUIViewController(_ uiViewController: CreditcardTokenizerViewController, context: Context) {
        // Update the view controller if needed
    }
}
