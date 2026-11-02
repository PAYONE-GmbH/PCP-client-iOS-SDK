// Example order data collected BEFORE the standard Apple Pay sheet is presented.
import Contacts
import Foundation
import PassKit

@objc public final class ApplePayDemoStandardOrder: NSObject {
    @objc public let shippingContact: PKContact
    @objc public let billingContact: PKContact
    @objc public let shippingMethodIdentifier: String

    @objc public init(shippingContact: PKContact, billingContact: PKContact, shippingMethodIdentifier: String) {
        self.shippingContact = shippingContact
        self.billingContact = billingContact
        self.shippingMethodIdentifier = shippingMethodIdentifier
        super.init()
    }

    var isValid: Bool {
        !shippingMethodIdentifier.isEmpty && [shippingContact, billingContact].allSatisfy { contact in
            guard let address = contact.postalAddress else { return false }
            return !address.street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !address.postalCode.isEmpty && !address.isoCountryCode.isEmpty &&
                !(contact.name?.givenName ?? "").isEmpty && !(contact.name?.familyName ?? "").isEmpty
        }
    }

    @objc public var summary: String {
        func format(_ contact: PKContact) -> String {
            let address = contact.postalAddress
            return [contact.name?.givenName, contact.name?.familyName, address?.street,
                    address?.postalCode, address?.city, address?.isoCountryCode].compactMap { $0 }.joined(separator: " ")
        }
        return "Lieferadresse: \(format(shippingContact))\nRechnungsadresse: \(format(billingContact))\nVersand: \(shippingMethodIdentifier)"
    }

    /// The bundled order stands in for the merchant's preceding checkout/address form.
    @objc(loadFromBundle:error:)
    public static func load(from bundle: Bundle) throws -> ApplePayDemoStandardOrder {
        guard let url = bundle.url(forResource: "ApplePayDemoStandardOrder", withExtension: "plist"),
              let values = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any],
              let shipping = values["shippingContact"] as? [String: String],
              let billing = values["billingContact"] as? [String: String],
              let method = values["shippingMethodIdentifier"] as? String else { throw configurationError }
        let order = ApplePayDemoStandardOrder(shippingContact: contact(shipping), billingContact: contact(billing),
                                              shippingMethodIdentifier: method)
        guard order.isValid else { throw configurationError }
        return order
    }

    private static var configurationError: NSError {
        NSError(domain: "ApplePayDemo.StandardOrder", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "ApplePayDemoStandardOrder.plist fehlt oder enthält unvollständige Bestelldaten."
        ])
    }

    private static func contact(_ values: [String: String]) -> PKContact {
        let contact = PKContact()
        var name = PersonNameComponents()
        name.givenName = values["givenName"]
        name.familyName = values["familyName"]
        contact.name = name
        let address = CNMutablePostalAddress()
        address.street = values["street"] ?? ""
        address.city = values["city"] ?? ""
        address.postalCode = values["postalCode"] ?? ""
        address.isoCountryCode = values["countryCode"]?.uppercased() ?? ""
        contact.postalAddress = address
        contact.emailAddress = values["emailAddress"]
        contact.phoneNumber = values["phoneNumber"].map(CNPhoneNumber.init(stringValue:))
        return contact
    }
}
