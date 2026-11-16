//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PassKit

/// Compatibility transport. Express integrations supply their own authorization callback.
internal final class ApplePayPaymentTransport {
    private struct Response: Decodable { let success: Bool }

    private let url: URL
    private let session: URLSession
    private static let timeout: TimeInterval = 20
    private static let successHTTPStatus = 200

    internal init(url: URL, session: URLSession) {
        self.url = url
        self.session = session
    }

    internal func authorize(_ payment: PKPayment, completion: @escaping (Bool) -> Void) -> URLSessionDataTask? {
        do {
            guard let token = try JSONSerialization.jsonObject(with: payment.token.paymentData) as? [String: Any] else {
                completion(false)
                return nil
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = Self.timeout
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "token": ["paymentData": token],
                "paymentMethod": payment.token.paymentMethod.network?.rawValue ?? "",
                "transactionIdentifier": payment.token.transactionIdentifier
            ])
            let task = session.dataTask(with: request) { data, response, error in
                let result = data.flatMap { try? JSONDecoder().decode(Response.self, from: $0) }
                completion(error == nil && (response as? HTTPURLResponse)?.statusCode == Self.successHTTPStatus &&
                    result?.success == true)
            }
            task.resume()
            return task
        } catch {
            completion(false)
            return nil
        }
    }
}
