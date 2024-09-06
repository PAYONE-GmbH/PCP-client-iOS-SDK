//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

/// Wraps the `FingerprintTokenizer` so it can be used by Objective-C apps.
@objc public class FingerprintTokenizerWrapper: NSObject {
    internal let tokenizer: FingerprintTokenizer

    /// Initializes the wrapper and therefore the `FingerprintTokenizer`.
    /// - Parameters:
    ///   - paylaPartnerId: The Payla partner ID.
    ///   - partnerMerchantId: Your partner merchant ID.
    ///   - environment: The `PCPEnvironment` you want to use. Either `test` or `production`.
    ///   - sessionId: An optional session ID that you want created on your own.`
    @objc public init(
        paylaPartnerId: String,
        partnerMerchantId: String,
        environment: PCPEnvironment,
        sessionId: String? = nil
    ) {
        self.tokenizer = FingerprintTokenizer(
            paylaPartnerId: paylaPartnerId,
            partnerMerchantId: partnerMerchantId,
            environment: environment,
            sessionId: sessionId
        )
    }

    /// Attempts to get the snippet token, could fail during the process.
    /// - Parameters:
    ///   - success: Handle the token after successfully retrieving it.
    ///   - failure: Handle potential error cases in this block.
    @objc public func getSnippetToken(
        success: @escaping (String) -> Void,
        failure: @escaping (FingerprintErrorWrapper) -> Void
    ) {
        tokenizer.getSnippetToken { result in
            switch result {
            case let .success(token):
                success(token)
            case let .failure(error):
                failure(error.toWrappedError())
            }
        }
    }
}
