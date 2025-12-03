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
    iframeConfig: IframeConfig,
    uiConfig: UIConfig?,
    locale: String?,
    token: String,
    mode: String?,
    allowedCardSchemes: [String]?,
    customTextConfig: CustomTextConfig?,
    submitButtonConfig: SubmitButtonConfig,
    tokenizationSuccessCallback: ((Int, String, CardDetails, String) -> Void)?,
    tokenizationFailureCallback: ((Int, [String: Any]) -> Void)?
  ) {
    creditcardTokenizerConfig = CreditcardTokenizerConfig(
      iframeConfig: iframeConfig,
      uiConfig: uiConfig,
      locale: locale,
      token: token,
      mode: mode,
      allowedCardSchemes: allowedCardSchemes,
      customTextConfig: customTextConfig,
      submitButtonConfig: submitButtonConfig,
      tokenizationSuccessCallback: tokenizationSuccessCallback,
      tokenizationFailureCallback: tokenizationFailureCallback
    )
  }
}
