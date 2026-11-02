// Shared by the Swift and Objective-C examples; not part of the SDK's public API.
import Contacts
import Foundation
import PassKit
import PCPClient

@objc public final class ApplePayDemoCheckout: NSObject {
    private let configuration: ApplePayDemoConfiguration
    private let backend: DemoBackendClient
    private let handler: ApplePayHandler
    private let standardOrder: ApplePayDemoStandardOrder?
    private var orderShipping: [String: Any] = [:]
    private var orderBilling: [String: Any] = [:]
    private var quote: DemoQuote?
    private var contact: [String: Any] = [:]
    private var method: String
    private var revision = 0
    private var active = false
    private var message = ""
    private var summaryItems: [PKPaymentSummaryItem] = []

    @objc public convenience init(configuration: ApplePayDemoConfiguration) {
        self.init(configuration: configuration, session: .shared, handler: ApplePayHandler())
    }

    /// Standard checkout uses order contacts and shipping selected before opening Apple Pay.
    @objc public convenience init(configuration: ApplePayDemoConfiguration, standardOrder: ApplePayDemoStandardOrder) {
        self.init(configuration: configuration, session: .shared, handler: ApplePayHandler(), standardOrder: standardOrder)
    }

    init(configuration: ApplePayDemoConfiguration, session: URLSession, handler: ApplePayHandler,
         standardOrder: ApplePayDemoStandardOrder? = nil) {
        self.configuration = configuration
        self.standardOrder = standardOrder
        backend = DemoBackendClient(baseURL: configuration.baseURL, session: session)
        self.handler = handler
        contact = ["countryCode": configuration.countryCode]
        method = configuration.initialShippingMethodIdentifier
        super.init()
    }

    @objc public func supportsApplePay() -> Bool { handler.supportsApplePay() }

