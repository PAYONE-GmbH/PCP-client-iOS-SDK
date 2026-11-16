// Example backend contract; these types are not part of the PCPClient SDK product.
import Foundation
import PassKit

struct DemoQuote: Decodable {
    struct Item: Decodable {
        let label: String
        let amount: String
        var decimal: NSDecimalNumber { NSDecimalNumber(string: amount, locale: Locale(identifier: "en_US_POSIX")) }
        var valid: Bool { amount.range(of: #"^\d+\.\d{2}$"#, options: .regularExpression) != nil && decimal != .notANumber }
        var summary: PKPaymentSummaryItem { PKPaymentSummaryItem(label: label, amount: decimal) }
    }
    struct Shipping: Decodable {
        let identifier: String
        let label: String
        let detail: String
        let amount: String
        var method: PKShippingMethod {
            let method = PKShippingMethod(label: label,
                                          amount: NSDecimalNumber(string: amount, locale: Locale(identifier: "en_US_POSIX")))
            method.identifier = identifier
            method.detail = detail
            return method
        }
    }
    struct Issue: Decodable { let code: String; let field: String; let message: String }
    let cartId: String
    let currencyCode: String
    let quoteId: String?
    let expiresAt: String?
    let shippingMethods: [Shipping]
    let selectedShippingMethodIdentifier: String?
    let lineItems: [Item]
    let total: Item
    let errors: [Issue]

    var validAmounts: Bool {
        total.valid && !lineItems.isEmpty && lineItems.allSatisfy(\.valid) &&
        shippingMethods.allSatisfy { Item(label: $0.label, amount: $0.amount).valid } &&
        lineItems.reduce(NSDecimalNumber.zero) { $0.adding($1.decimal) } == total.decimal
    }
    var isUsable: Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let expiresAt,
              let expiry = formatter.date(from: expiresAt) ?? ISO8601DateFormatter().date(from: expiresAt),
              let quoteId, !quoteId.isEmpty else { return false }
        return expiry > Date() && validAmounts && errors.isEmpty &&
            shippingMethods.contains { $0.identifier == selectedShippingMethodIdentifier }
    }
    var summaryItems: [PKPaymentSummaryItem] { lineItems.map(\.summary) + [total.summary] }
    var methods: [PKShippingMethod] {
        // PassKit defaults to the first method after contact updates.
        (shippingMethods.filter { $0.identifier == selectedShippingMethodIdentifier } +
         shippingMethods.filter { $0.identifier != selectedShippingMethodIdentifier }).map(\.method)
    }
}

struct DemoReceipt: Decodable {
    let success: Bool
    let mode: String
    let paymentStatus: String
    let orderId: String
    let quoteId: String
    let cartId: String
    let currencyCode: String
    let shippingMethodIdentifier: String
    let total: DemoQuote.Item

    func matches(_ quote: DemoQuote) -> Bool {
        success && mode == "demo" && paymentStatus == "simulated" && orderId.hasPrefix("demo-order-") &&
        quoteId == quote.quoteId && cartId == quote.cartId && currencyCode == quote.currencyCode &&
        shippingMethodIdentifier == quote.selectedShippingMethodIdentifier && total.valid && total.decimal == quote.total.decimal
    }
}

enum DemoCheckoutError: LocalizedError {
    case invalidQuote, invalidReceipt, superseded, http(Int)
    var errorDescription: String? {
        switch self {
        case .invalidQuote: return "Versandangebot ungültig oder abgelaufen. Bitte neu berechnen."
        case .invalidReceipt: return "Ungültige Demo-Bestätigung."
        case .superseded: return "Versanddaten wurden inzwischen geändert."
        case .http(409): return "Versandangebot abgelaufen oder geändert. Bitte Versand neu auswählen."
        case .http(let status): return "Demo-Server meldet einen Fehler (HTTP \(status)). Bitte erneut versuchen."
        }
    }
}
