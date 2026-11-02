// Example configuration, deliberately separate from the SDK and checkout implementation.
import Foundation

@objc public final class ApplePayDemoConfiguration: NSObject {
    @objc public let merchantIdentifier: String
    @objc public let baseURL: URL
    @objc public let cartID: String
    @objc public let countryCode: String
    @objc public let currencyCode: String
    @objc public let initialShippingMethodIdentifier: String

    @objc public init(merchantIdentifier: String, baseURL: URL, cartID: String,
                      countryCode: String, currencyCode: String, initialShippingMethodIdentifier: String) {
        self.merchantIdentifier = merchantIdentifier
        self.baseURL = baseURL
        self.cartID = cartID
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.initialShippingMethodIdentifier = initialShippingMethodIdentifier
        super.init()
    }

    /// Both apps bundle the same editable plist. No merchant/server fallback is embedded in Swift.
    @objc(loadFromBundle:error:)
    public static func load(from bundle: Bundle) throws -> ApplePayDemoConfiguration {
        guard let url = bundle.url(forResource: "ApplePayDemoConfiguration", withExtension: "plist"),
              let values = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
                as? [String: String],
              let merchant = values["merchantIdentifier"], merchant.hasPrefix("merchant."),
              let server = values["baseURL"], let baseURL = URL(string: server),
              baseURL.scheme == "https", baseURL.host?.isEmpty == false,
              let cart = values["cartID"], !cart.isEmpty,
              let country = values["countryCode"], country.range(of: #"^[A-Z]{2}$"#, options: .regularExpression) != nil,
              let currency = values["currencyCode"], currency.range(of: #"^[A-Z]{3}$"#, options: .regularExpression) != nil,
              let shipping = values["initialShippingMethodIdentifier"], !shipping.isEmpty else {
            throw NSError(domain: "ApplePayDemo.Configuration", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "ApplePayDemoConfiguration.plist fehlt oder enthält ungültige Werte."
            ])
        }
        return ApplePayDemoConfiguration(merchantIdentifier: merchant, baseURL: baseURL, cartID: cart,
                                         countryCode: country, currencyCode: currency, initialShippingMethodIdentifier: shipping)
    }
}