    @objc public func start(completion: @escaping (String) -> Void) {
        guard !active else { return }
        if let standardOrder, !standardOrder.isValid {
            completion("Standard-Checkout benötigt vollständige Bestelladressen und eine Versandart.")
            return
        }
        active = true
        quote = nil
        contact = ["countryCode": configuration.countryCode]
        method = configuration.initialShippingMethodIdentifier
        if let standardOrder {
            // Snapshot merchant order data; Wallet contacts must not replace the preceding checkout.
            orderShipping = Self.contactData(standardOrder.shippingContact)
            orderBilling = Self.contactData(standardOrder.billingContact)
            contact = orderShipping
            method = standardOrder.shippingMethodIdentifier
        }
        message = ""
        fetchQuote { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.active = false
                completion(error.localizedDescription)
            case .success(let quote):
                guard quote.isUsable else {
                    self.active = false
                    completion("Kein gültiges Versandangebot verfügbar.")
                    return
                }
                self.configureCallbacks(completion: completion)
                let request = self.makeRequest(quote)
                self.handler.startPayment(request: request, onDidSelectPaymentMethod: { [weak self] _ in
                    PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: self?.summaryItems ?? [])
                }, completion: { _ in })
            }
        }
    }

    private func configureCallbacks(completion: @escaping (String) -> Void) {
        handler.updateShippingContact = nil
        handler.updateShippingMethod = nil
        if standardOrder == nil { configureExpressUpdates() }
        handler.authorizePayment = { [weak self] payment, reply in
            self?.complete(payment: payment, reply: reply)
        }
        handler.didFinish = { [weak self] status in
            guard let self else { return }
            self.active = false
            self.revision += 1
            self.quote = nil
            self.orderShipping = [:]
            self.orderBilling = [:]
            switch status {
            case .success: completion(self.message)
            case .cancelled: completion("Apple Pay abgebrochen.")
            case .failure: completion(self.message.isEmpty ? "Checkout fehlgeschlagen. Bitte erneut versuchen." : self.message)
            @unknown default: completion("Checkout fehlgeschlagen.")
            }
        }
    }

    private func configureExpressUpdates() {
        handler.updateShippingContact = { [weak self] contact, reply in
            guard let self else { return }
            self.contact = Self.contactData(contact)
            self.fetchQuote { result in
                switch result {
                case .success(let quote):
                    let update = PKPaymentRequestShippingContactUpdate(paymentSummaryItems: quote.summaryItems)
                    update.shippingMethods = quote.methods
                    update.errors = quote.errors.map {
                        PKPaymentRequest.paymentShippingAddressInvalidError(
                            withKey: CNPostalAddressISOCountryCodeKey, localizedDescription: $0.message
                        )
                    }
                    reply(update)
                case .failure(let error):
                    let update = PKPaymentRequestShippingContactUpdate(paymentSummaryItems: self.summaryItems)
                    update.errors = [error]
                    reply(update)
                }
            }
        }
        handler.updateShippingMethod = { [weak self] method, reply in
            guard let self else { return }
            self.method = method.identifier ?? ""
            self.fetchQuote { result in
                let update: PKPaymentRequestShippingMethodUpdate
                switch result {
                case .success(let quote):
                    update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: quote.summaryItems)
                    if !quote.errors.isEmpty { self.message = DemoCheckoutError.invalidQuote.localizedDescription }
                case .failure(let error):
                    update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: self.summaryItems)
                    self.message = error.localizedDescription
                }
                reply(update)
            }
        }
    }

    private func makeRequest(_ quote: DemoQuote) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = configuration.merchantIdentifier
        request.countryCode = configuration.countryCode
        request.currencyCode = configuration.currencyCode
        request.supportedNetworks = [.visa, .masterCard, .girocard]
        request.merchantCapabilities = .threeDSecure
        if let standardOrder {
            request.shippingContact = standardOrder.shippingContact
            request.billingContact = standardOrder.billingContact
            request.requiredShippingContactFields = []
            request.requiredBillingContactFields = []
            request.shippingMethods = []
        } else {
            request.requiredShippingContactFields = [.postalAddress, .name, .emailAddress, .phoneNumber]
            request.requiredBillingContactFields = [.postalAddress, .name]
            request.shippingMethods = quote.methods
        }
        request.paymentSummaryItems = quote.summaryItems
        return request
    }

    /// Invalidates authorization immediately, before starting any asynchronous recalculation.
    func fetchQuote(completion: @escaping (Result<DemoQuote, Error>) -> Void) {
        revision += 1
        let currentRevision = revision
        quote = nil
        let body: [String: Any] = ["cartId": configuration.cartID, "shippingContact": contact,
                                   "shippingMethodIdentifier": method]
        backend.post("checkout/quote", body: body, as: DemoQuote.self) { [weak self] result in
            guard let self else { return }
            guard currentRevision == self.revision else {
                completion(.failure(DemoCheckoutError.superseded))
                return
            }
            switch result {
            case .success(let response):
                guard response.validAmounts, response.cartId == self.configuration.cartID,
                      response.currencyCode == self.configuration.currencyCode else {
                    completion(.failure(DemoCheckoutError.invalidQuote)); return
                }
                if let order = self.standardOrder, response.errors.isEmpty,
                   response.selectedShippingMethodIdentifier != order.shippingMethodIdentifier {
                    completion(.failure(DemoCheckoutError.invalidQuote)); return
                }
                self.summaryItems = response.summaryItems
                if response.isUsable {
                    self.quote = response
                    self.method = response.selectedShippingMethodIdentifier ?? self.configuration.initialShippingMethodIdentifier
                }
                completion(.success(response))
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    private func complete(payment: PKPayment, reply: @escaping (PKPaymentAuthorizationResult) -> Void) {
        guard let quote, quote.isUsable, quote.selectedShippingMethodIdentifier == method else {
            message = standardOrder == nil ?
                "Versandangebot fehlt oder ist abgelaufen. Adresse oder Versandart erneut auswählen." :
                "Bestellangebot fehlt oder ist abgelaufen. Checkout schließen und erneut starten."
            reply(PKPaymentAuthorizationResult(status: .failure, errors: [DemoCheckoutError.invalidQuote]))
            return
        }
        if standardOrder == nil, let selected = payment.shippingMethod?.identifier, selected != method {
            reply(PKPaymentAuthorizationResult(status: .failure, errors: [DemoCheckoutError.invalidQuote]))
            return
        }
        do {
            let body = try completionBody(payment: payment, quote: quote)
            let currentRevision = revision
            backend.post("process-payment", body: body, as: DemoReceipt.self) { [weak self] result in
                guard let self else { return }
                guard currentRevision == self.revision else {
                    reply(PKPaymentAuthorizationResult(status: .failure, errors: [DemoCheckoutError.superseded])); return
                }
                switch result {
                case .success(let receipt) where receipt.matches(quote):
                    self.message = "Simulierter Checkout erfolgreich: \(receipt.orderId). Keine PAYONE-Zahlung."
                    reply(PKPaymentAuthorizationResult(status: .success, errors: nil))
                case .success:
                    self.message = "Ungültige Demo-Bestätigung. Keine Zahlung bestätigt."
                    reply(PKPaymentAuthorizationResult(status: .failure, errors: [DemoCheckoutError.invalidReceipt]))
                case .failure(let error):
                    self.message = error.localizedDescription
                    reply(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                }
            }
        } catch {
            message = "Apple-Pay-Token konnte nicht übertragen werden."
            reply(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
        }
    }

    func completionBody(payment: PKPayment, quote: DemoQuote) throws -> [String: Any] {
        let token = try JSONSerialization.jsonObject(with: payment.token.paymentData)
        guard token is [String: Any] else { throw DemoCheckoutError.invalidReceipt }
        return ["cartId": configuration.cartID, "quoteId": quote.quoteId ?? "",
                "shippingMethodIdentifier": quote.selectedShippingMethodIdentifier ?? "",
                "token": ["paymentData": token,
                          "paymentMethod": ["network": payment.token.paymentMethod.network?.rawValue ?? ""],
                          "transactionIdentifier": payment.token.transactionIdentifier],
                "shippingContact": standardOrder == nil ? Self.contactData(payment.shippingContact ?? PKContact()) : orderShipping,
                "billingContact": standardOrder == nil ? Self.contactData(payment.billingContact ?? PKContact()) : orderBilling]
    }

    static func contactData(_ contact: PKContact) -> [String: Any] {
        var result: [String: Any] = [:]
        if let address = contact.postalAddress {
            result["countryCode"] = address.isoCountryCode.uppercased()
            result["postalCode"] = address.postalCode
            result["locality"] = address.city
            result["administrativeArea"] = address.state
            result["addressLines"] = address.street.components(separatedBy: .newlines).filter { !$0.isEmpty }
        }
        result["givenName"] = contact.name?.givenName
        result["familyName"] = contact.name?.familyName
        result["emailAddress"] = contact.emailAddress
        result["phoneNumber"] = contact.phoneNumber?.stringValue
        return result
    }
}
