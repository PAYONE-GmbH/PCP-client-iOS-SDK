//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PCPClient

@objc public class CreditcardTokenizerConfigWrapper: NSObject {
    let creditcardTokenizerConfig: CreditcardTokenizerConfig

    @objc init(
        cardPan: Field,
        cardCvc2: Field,
        cardExpireMonth: Field,
        cardExpireYear: Field,
        defaultStyles: [String: String],
        language: PayoneLanguage,
        error: String,
        submitButtonId: String,
        success: @escaping (CCTokenizerResponse) -> Void,
        failure: @escaping (CCTokenizerError) -> Void
    ) {
        creditcardTokenizerConfig = CreditcardTokenizerConfig(
            cardPan: cardPan,
            cardCvc2: cardCvc2,
            cardExpireMonth: cardExpireMonth,
            cardExpireYear: cardExpireYear,
            defaultStyles: defaultStyles,
            language: language,
            error: error,
            submitButtonId: submitButtonId,
            creditCardCheckCallback: { result in
                switch result {
                case let .success(response):
                    success(response)
                case let .failure(error):
                    failure(error)
                }
            }
        )
    }
}



