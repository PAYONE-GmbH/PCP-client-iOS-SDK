//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import CardPayments
import SwiftUI

// Constants for layout
private enum Layout {
  static let stackSpacing: CGFloat = 16
  static let bottomPadding: CGFloat = 8
  static let cornerRadius: CGFloat = 8
}

public struct PayPalCardView: View {
  // MARK: - Properties
  // Step 2: Create CardClient
  @State private var cardClientStatus: String = "Not created"

  // The CardClient will be initialized when the "Create CardClient" button is tapped
  @State private var cardClient: CardClient?

  // Step 3: Get Order ID
  @State private var orderID: String = ""
  @State private var orderStatus: String = "Not fetched"

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.stackSpacing) {
        // Header
        Text("PayPal Card Payment")
          .font(.largeTitle)
          .padding(.bottom, Layout.bottomPadding)

        // Step 1: Add CardPayments Module
        stepOneView

        // Step 2: Create CardClient
        PayPalCardClientView(cardClient: $cardClient, cardClientStatus: $cardClientStatus)

        // Step 3: Get Order ID
        PayPalOrderIDView(orderID: $orderID, orderStatus: $orderStatus)

        Spacer()
      }
      .padding()
    }
    .navigationTitle("PayPal Card Payment")
  }

  // MARK: - Helper Views
  private var stepOneView: some View {
    VStack(alignment: .leading, spacing: Layout.stackSpacing) {
      Text("Step 1: Add CardPayments Module")
        .font(.headline)

      Text("✅ Completed: CardPayments module has been added to the project.")
        .font(.body)
        .foregroundColor(.green)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(Layout.cornerRadius)
  }
}
