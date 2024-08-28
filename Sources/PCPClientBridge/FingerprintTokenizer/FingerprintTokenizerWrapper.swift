//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

@objc public class FingerprintTokenizerWrapper: NSObject {
    private let tokenizer: FingerprintTokenizer

    public init(
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
