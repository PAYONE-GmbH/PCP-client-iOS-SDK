import Contacts
import PassKit
@testable import PCPClient
import XCTest

final class ApplePayDemoCheckoutTests: XCTestCase {
    private func fixture(method: String = "standard", supported: Bool = true) -> [String: Any] {
        let shipping = supported ? (method == "express" ? "9.90" : "4.90") : "0.00"
        return [
            "cartId": "demo-cart-1", "currencyCode": "EUR",
            "quoteId": supported ? "quote-\(method)" as Any : NSNull(),
            "expiresAt": supported ? "2099-01-01T00:00:00.000Z" as Any : NSNull(),
            "shippingMethods": supported ? [
                ["identifier": "standard", "label": "Standard", "detail": "2 Tage", "amount": "4.90"],
                ["identifier": "express", "label": "Express", "detail": "1 Tag", "amount": "9.90"]
            ] : [],
            "selectedShippingMethodIdentifier": supported ? method as Any : NSNull(),
            "lineItems": [["label": "Artikel", "amount": "19.90"], ["label": "Versand", "amount": shipping]],
            "total": ["label": "Demo", "amount": supported ? (method == "express" ? "29.80" : "24.80") : "19.90"],
            "errors": supported ? [] : [["code": "shippingContactInvalid", "field": "countryCode", "message": "Nur Deutschland"]]
        ]
    }

