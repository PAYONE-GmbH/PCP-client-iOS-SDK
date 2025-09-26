//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import CorePayments
import Foundation
import PayPalWebPayments

public class PayPalViewModel: ObservableObject {
  @Published public var selectedAmountIndex: Int = 0

  private let amounts = ["5.00", "10.00", "25.00"]
  private var payPalWebCheckoutClient: PayPalWebCheckoutClient?
  private var completion: ((Result<String, Error>) -> Void)?

  public func initiatePayment(completion: @escaping (Result<String, Error>) -> Void) {
    self.completion = completion

    // 1. Create CoreConfig with client ID
    let config = CoreConfig(
      clientID: "AUn5n-4qxBUkdzQBv6f8yd8F4AWdEvV6nLzbAifDILhKGCjOS62qQLiKbUbpIKH_O2Z3OL8CvX7ucZfh",  // Replace with your actual client ID
      environment: .sandbox
    )

    // 2. Create PayPalWebCheckoutClient
    let payPalClient = PayPalWebCheckoutClient(config: config)
    self.payPalWebCheckoutClient = payPalClient

    // 3. Get Order ID from server (simulated here)
    getOrderIdFromServer { [weak self] result in
      guard let self = self else { return }

      switch result {
      case .success(let orderId):
        // 4. Create web checkout request
        let payPalWebRequest = PayPalWebCheckoutRequest(
          orderID: orderId,
          fundingSource: .paypal
        )

        // 5. Start checkout with completion handler (new approach in 2.0.0)
        payPalClient.start(request: payPalWebRequest) { [weak self] result in
          guard let self = self else { return }

          switch result {
          case .success(let payPalResult):
            // Order was approved and is ready to be captured/authorized
            self.authorizeOrCaptureOrder(orderId: payPalResult.orderID)
          case .failure(let error):
            // Handle errors including cancellation
            if PayPalError.isCheckoutCanceled(error) {
              // Handle cancellation specifically
              let errorDomain = "PayPalError"
              let userCanceledError = NSError(
                domain: errorDomain,
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Payment was canceled by the user"]
              )
              self.completion?(.failure(userCanceledError))
            } else {
              // Handle other errors
              self.completion?(.failure(error))
            }
          }
        }

      case .failure(let error):
        self.completion?(.failure(error))
      }
    }
  }

  private func getOrderIdFromServer(completion: @escaping (Result<String, Error>) -> Void) {
    // This would typically be an API call to your server
    // For demo purposes, we're simulating the server response

    // Simulate network delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // Return a mock order ID
      let orderID = "MOCK-ORDER-ID-\(UUID().uuidString.prefix(8))" // In a real implementation, you would get the orderID (or payPalTransactionId) from your Server with th PCP Server SDK
      completion(.success(orderID))

      // In a real implementation, you would make a network request to your server
    }
  }

  private func authorizeOrCaptureOrder(orderId: String) {
    // In a real implementation, you would call your server to authorize or capture the order
    // For demo purposes, we're simulating the server response

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // Return success
      self.completion?(.success("Payment successful! Order ID: \(orderId)"))

      // In a real implementation, you would make a network request to your server
    }
  }
}
