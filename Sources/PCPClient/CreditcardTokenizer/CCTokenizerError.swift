//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

/// The creditcard tokenizer errors that can occur during tokenization of a creditcard.
@objc public enum CCTokenizerError: Int, Error {
    case loadingScriptFailed
    case populatingHTMLFailed
    case invalidResponse
}
