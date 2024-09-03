//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import PassKit
@testable import PCPClient
import XCTest

// swiftlint:disable type_body_length line_length
internal final class ApplePayHandlerTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional
    private var sut: ApplePayHandler!
    // swiftlint:enable implicitly_unwrapped_optional

    // MARK: - Test Lifecycle

    override internal func setUp() {
        super.setUp()

        // swiftlint:disable:next force_unwrapping
        sut = ApplePayHandler(processPaymentServerUrl: URL(string: "https://some-server-for-payment.com")!)
    }

    override internal func tearDown() {
        URLProtocolStub.invokedURLRequests = []
        URLProtocolStub.expectedResult = nil
        URLProtocolStub.expectation = nil
        super.tearDown()
    }

    // MARK: - Tests

    internal func test_supportApplePay_withNoRequest_returnsControllerCanMakePaymentsResult() {
        let expectedResult = PKPaymentAuthorizationController.canMakePayments()

        XCTAssertEqual(sut.supportsApplePay(), expectedResult)
    }

    internal func test_supportApplePay_withRequest_returnsTrueWhenControllerCanMakePaymentsAndUsingNetworksAndCapabilitiesIsTrue() {
        let request = PKPaymentRequest()
        request.supportedNetworks = [.amex, .visa]
        request.merchantCapabilities = .threeDSecure
        let expectedResult = PKPaymentAuthorizationController.canMakePayments() && PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: [.amex, .visa],
            capabilities: .threeDSecure
        )

        XCTAssertEqual(sut.supportsApplePay(), expectedResult)
    }

    internal func test_startPayment_withRequest_setsRequestCorrectly() {
        let request = PKPaymentRequest()

        sut.startPayment(
            request: request,
            onDidSelectPaymentMethod: { _ in
                PKPaymentRequestPaymentMethodUpdateMock()
            },
            completion: { _ in
                XCTFail("Unexpected completion call.")
            }
        )

        XCTAssertEqual(sut.request, request)
    }

    internal func test_paymentAuthorizationControllerDidFinish_dismissesController() {
        let controller = PKPaymentAuthorizationControllerMock()

        sut.paymentAuthorizationControllerDidFinish(controller)

        XCTAssertEqual(controller.invokedDismissCount, 1)
    }

    internal func test_didSelectShippingMethod_withNoOnShippingMethodDidChangeClosure_completesWithFalse() {
        var completionCalledValues = [Bool]()
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []) },
            completion: { completionCalledValues.append($0) }
        )

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: PKShippingMethod(label: "Free", amount: .zero),
            handler: { _ in
                XCTFail("Unexpected completion call.")
            }
        )

        XCTAssertEqual(completionCalledValues, [false])
    }

    internal func test_didSelectShippingMethod_withOnShippingMethodDidChangeClosure_callsThatCompletionWithShippingMethod() {
        var completionCalledValues = [Bool]()
        var shippingMethodCompletionHandlerCallCount = 0
        let expectedShippingMethodUpdate = PKPaymentRequestShippingMethodUpdateMock()
        let expectedShippingMethod = PKShippingMethod(label: "Free", amount: .zero)
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []) },
            completion: { completionCalledValues.append($0) }
        )
        sut.onShippingMethodDidChange = { newShippingMethod in
            XCTAssertEqual(newShippingMethod, expectedShippingMethod)
            return expectedShippingMethodUpdate
        }

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: expectedShippingMethod,
            handler: { returnedUpdate in
                shippingMethodCompletionHandlerCallCount += 1
                XCTAssertEqual(returnedUpdate, expectedShippingMethodUpdate)
            }
        )

        XCTAssert(completionCalledValues.isEmpty)
        XCTAssertEqual(shippingMethodCompletionHandlerCallCount, 1)
    }

    internal func test_didSelectShippingContact_withNoRequest_completesWithFalse() {
        var completionCalledValues = [Bool]()
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []) },
            completion: { completionCalledValues.append($0) }
        )
        sut.request = nil

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: PKContact(),
            handler: { _ in
                XCTFail("Unexpected completion call.")
            }
        )

        XCTAssertEqual(completionCalledValues, [false])
    }

    internal func test_didSelectShippingContact_withDidSelectShippingContactClosure_callsThatCompletion() {
        var completionCalledValues = [Bool]()
        var selectShippingContactCompletionHandlerCallCount = 0
        let expectedContact = PKContact()
        let previousItems = [
            PKPaymentSummaryItem(label: "First", amount: .one),
            PKPaymentSummaryItem(label: "Second", amount: .init(decimal: Decimal(2)))
        ]
        let request = PKPaymentRequest()
        request.paymentSummaryItems = previousItems
        sut.startPayment(
            request: request,
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: previousItems) },
            completion: { completionCalledValues.append($0) }
        )
        sut.didSelectShippingContact = { shippingContact in
            XCTAssertEqual(shippingContact, expectedContact)
        }

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: expectedContact,
            handler: { returnedUpdate in
                selectShippingContactCompletionHandlerCallCount += 1
                XCTAssertEqual(returnedUpdate.paymentSummaryItems, previousItems)
            }
        )

        XCTAssert(completionCalledValues.isEmpty)
        XCTAssertEqual(selectShippingContactCompletionHandlerCallCount, 1)
    }

    internal func test_didChangeCouponCode_withNoChangeCouponCodeClosure_completesWithFalse() {
        var completionCalledValues = [Bool]()
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []) },
            completion: { completionCalledValues.append($0) }
        )

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didChangeCouponCode: "newCouponCode",
            handler: { _ in
                XCTFail("Unexpected completion call.")
            }
        )

        XCTAssertEqual(completionCalledValues, [false])
    }

    internal func test_didChangeCouponCode_withOnChangeCouponCodeClosure_callsThatCompletion() {
        var completionCalledValues = [Bool]()
        var couponCodeCompletionHandlerCallCount = 0
        let expectedCouponCodeUpdate = PKPaymentRequestCouponCodeUpdateMock()
        let expectedCouponCode = "newCouponCode"
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []) },
            completion: { completionCalledValues.append($0) }
        )
        sut.onChangeCouponCode = { newCouponCode in
            XCTAssertEqual(newCouponCode, expectedCouponCode)
            return expectedCouponCodeUpdate
        }

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didChangeCouponCode: "newCouponCode",
            handler: { returnedUpdate in
                couponCodeCompletionHandlerCallCount += 1
                XCTAssertEqual(returnedUpdate, expectedCouponCodeUpdate)
            }
        )

        XCTAssert(completionCalledValues.isEmpty)
        XCTAssertEqual(couponCodeCompletionHandlerCallCount, 1)
    }

    internal func test_didSelectPaymentMethod_withNoOnDidSelectPaymentMethodClosure_completesWithFalse() {
        var completionCalledValues = [Bool]()
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []) },
            completion: { completionCalledValues.append($0) }
        )
        sut.onDidSelectPaymentMethod = nil

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectPaymentMethod: PKPaymentMethod(),
            handler: { _ in
                XCTFail("Unexpected completion call.")
            }
        )

        XCTAssertEqual(completionCalledValues, [false])
    }

    internal func test_didSelectPaymentMethod_withOnDidSelectPaymentMethodClosure_callsThatCompletion() {
        var completionCalledValues = [Bool]()
        var paymentMethodCompletionHandlerCallCount = 0
        let expectedUpdate = PKPaymentRequestPaymentMethodUpdateMock()
        let expectedPaymentMethod = PKPaymentMethod()
        sut.startPayment(
            request: PKPaymentRequest(),
            onDidSelectPaymentMethod: { paymentMethod in
                XCTAssertEqual(paymentMethod, expectedPaymentMethod)
                return expectedUpdate
            },
            completion: { completionCalledValues.append($0) }
        )

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectPaymentMethod: expectedPaymentMethod,
            handler: { returnedUpdate in
                paymentMethodCompletionHandlerCallCount += 1
                XCTAssertEqual(returnedUpdate, expectedUpdate)
            }
        )

        XCTAssert(completionCalledValues.isEmpty)
        XCTAssertEqual(paymentMethodCompletionHandlerCallCount, 1)
    }

    internal func test_didAuthorizePayment_sendsCorrectNetworkRequest() throws {
        let expectation = expectation(description: #function)
        URLProtocolStub.expectation = expectation
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let expectedUrlString = "https://some-expected-url-for-this-test.com"
        // swiftlint:disable:next force_unwrapping
        let sut = ApplePayHandler(processPaymentServerUrl: URL(string: expectedUrlString)!, urlSession: session)
        let paymentRequest = PKPaymentRequest()
        paymentRequest.countryCode = "DE"
        paymentRequest.currencyCode = "EUR"
        sut.startPayment(
            request: paymentRequest,
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate() },
            completion: { _ in
                XCTFail("Unexpected completion call.")
            }
        )

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didAuthorizePayment: PKPayment(),
            handler: { _ in
                // Not needed
            }
        )

        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(URLProtocolStub.invokedURLRequests.count, 1)
        let request = try XCTUnwrap(URLProtocolStub.invokedURLRequests.first)
        XCTAssertEqual(request.url?.absoluteString, expectedUrlString)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpMethod, "POST")
        // We can't check for the data since it's cleared before going to the URLProtocol methods.
    }

    internal func test_didAuthorizePayment_handlesDataResultCorrectly() throws {
        let expectation = expectation(description: #function)
        URLProtocolStub.expectation = expectation
        URLProtocolStub.expectedResult = {
            (Data("Some text".utf8), nil)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let expectedUrlString = "https://some-expected-url-for-this-test.com"
        // swiftlint:disable:next force_unwrapping
        let sut = ApplePayHandler(processPaymentServerUrl: URL(string: expectedUrlString)!, urlSession: session)
        let paymentRequest = PKPaymentRequest()
        paymentRequest.countryCode = "DE"
        paymentRequest.currencyCode = "EUR"
        sut.startPayment(
            request: paymentRequest,
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate() },
            completion: { result in
                XCTAssert(result)
            }
        )

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didAuthorizePayment: PKPayment(),
            handler: { result in
                XCTAssertEqual(result.status, .success)
            }
        )

        wait(for: [expectation], timeout: 3.0)
    }

    internal func test_didAuthorizePayment_handlesErrorResultCorrectly() throws {
        let expectation = expectation(description: #function)
        URLProtocolStub.expectation = expectation
        URLProtocolStub.expectedResult = {
            (nil, FakeError.test)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let expectedUrlString = "https://some-expected-url-for-this-test.com"
        // swiftlint:disable:next force_unwrapping
        let sut = ApplePayHandler(processPaymentServerUrl: URL(string: expectedUrlString)!, urlSession: session)
        let paymentRequest = PKPaymentRequest()
        paymentRequest.countryCode = "DE"
        paymentRequest.currencyCode = "EUR"
        sut.startPayment(
            request: paymentRequest,
            onDidSelectPaymentMethod: { _ in PKPaymentRequestPaymentMethodUpdate() },
            completion: { result in
                XCTAssertFalse(result)
            }
        )

        sut.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didAuthorizePayment: PKPayment(),
            handler: { result in
                XCTAssertEqual(result.status, .failure)
            }
        )

        wait(for: [expectation], timeout: 3.0)
    }
}
// swiftlint:enable type_body_length line_length
