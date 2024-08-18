//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

public struct PCPClient {
    public func frameworkName(isShortName: Bool) -> String {
        if isShortName {
            return "PCPC"
        }
        return "PCPClient"
    }
}
