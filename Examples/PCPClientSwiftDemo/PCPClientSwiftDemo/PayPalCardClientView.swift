//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import CardPayments
import CorePayments
import SwiftUI

// MARK: - Layout Constants
private enum Layout {
  static let stackSpacing: CGFloat = 16
  static let verticalPadding: CGFloat = 8
  static let cornerRadius: CGFloat = 8
}

// MARK: - Card Client View
public struct PayPalCardClientView: View {
  // MARK: - Properties
  @Binding public var cardClient: CardClient?
  @Binding public var cardClientStatus: String
  @State private var clientID: String = "YOUR_CLIENT_ID"  // Replace with your actual PayPal Client ID

  // MARK: - Body
  public var body: some View {
    VStack(alignment: .leading, spacing: Layout.stackSpacing) {
      Text("Step 2: Create CardClient")
        .font(.headline)

      Text(
        "A CardClient helps you attach a card to a payment. Create a CoreConfig with your Client ID."
      )
      .font(.body)

      TextField("Enter your PayPal Client ID", text: $clientID)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(.vertical, Layout.verticalPadding)

      Button(
        action: {
          createCardClient()
        },
        label: {
          Text("Create CardClient")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(Layout.cornerRadius)
        })

      Text("Status: \(cardClientStatus)")
        .foregroundColor(cardClientStatus == "Created successfully" ? .green : .primary)
        .padding(.top, Layout.verticalPadding)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(Layout.cornerRadius)
  }

  // MARK: - Methods
  private func createCardClient() {
    do {
      // Create CoreConfig with the provided clientID
      let coreConfig = CoreConfig(clientID: clientID, environment: .sandbox)

      // Initialize CardClient with the config
      cardClient = CardClient(config: coreConfig)

      // Update status
      cardClientStatus = "Created successfully"
    } catch {
      cardClientStatus = "Error: \(error.localizedDescription)"
    }
  }
}