    private func makeCheckout(
        configuration: ApplePayDemoConfiguration = ApplePayDemoConfiguration(
            merchantIdentifier: "merchant.de.nanogiants.payonedemo", baseURL: URL(string: "https://example.test")!,
            cartID: "demo-cart-1", countryCode: "DE", currencyCode: "EUR", initialShippingMethodIdentifier: "standard"
        ),
        standardOrder: ApplePayDemoStandardOrder? = nil
    ) -> (ApplePayDemoCheckout, ApplePayHandler, DemoSheetStub) {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DemoURLProtocol.self]
        let handler = ApplePayHandler()
        let sheet = DemoSheetStub()
        handler.controllerFactory = { request in sheet.capturedRequest = request; return sheet }
        let checkout = ApplePayDemoCheckout(configuration: configuration,
                                            session: URLSession(configuration: config), handler: handler,
                                            standardOrder: standardOrder)
        return (checkout, handler, sheet)
    }

    override func tearDown() { DemoURLProtocol.respond = nil; DemoURLProtocol.requestURLs = []; super.tearDown() }

    func testStandardUsesPrecollectedOrderAndFixedShippingWithoutExpressCallbacks() throws {
        _ = try XCTUnwrap(Bundle.module.url(forResource: "ApplePayDemoStandardOrder", withExtension: "plist"))
        let order = try ApplePayDemoStandardOrder.load(from: .module)
        let (checkout, handler, sheet) = makeCheckout(standardOrder: order)
        let presented = expectation(description: "standard sheet")
        sheet.onPresent = { presented.fulfill() }
        let finished = expectation(description: "standard receipt")
        var quoteCalls = 0
        DemoURLProtocol.respond = { path, body in
            XCTAssertEqual(body["shippingMethodIdentifier"] as? String, order.shippingMethodIdentifier)
            let shipping = body["shippingContact"] as? [String: Any]
            XCTAssertEqual(shipping?["addressLines"] as? [String], ["Teststraße 1"])
            if path == "/checkout/quote" {
                quoteCalls += 1
                return (200, self.fixture(), 0)
            }
            XCTAssertEqual(path, "/process-payment")
            XCTAssertEqual((body["billingContact"] as? [String: Any])?["addressLines"] as? [String], ["Teststraße 2"])
            return (200, self.receipt(), 0)
        }
        checkout.start { XCTAssertTrue($0.contains("Simulierter Checkout erfolgreich")); finished.fulfill() }
        wait(for: [presented], timeout: 2)
        let request = try XCTUnwrap(sheet.capturedRequest)
        XCTAssertTrue(request.requiredShippingContactFields.isEmpty)
        XCTAssertTrue(request.requiredBillingContactFields.isEmpty)
        XCTAssertTrue(request.shippingMethods?.isEmpty != false)
        XCTAssertEqual(request.shippingContact?.postalAddress?.street, "Teststraße 1")
        XCTAssertEqual(request.billingContact?.postalAddress?.street, "Teststraße 2")
        XCTAssertEqual(request.paymentSummaryItems.last?.amount, NSDecimalNumber(string: "24.80"))
        XCTAssertNil(handler.updateShippingContact)
        XCTAssertNil(handler.updateShippingMethod)
        let authorized = expectation(description: "standard authorization")
        // No Wallet contacts: the standard order remains authoritative.
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: StandardPaymentStub()) {
            XCTAssertEqual($0.status, .success)
            authorized.fulfill()
        }
        wait(for: [authorized], timeout: 2)
        XCTAssertEqual(quoteCalls, 1)
        handler.paymentAuthorizationControllerDidFinish(sheet)
        wait(for: [finished], timeout: 1)
    }

    func testStandardCancellationAndFailureCanBeRetried() throws {
        let order = try ApplePayDemoStandardOrder.load(from: .module)
        let (checkout, handler, sheet) = makeCheckout(standardOrder: order)
        for status in [0, 409, 503, -1] {
            let presented = expectation(description: "standard attempt")
            sheet.onPresent = { presented.fulfill() }
            var paymentCalls = 0
            DemoURLProtocol.respond = { path, _ in
                if path == "/checkout/quote" { return (200, self.fixture(), 0) }
                paymentCalls += 1
                return (status, ["success": false], 0)
            }
            let finished = expectation(description: "standard cancel/error")
            checkout.start {
                XCTAssertFalse($0.contains("erfolgreich"))
                if status == 0 { XCTAssertTrue($0.contains("abgebrochen")) }
                finished.fulfill()
            }
            wait(for: [presented], timeout: 2)
            if status != 0 {
                let replied = expectation(description: "standard backend error")
                handler.paymentAuthorizationController(sheet, didAuthorizePayment: StandardPaymentStub()) {
                    XCTAssertEqual($0.status, .failure)
                    replied.fulfill()
                }
                wait(for: [replied], timeout: 2)
            }
            handler.paymentAuthorizationControllerDidFinish(sheet)
            wait(for: [finished], timeout: 1)
            XCTAssertEqual(paymentCalls, status == 0 ? 0 : 1)
        }
    }

    func testStandardRejectsIncompleteOrderBeforeNetworkAndUnexpectedShippingBeforePresentation() throws {
        let invalid = ApplePayDemoStandardOrder(shippingContact: PKContact(), billingContact: PKContact(), shippingMethodIdentifier: "standard")
        let (invalidCheckout, _, invalidSheet) = makeCheckout(standardOrder: invalid)
        invalidSheet.onPresent = { XCTFail("Incomplete order") }
        var invalidReported = false
        invalidCheckout.start { _ in invalidReported = true }
        XCTAssertTrue(invalidReported)
        XCTAssertTrue(DemoURLProtocol.requestURLs.isEmpty)

        let order = try ApplePayDemoStandardOrder.load(from: .module)
        let (checkout, _, sheet) = makeCheckout(standardOrder: order)
        sheet.onPresent = { XCTFail("Backend changed the standard order's shipping") }
        DemoURLProtocol.respond = { _, _ in (200, self.fixture(method: "express"), 0) }
        let failed = expectation(description: "shipping mismatch")
        checkout.start { XCTAssertFalse($0.contains("erfolgreich")); failed.fulfill() }
        wait(for: [failed], timeout: 2)
    }

    private func receipt() -> [String: Any] {
        ["success": true, "mode": "demo", "paymentStatus": "simulated", "orderId": "demo-order-standard",
         "quoteId": "quote-standard", "cartId": "demo-cart-1", "currencyCode": "EUR",
         "shippingMethodIdentifier": "standard", "total": ["label": "Demo", "amount": "24.80"]]
    }

    func testInjectedConfigurationControlsMerchantServerCartAndRegion() {
        let configuration = ApplePayDemoConfiguration(
            merchantIdentifier: "merchant.example.custom", baseURL: URL(string: "https://custom.example/api")!,
            cartID: "custom-cart", countryCode: "US", currencyCode: "USD", initialShippingMethodIdentifier: "express"
        )
        let (checkout, handler, sheet) = makeCheckout(configuration: configuration)
        var response = fixture(method: "express")
        response["cartId"] = "custom-cart"
        response["currencyCode"] = "USD"
        DemoURLProtocol.respond = { path, body in
            XCTAssertEqual(body["cartId"] as? String, "custom-cart")
            XCTAssertEqual(body["shippingMethodIdentifier"] as? String, "express")
            if path == "/api/checkout/quote" {
                XCTAssertEqual((body["shippingContact"] as? [String: Any])?["countryCode"] as? String, "US")
                return (200, response, 0)
            }
            XCTAssertEqual(path, "/api/process-payment")
            XCTAssertEqual(body["quoteId"] as? String, "quote-express")
            return (200, ["success": true, "mode": "demo", "paymentStatus": "simulated",
                          "orderId": "demo-order-custom", "quoteId": "quote-express", "cartId": "custom-cart",
                          "currencyCode": "USD", "shippingMethodIdentifier": "express",
                          "total": ["label": "Demo", "amount": "29.80"]], 0)
        }
        let presented = expectation(description: "custom request")
        sheet.onPresent = { presented.fulfill() }
        checkout.start { _ in }
        wait(for: [presented], timeout: 2)
        XCTAssertEqual(DemoURLProtocol.requestURLs, [URL(string: "https://custom.example/api/checkout/quote")!])
        XCTAssertEqual(sheet.capturedRequest?.merchantIdentifier, "merchant.example.custom")
        XCTAssertEqual(sheet.capturedRequest?.countryCode, "US")
        XCTAssertEqual(sheet.capturedRequest?.currencyCode, "USD")
        let authorized = expectation(description: "custom cart authorization")
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: DemoPaymentStub()) { result in
            XCTAssertEqual(result.status, .success)
            authorized.fulfill()
        }
        wait(for: [authorized], timeout: 2)
        XCTAssertEqual(DemoURLProtocol.requestURLs.last, URL(string: "https://custom.example/api/process-payment"))
        handler.paymentAuthorizationControllerDidFinish(sheet)
    }

    func testBundledExampleConfigurationLoadsAndMissingConfigurationFails() throws {
        let configuration = try ApplePayDemoConfiguration.load(from: .module)
        XCTAssertEqual(configuration.cartID, "demo-cart-1")
        XCTAssertEqual(configuration.currencyCode, "EUR")
        XCTAssertThrowsError(try ApplePayDemoConfiguration.load(from: Bundle(for: NSObject.self)))
    }

    func testExpressFlowSendsFinalContactsAndJSONTokenAndReportsSimulation() throws {
        let (checkout, handler, sheet) = makeCheckout()
        let started = expectation(description: "initial quote")
        let completed = expectation(description: "simulated checkout")
        sheet.onPresent = { started.fulfill() }
        var completionBody: [String: Any]?
        DemoURLProtocol.respond = { path, body in
            if path == "/checkout/quote" {
                XCTAssertEqual(body["cartId"] as? String, "demo-cart-1")
                return (200, self.fixture(method: body["shippingMethodIdentifier"] as? String ?? "standard"), 0)
            }
            completionBody = body
            return (200, ["success": true, "mode": "demo", "paymentStatus": "simulated", "orderId": "demo-order-1",
                          "quoteId": "quote-express", "cartId": "demo-cart-1", "currencyCode": "EUR",
                          "shippingMethodIdentifier": "express", "total": ["label": "Demo", "amount": "29.80"]], 0)
        }
        checkout.start {
            XCTAssertTrue($0.contains("Simulierter Checkout erfolgreich"))
            XCTAssertTrue($0.contains("Keine PAYONE-Zahlung"))
            completed.fulfill()
        }
        wait(for: [started], timeout: 2)
        XCTAssertEqual(sheet.capturedRequest?.merchantIdentifier, "merchant.de.nanogiants.payonedemo")
        XCTAssertEqual(sheet.capturedRequest?.paymentSummaryItems.last?.amount, NSDecimalNumber(string: "24.80"))
        XCTAssertTrue(sheet.capturedRequest?.requiredShippingContactFields.contains(.phoneNumber) == true)
        let partial = PKContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = "de"
        address.postalCode = "101"
        partial.postalAddress = address
        let updatedContact = expectation(description: "partial contact")
        handler.paymentAuthorizationController(sheet, didSelectShippingContact: partial) { update in
            XCTAssertTrue(update.errors?.isEmpty != false)
            updatedContact.fulfill()
        }
        wait(for: [updatedContact], timeout: 2)
        let method = PKShippingMethod(label: "Express", amount: NSDecimalNumber(string: "9.90"))
        method.identifier = "express"
        let updatedMethod = expectation(description: "express quote")
        handler.paymentAuthorizationController(sheet, didSelectShippingMethod: method) { update in
            XCTAssertEqual(update.paymentSummaryItems.last?.amount, NSDecimalNumber(string: "29.80"))
            updatedMethod.fulfill()
        }
        wait(for: [updatedMethod], timeout: 2)
        let authorized = expectation(description: "authorized simulation")
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: DemoPaymentStub()) { result in
            XCTAssertEqual(result.status, .success)
            authorized.fulfill()
        }
        wait(for: [authorized], timeout: 2)
        handler.paymentAuthorizationControllerDidFinish(sheet)
        wait(for: [completed], timeout: 2)
        let body = try XCTUnwrap(completionBody)
        XCTAssertEqual(body["quoteId"] as? String, "quote-express")
        let token = try XCTUnwrap(body["token"] as? [String: Any])
        let paymentData = try XCTUnwrap(token["paymentData"] as? [String: Any])
        XCTAssertEqual(paymentData["signature"] as? String, "synthetic-signature")
        XCTAssertEqual((token["paymentMethod"] as? [String: String])?["network"], PKPaymentNetwork.visa.rawValue)
        XCTAssertEqual(token["transactionIdentifier"] as? String, "test-transaction")
        let shipping = try XCTUnwrap(body["shippingContact"] as? [String: Any])
        XCTAssertEqual(shipping["postalCode"] as? String, "10115")
        XCTAssertEqual(shipping["addressLines"] as? [String], ["Teststraße 1", "Hinterhaus"])
        XCTAssertEqual(shipping["givenName"] as? String, "Demo")
        XCTAssertNotNil(body["billingContact"] as? [String: Any])
    }

    func testUnsupportedCountryInvalidatesQuoteAndPreventsCompletionRequest() {
        let (checkout, handler, sheet) = makeCheckout()
        let started = expectation(description: "started")
        sheet.onPresent = { started.fulfill() }
        var unsupported = false
        DemoURLProtocol.respond = { path, _ in
            XCTAssertEqual(path, "/checkout/quote", "No payment POST with an invalid quote")
            return (200, self.fixture(supported: !unsupported), 0)
        }
        checkout.start { _ in }
        wait(for: [started], timeout: 2)
        unsupported = true
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = "US"
        contact.postalAddress = address
        let updated = expectation(description: "country error")
        handler.paymentAuthorizationController(sheet, didSelectShippingContact: contact) {
            XCTAssertEqual($0.errors?.count, 1)
            XCTAssertTrue($0.shippingMethods.isEmpty)
            updated.fulfill()
        }
        wait(for: [updated], timeout: 2)
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: DemoPaymentStub()) { XCTAssertEqual($0.status, .failure) }
        handler.paymentAuthorizationControllerDidFinish(sheet)
    }

    func testHTTPConflictAndBusinessFailureAreNotSuccess() {
        for status in [200, 409, 503, -1] {
            let (checkout, handler, sheet) = makeCheckout()
            let started = expectation(description: "started")
            sheet.onPresent = { started.fulfill() }
            DemoURLProtocol.respond = { path, _ in
                path == "/checkout/quote" ? (200, self.fixture(), 0) : (status, ["success": false], 0)
            }
            let finished = expectation(description: "failure")
            checkout.start { XCTAssertFalse($0.contains("erfolgreich")); finished.fulfill() }
            wait(for: [started], timeout: 2)
            let replied = expectation(description: "failure reply")
            handler.paymentAuthorizationController(sheet, didAuthorizePayment: DemoPaymentStub()) {
                XCTAssertEqual($0.status, .failure)
                replied.fulfill()
            }
            wait(for: [replied], timeout: 2)
            handler.paymentAuthorizationControllerDidFinish(sheet)
            wait(for: [finished], timeout: 2)
        }
    }

    func testStaleQuoteCannotReplaceNewerQuote() {
        let (checkout, _, _) = makeCheckout()
        let firstReceived = expectation(description: "first received")
        var count = 0
        DemoURLProtocol.respond = { _, _ in
            count += 1
            if count == 1 { firstReceived.fulfill(); return (200, self.fixture(), 0.1) }
            return (200, self.fixture(method: "express"), 0)
        }
        let stale = expectation(description: "stale")
        checkout.fetchQuote { result in
            if case .success = result { XCTFail("Stale quote accepted") }
            stale.fulfill()
        }
        wait(for: [firstReceived], timeout: 1)
        let latest = expectation(description: "latest")
        checkout.fetchQuote { result in
            XCTAssertEqual(try? result.get().selectedShippingMethodIdentifier, "express")
            latest.fulfill()
        }
        wait(for: [latest, stale], timeout: 2)
    }

    func testExpiredQuoteInvalidAmountsAndMismatchedReceiptAreRejected() throws {
        var json = fixture()
        json["expiresAt"] = "2024-01-01T00:00:00.000Z"
        let expired = try JSONDecoder().decode(DemoQuote.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(expired.isUsable)
        json = fixture()
        json["total"] = ["label": "Wrong", "amount": "0.01"]
        let wrong = try JSONDecoder().decode(DemoQuote.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(wrong.isUsable)
        let receiptData: [String: Any] = ["success": true, "mode": "demo", "paymentStatus": "simulated",
            "orderId": "demo-order-1", "quoteId": "other-quote", "cartId": "demo-cart-1", "currencyCode": "EUR",
            "shippingMethodIdentifier": "standard", "total": ["label": "Total", "amount": "24.80"]]
        let receipt = try JSONDecoder().decode(DemoReceipt.self, from: JSONSerialization.data(withJSONObject: receiptData))
        let quote = try JSONDecoder().decode(DemoQuote.self, from: JSONSerialization.data(withJSONObject: fixture()))
        XCTAssertFalse(receipt.matches(quote))
    }

    func testCancelAllowsAnotherCheckoutAndInitialNetworkFailureDoesNotPresent() {
        let (checkout, handler, sheet) = makeCheckout()
        DemoURLProtocol.respond = { _, _ in (200, self.fixture(), 0) }
        for _ in 0..<2 {
            let started = expectation(description: "started")
            sheet.onPresent = { started.fulfill() }
            let finished = expectation(description: "cancelled")
            checkout.start { XCTAssertTrue($0.contains("abgebrochen")); finished.fulfill() }
            wait(for: [started], timeout: 2)
            handler.paymentAuthorizationControllerDidFinish(sheet)
            wait(for: [finished], timeout: 1)
        }
        DemoURLProtocol.respond = { _, _ in (503, [:], 0) }
        sheet.onPresent = { XCTFail("Must not present after initial error") }
        let error = expectation(description: "initial error")
        checkout.start { XCTAssertTrue($0.contains("503")); error.fulfill() }
        wait(for: [error], timeout: 2)
    }
}

private final class DemoSheetStub: PKPaymentAuthorizationController {
    var capturedRequest: PKPaymentRequest?
    var onPresent: (() -> Void)?
    override func present(completion: ((Bool) -> Void)? = nil) { completion?(true); onPresent?() }
    override func dismiss(completion: (() -> Void)? = nil) { completion?() }
}

private final class DemoPaymentStub: PKPayment {
    override var token: PKPaymentToken { DemoTokenStub() }
    override var shippingContact: PKContact? {
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = "DE"
        address.postalCode = "10115"
        address.street = "Teststraße 1\nHinterhaus"
        address.city = "Berlin"
        contact.postalAddress = address
        var name = PersonNameComponents()
        name.givenName = "Demo"
        name.familyName = "Test"
        contact.name = name
        contact.emailAddress = "demo@example.com"
        contact.phoneNumber = CNPhoneNumber(stringValue: "+49300000000")
        return contact
    }
    override var billingContact: PKContact? { shippingContact }
}
private final class DemoTokenStub: PKPaymentToken {
    override var paymentMethod: PKPaymentMethod { DemoNetworkMethod() }
    override var transactionIdentifier: String { "test-transaction" }
    override var paymentData: Data {
        Data(#"{"version":"EC_v1","data":"synthetic-data","signature":"synthetic-signature","header":{"ephemeralPublicKey":"key","publicKeyHash":"hash","transactionId":"id"}}"#.utf8)
    }
}

private final class DemoNetworkMethod: PKPaymentMethod {
    override var network: PKPaymentNetwork? { .visa }
}

private final class StandardPaymentStub: PKPayment {
    override var token: PKPaymentToken { DemoTokenStub() }
    override var shippingContact: PKContact? { nil }
    override var billingContact: PKContact? { nil }
}

private final class DemoURLProtocol: URLProtocol {
    static var respond: ((String, [String: Any]) -> (Int, [String: Any], TimeInterval))?
    static var requestURLs: [URL] = []
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requestURLs.append(request.url!)
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
        }
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let (status, body, delay) = Self.respond?(request.url!.path, object) ?? (500, [:], 0)
        if status == -1 {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.client?.urlProtocol(self, didReceive: HTTPURLResponse(url: self.request.url!, statusCode: status,
                                      httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: body))
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {}
}
