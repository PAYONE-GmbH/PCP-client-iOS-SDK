//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import CommonCrypto

@objc public class CCTokenizerRequest: NSObject {
    let mid: String
    let aid: String
    let portalId: String
    let environment: PCPEnvironment
    let generatedHash: String

    @objc public init(
        mid: String,
        aid: String,
        portalId: String,
        environment: PCPEnvironment,
        pmiPortalKey: String
    ) {
        self.mid = mid
        self.aid = aid
        self.portalId = portalId
        self.environment = environment
        self.generatedHash = Self.makeHash(
            environment: environment,
            mid: mid,
            aid: aid,
            portalId: portalId,
            pmiPortalKey: pmiPortalKey
        )
    }

    private static func makeHash(
        environment: PCPEnvironment,
        mid: String,
        aid: String,
        portalId: String,
        pmiPortalKey: String
    ) -> String {
        let requestValues = [
            aid,
            "3.11",
            "UTF-8",
            mid,
            environment.ccTokenizerIdentifier,
            portalId,
            "creditcardcheck",
            "JSON",
            "yes"
        ];

        let hash = createHash(requestValues.joined(separator: ""), pmiPortalKey)
        return hash
    }

    private static func createHash(_ string: String, _ secret: String) -> String {
        let stringToSign = "\(string)\(secret)"
        let key = secret.data(using: .utf8)!
        let data = stringToSign.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes {
            guard let baseAddress = $0.baseAddress else { return }
            key.withUnsafeBytes { keyBytes in
                guard let keyAddress = keyBytes.baseAddress else { return }
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512), keyAddress, key.count, baseAddress, data.count, &digest)
            }
        }
        let hash = Data(digest).base64EncodedString()
        return hash
    }
}
