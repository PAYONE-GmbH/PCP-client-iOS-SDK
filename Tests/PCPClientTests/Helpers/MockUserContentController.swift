//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import WebKit

internal class MockUserContentController: WKUserContentController {
    internal var addedHandlers = [String]()

    override internal func add(_ scriptMessageHandler: WKScriptMessageHandler, name: String) {
        addedHandlers.append(name)
        super.add(scriptMessageHandler, name: name)
    }
}
