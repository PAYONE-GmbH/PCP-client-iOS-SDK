//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import SwiftUI

// MARK: - Order ID View
public struct PayPalOrderIDView: View {
  // MARK: - Properties
  @Binding public var orderID: String
  @Binding public var orderStatus: String
  @State private var serverURL: String = "https://your-server.com/create-order"
  @State private var isLoading: Bool = false

  // MARK: - Initialization
  public init(orderID: Binding<String>, orderStatus: Binding<String>) {
    self._orderID = orderID
    self._orderStatus = orderStatus
  }

  // MARK: - Body
  public var body: some View {
    containerView
  }

  // MARK: - Container View
  private var containerView: some View {
    VStack(alignment: .leading, spacing: PayPalOrderIDViewLayout.stackSpacing) {
      headerView
      mainContentView
      actionButton
      statusView
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(PayPalOrderIDViewLayout.cornerRadius)
  }

  // MARK: - Header View
  private var headerView: some View {
    VStack(alignment: .leading, spacing: PayPalOrderIDViewLayout.stackSpacing) {
      Text("Step 3: Get Order ID")
        .font(.headline)

      Text("An ORDER_ID is required to link the card payment to a specific transaction.")
        .font(.body)

      Text("Your server should create this using the PayPal Orders API.")
        .font(.body)
    }
  }

  // MARK: - Main Content View
  private var mainContentView: some View {
    TextField("Enter your server endpoint URL", text: $serverURL)
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .padding(.vertical, PayPalOrderIDViewLayout.verticalPadding)
  }

  // MARK: - Action Button
  private var actionButton: some View {
    Button(
      action: {
        fetchOrderID()
      },
      label: {
        HStack {
          if isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .padding(.trailing, PayPalOrderIDViewLayout.iconPadding)
          }

          Text("Fetch Order ID")
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(PayPalOrderIDViewLayout.cornerRadius)
      }
    )
    .disabled(isLoading)
  }

  // MARK: - Status View
  private var statusView: some View {
    VStack(alignment: .leading, spacing: PayPalOrderIDViewLayout.textSpacing) {
      Text("Status: \(orderStatus)")
        .foregroundColor(orderID.isEmpty ? .primary : .green)

      if !orderID.isEmpty {
        Text("Order ID: \(orderID)")
          .font(.subheadline)
          .foregroundColor(.green)
      }
    }
    .padding(.top, PayPalOrderIDViewLayout.verticalPadding)
  }

  // MARK: - Methods
  private func fetchOrderID() {
    guard let url = URL(string: serverURL) else {
      orderStatus = "Error: Invalid URL"
      return
    }

    isLoading = true
    orderStatus = "Fetching..."

    OrderIDService.getOrderID(from: url) { result in
      DispatchQueue.main.async {
        isLoading = false

        switch result {
        case .success(let id):
          orderID = id
          orderStatus = "Order ID received successfully"
        case .failure(let error):
          orderID = ""
          orderStatus = "Error: \(error.localizedDescription)"
        }
      }
    }
  }
}
