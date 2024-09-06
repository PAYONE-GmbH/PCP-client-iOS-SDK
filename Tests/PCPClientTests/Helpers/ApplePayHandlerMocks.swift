//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PassKit

internal class PKPaymentRequestPaymentMethodUpdateMock: PKPaymentRequestPaymentMethodUpdate {}

internal class PKPaymentRequestCouponCodeUpdateMock: PKPaymentRequestCouponCodeUpdate {}

internal class PKPaymentRequestShippingContactUpdateMock: PKPaymentRequestShippingContactUpdate {}

internal class PKPaymentRequestShippingMethodUpdateMock: PKPaymentRequestShippingMethodUpdate {}

internal class PKPaymentAuthorizationControllerMock: PKPaymentAuthorizationController {
    internal var invokedDismissCount = 0

    override internal func dismiss(completion _: (() -> Void)? = nil) {
        invokedDismissCount += 1
    }
}
