//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

/// Objective-C wrapper for the `CreditcardTokenizerConfig`.
@objc public class CreditcardTokenizerConfigWrapper: NSObject {
  /// The `CreditcardTokenizerConfig` which can be used besides it's completion.
  @objc public let creditcardTokenizerConfig: CreditcardTokenizerConfig

  @objc public init(
    iframeConfig: IframeConfig?,
    uiConfig: UIConfig?,
    locale: String?,
    submitButtonConfig: SubmitButtonConfig?,
    environment: String,
    tokenizationSuccessCallback: ((Int, String, [String: Any]?) -> Void)?,
    tokenizationFailureCallback: ((Int, [String: Any]?) -> Void)?
  ) {
    creditcardTokenizerConfig = CreditcardTokenizerConfig(
      iframeConfig: iframeConfig,
      uiConfig: uiConfig,
      locale: locale,
      submitButtonConfig: submitButtonConfig,
      environment: environment,
      tokenizationSuccessCallback: tokenizationSuccessCallback,
      tokenizationFailureCallback: tokenizationFailureCallback
    )
  }
}
