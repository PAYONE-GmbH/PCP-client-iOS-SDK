//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PaymentButtons
import SwiftUI
import UIKit

public struct PayPalWebPaymentsView: View {
  @State private var paymentResult: String = "No payment result yet"
  @State private var isProcessing: Bool = false
  @ObservedObject private var viewModel = PayPalViewModel()

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("PayPal Web Payments Integration")
        .font(.headline)
        .padding(.bottom, 8)

      Text("This example demonstrates how to integrate PayPal Web Payments in your app.")
        .font(.subheadline)
        .padding(.bottom, 16)

      // Payment amount selection
      VStack(alignment: .leading, spacing: 8) {
        Text("Select Payment Amount:")
          .font(.subheadline)
          .bold()

        Picker("Amount", selection: $viewModel.selectedAmountIndex) {
          Text("$5.00").tag(0)
          Text("$10.00").tag(1)
          Text("$25.00").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 8)
      }

      // Official PayPal button using PayPalButton.Representable directly from the SDK
        PaymentButtons.PayPalButton.Representable(edges:.softEdges) {
        isProcessing = true
        viewModel.initiatePayment { result in
          isProcessing = false
          switch result {
          case .success(let message):
            paymentResult = message
          case .failure(let error):
            paymentResult = "Error: \(error.localizedDescription)"
          }
        }
      }
      .frame(height: 44)
      .accessibility(label: Text("Pay with PayPal"))
      .disabled(isProcessing)

      if isProcessing {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(1.5)
          .padding()
      }

      // Payment result display
      VStack(alignment: .leading, spacing: 8) {
        Text("Payment Result:")
          .font(.subheadline)
          .bold()

        Text(paymentResult)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.systemGray6))
          .cornerRadius(8)
      }

      Spacer()
    }
    .padding()
    .navigationTitle("PayPal Web Payments")
  }
}

#Preview {
  PayPalWebPaymentsView()
}
