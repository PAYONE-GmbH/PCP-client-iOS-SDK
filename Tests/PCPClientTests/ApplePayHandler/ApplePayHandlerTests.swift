import PassKit
@testable import PCPClient
import XCTest

final class ApplePayHandlerTests: XCTestCase {
    private func makeHandler() -> (ApplePayHandler, SheetStub) {
        let handler = ApplePayHandler()
        let controller = SheetStub()
        handler.controllerFactory = { _ in controller }
        return (handler, controller)
    }

    private func start(_ handler: ApplePayHandler, completion: @escaping (Bool) -> Void = { _ in }) {
        let request = PKPaymentRequest()
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Total", amount: 10)]
        handler.startPayment(request: request, onDidSelectPaymentMethod: { _ in
            PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: request.paymentSummaryItems)
        }, completion: completion)
    }

    func testCancellationCompletesOnceAndDismisses() {
        let (handler, sheet) = makeHandler()
        var results: [Bool] = []
        var statuses: [ApplePayCompletionStatus] = []
        handler.didFinish = { statuses.append($0) }
        start(handler) { results.append($0) }
        handler.paymentAuthorizationControllerDidFinish(sheet)
        handler.paymentAuthorizationControllerDidFinish(sheet)
        XCTAssertEqual(results, [false])
        XCTAssertEqual(statuses, [.cancelled])
        XCTAssertEqual(sheet.dismissCount, 1)
    }

    func testSuccessfulSessionDoesNotLeakIntoNextCancellation() {
        let (handler, sheet) = makeHandler()
        var statuses: [ApplePayCompletionStatus] = []
        handler.didFinish = { statuses.append($0) }
        handler.authorizePayment = { _, reply in reply(PKPaymentAuthorizationResult(status: .success, errors: nil)) }
        start(handler)
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: PKPayment()) { result in
            XCTAssertEqual(result.status, .success)
        }
        handler.paymentAuthorizationControllerDidFinish(sheet)
        start(handler)
        handler.paymentAuthorizationControllerDidFinish(sheet)
        XCTAssertEqual(statuses, [.success, .cancelled])
    }

    func testDuplicateAuthorizationRepliesAreIgnored() {
        let (handler, sheet) = makeHandler()
        handler.authorizePayment = { _, reply in
            reply(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            reply(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
        var calls = 0
        start(handler)
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: PKPayment()) { result in
            calls += 1
            XCTAssertEqual(result.status, .failure)
        }
        handler.didFinish = { XCTAssertEqual($0, .failure) }
        handler.paymentAuthorizationControllerDidFinish(sheet)
        XCTAssertEqual(calls, 1)
    }

    func testLateReplyCannotAffectNewSession() {
        let (handler, sheet) = makeHandler()
        var pending: ((PKPaymentAuthorizationResult) -> Void)?
        handler.authorizePayment = { _, reply in pending = reply }
        start(handler)
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: PKPayment()) { _ in XCTFail("Late reply") }
        handler.paymentAuthorizationControllerDidFinish(sheet)
        start(handler)
        pending?(PKPaymentAuthorizationResult(status: .success, errors: nil))
        handler.didFinish = { XCTAssertEqual($0, .cancelled) }
        handler.paymentAuthorizationControllerDidFinish(sheet)
    }

    func testAsyncContactPrecedesLegacyCallbackAndUpdatesRequest() {
        let (handler, sheet) = makeHandler()
        start(handler)
        handler.didSelectShippingContact = { _ in XCTFail("Legacy callback must not override async callback") }
        var pending: ((PKPaymentRequestShippingContactUpdate) -> Void)?
        handler.updateShippingContact = { _, reply in pending = reply }
        var calls = 0
        handler.paymentAuthorizationController(sheet, didSelectShippingContact: PKContact()) { update in
            calls += 1
            XCTAssertEqual(update.paymentSummaryItems.last?.amount, 25)
        }
        XCTAssertEqual(calls, 0)
        let update = PKPaymentRequestShippingContactUpdate(paymentSummaryItems: [PKPaymentSummaryItem(label: "Total", amount: 25)])
        pending?(update)
        pending?(update)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(handler.request?.paymentSummaryItems.last?.amount, 25)
    }

    func testAsyncMethodUpdatesCurrentSummaryAndIgnoresDuplicateReplies() {
        let (handler, sheet) = makeHandler()
        start(handler)
        handler.onShippingMethodDidChange = { _ in XCTFail("Legacy callback"); return PKPaymentRequestShippingMethodUpdate() }
        handler.updateShippingMethod = { _, reply in
            let update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [PKPaymentSummaryItem(label: "Total", amount: 30)])
            reply(update)
            reply(update)
        }
        var calls = 0
        handler.paymentAuthorizationController(sheet, didSelectShippingMethod: PKShippingMethod()) { _ in calls += 1 }
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(handler.request?.paymentSummaryItems.last?.amount, 30)
    }

    func testAuthorizationTimeoutAndBackgroundRepliesCompleteOnMain() {
        let (handler, sheet) = makeHandler()
        handler.callbackTimeout = 0.01
        handler.authorizePayment = { _, _ in }
        start(handler)
        let timeout = expectation(description: "timeout")
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: PKPayment()) { result in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(result.status, .failure)
            timeout.fulfill()
        }
        wait(for: [timeout], timeout: 1)
        handler.authorizePayment = { _, reply in
            DispatchQueue.global().async { reply(PKPaymentAuthorizationResult(status: .success, errors: nil)) }
        }
        handler.callbackTimeout = 1
        let background = expectation(description: "background")
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: PKPayment()) { result in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(result.status, .success)
            background.fulfill()
        }
        wait(for: [background], timeout: 2)
    }

    func testMissingOptionalCallbacksStillCompletePassKitUpdates() {
        let (handler, sheet) = makeHandler()
        start(handler)
        handler.onDidSelectPaymentMethod = nil
        var calls = 0
        handler.paymentAuthorizationController(sheet, didSelectShippingMethod: PKShippingMethod()) { _ in calls += 1 }
        handler.paymentAuthorizationController(sheet, didSelectShippingContact: PKContact()) { _ in calls += 1 }
        handler.paymentAuthorizationController(sheet, didSelectPaymentMethod: PKPaymentMethod()) { _ in calls += 1 }
        handler.paymentAuthorizationController(sheet, didChangeCouponCode: "CODE") { _ in calls += 1 }
        XCTAssertEqual(calls, 4)
    }

    func testSynchronousShippingAndCouponCallbacksRemainAvailable() {
        let (handler, sheet) = makeHandler()
        start(handler)
        let methodUpdate = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [])
        handler.onShippingMethodDidChange = { _ in methodUpdate }
        handler.paymentAuthorizationController(sheet, didSelectShippingMethod: PKShippingMethod()) { XCTAssertTrue($0 === methodUpdate) }
        let couponUpdate = PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: [])
        handler.onChangeCouponCode = { code in XCTAssertEqual(code, "CODE"); return couponUpdate }
        handler.paymentAuthorizationController(sheet, didChangeCouponCode: "CODE") { XCTAssertTrue($0 === couponUpdate) }
    }

    func testConcurrentStartDoesNotReplaceCheckout() {
        let (handler, sheet) = makeHandler()
        var first: [Bool] = []
        start(handler) { first.append($0) }
        start(handler) { XCTAssertFalse($0) }
        XCTAssertTrue(first.isEmpty)
        handler.paymentAuthorizationControllerDidFinish(sheet)
        XCTAssertEqual(first, [false])
    }

    func testUnrelatedControllerCannotInvokeMerchantUpdatesOrMutateCurrentRequest() {
        let (handler, _) = makeHandler()
        start(handler)
        handler.updateShippingContact = { _, _ in XCTFail("Unrelated contact event") }
        handler.updateShippingMethod = { _, _ in XCTFail("Unrelated shipping event") }
        handler.onChangeCouponCode = { _ in XCTFail("Unrelated coupon event"); return PKPaymentRequestCouponCodeUpdate() }
        handler.onDidSelectPaymentMethod = { _ in XCTFail("Unrelated card event"); return PKPaymentRequestPaymentMethodUpdate() }
        let unrelated = SheetStub()
        var replies = 0
        handler.paymentAuthorizationController(unrelated, didSelectShippingContact: PKContact()) { _ in replies += 1 }
        handler.paymentAuthorizationController(unrelated, didSelectShippingMethod: PKShippingMethod()) { _ in replies += 1 }
        handler.paymentAuthorizationController(unrelated, didChangeCouponCode: "CODE") { _ in replies += 1 }
        handler.paymentAuthorizationController(unrelated, didSelectPaymentMethod: PKPaymentMethod()) { _ in replies += 1 }
        XCTAssertEqual(replies, 4)
        XCTAssertEqual(handler.request?.paymentSummaryItems.last?.amount, 10)
    }

    func testCardAndCouponUpdatesRemainAuthoritativeForLaterFallbacksAndAreReleasedOnFinish() {
        let (handler, sheet) = makeHandler()
        start(handler)
        handler.onDidSelectPaymentMethod = { _ in
            PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: [PKPaymentSummaryItem(label: "Total", amount: 20)])
        }
        handler.paymentAuthorizationController(sheet, didSelectPaymentMethod: PKPaymentMethod()) { _ in }
        handler.paymentAuthorizationController(sheet, didSelectShippingMethod: PKShippingMethod()) {
            XCTAssertEqual($0.paymentSummaryItems.last?.amount, 20)
        }
        handler.onChangeCouponCode = { _ in
            PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: [PKPaymentSummaryItem(label: "Total", amount: 15)])
        }
        handler.paymentAuthorizationController(sheet, didChangeCouponCode: "CODE") { _ in }
        handler.paymentAuthorizationController(sheet, didSelectShippingMethod: PKShippingMethod()) {
            XCTAssertEqual($0.paymentSummaryItems.last?.amount, 15)
        }
        handler.paymentAuthorizationControllerDidFinish(sheet)
        XCTAssertNil(handler.request)
        XCTAssertNil(handler.paymentController)
        XCTAssertNil(handler.onDidSelectPaymentMethod)
    }

    func testPresentationFailureFinishesWithFailure() {
        let (handler, sheet) = makeHandler()
        sheet.presented = false
        let done = expectation(description: "presentation failed")
        handler.didFinish = { XCTAssertEqual($0, .failure); done.fulfill() }
        start(handler) { XCTAssertFalse($0) }
        wait(for: [done], timeout: 1)
    }

    func testDefaultTransportRejectsMalformedToken() {
        let (handler, sheet) = makeHandler()
        start(handler)
        handler.paymentAuthorizationController(sheet, didAuthorizePayment: PKPayment()) {
            XCTAssertEqual($0.status, .failure)
        }
    }

    func testDefaultTransportRequiresHTTPAndBusinessSuccessAndSendsJSONToken() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ApplePayTransportStub.self]
        let session = URLSession(configuration: configuration)
        for (status, response, expected) in [(200, "{\"success\":true}", true), (500, "{\"success\":true}", false),
                                             (200, "{\"success\":false}", false), (200, "{}", false), (200, "", false),
                                             (200, "{\"success\":1}", false), (-1, "", false)] {
            ApplePayTransportStub.status = status
            ApplePayTransportStub.body = Data(response.utf8)
            let handler = ApplePayHandler(processPaymentServerUrl: URL(string: "https://example.test/pay")!, urlSession: session)
            let sheet = SheetStub()
            handler.controllerFactory = { _ in sheet }
            start(handler)
            let done = expectation(description: "transport")
            handler.paymentAuthorizationController(sheet, didAuthorizePayment: PaymentStub()) {
                XCTAssertEqual($0.status == .success, expected)
                done.fulfill()
            }
            wait(for: [done], timeout: 2)
            let data = try XCTUnwrap(ApplePayTransportStub.requestBody)
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let token = try XCTUnwrap(body["token"] as? [String: Any])
            XCTAssertNotNil(token["paymentData"] as? [String: Any])
            handler.paymentAuthorizationControllerDidFinish(sheet)
        }
    }
}

private final class SheetStub: PKPaymentAuthorizationController {
    var dismissCount = 0
    var presented = true
    override func present(completion: ((Bool) -> Void)? = nil) { completion?(presented) }
    override func dismiss(completion: (() -> Void)? = nil) { dismissCount += 1; completion?() }
}

private final class PaymentStub: PKPayment {
    override var token: PKPaymentToken { TokenStub() }
}
private final class TokenStub: PKPaymentToken {
    override var paymentData: Data { Data("{\"version\":\"EC_v1\",\"data\":\"synthetic\"}".utf8) }
}

private final class ApplePayTransportStub: URLProtocol {
    static var status = 200
    static var body = Data()
    static var requestBody: Data?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        if Self.status == -1 {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        if let data = request.httpBody { Self.requestBody = data }
        else if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
            Self.requestBody = data
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                                           httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
