//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation

// MARK: - Order ID Service
public enum OrderIDService {
  // Fetch order ID from server
  public static func getOrderID(
    from url: URL, completion: @escaping (Result<String, Error>) -> Void
  ) {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    URLSession.shared.dataTask(with: request) { data, _, error in
      if let error {
        completion(.failure(error))
        return
      }

      guard let data else {
        let noDataError = NSError(
          domain: "com.payone.pcpclient",
          code: OrderIDErrorCode.noDataReceived,
          userInfo: [NSLocalizedDescriptionKey: "No data received"]
        )
        completion(.failure(noDataError))
        return
      }

      // Parse the response to extract order ID
      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let orderID = json["id"] as? String
        {
          completion(.success(orderID))
        } else {
          let responseString = String(data: data, encoding: .utf8) ?? "Unknown response"
          let extractError = NSError(
            domain: "com.payone.pcpclient",
            code: OrderIDErrorCode.failedToExtractOrderID,
            userInfo: [NSLocalizedDescriptionKey: "Failed to extract order ID: \(responseString)"]
          )
          completion(.failure(extractError))
        }
      } catch {
        completion(.failure(error))
      }
    }
    .resume()
  }
}
