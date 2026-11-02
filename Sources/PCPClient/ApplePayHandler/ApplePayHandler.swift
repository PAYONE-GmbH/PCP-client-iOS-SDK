//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import PassKit

/// Presents native Apple Pay Standard or Express using the supplied PKPaymentRequest.
/// Standard uses precollected order data; Express adds asynchronous contact/shipping callbacks.
/// Configure and start on main. Async reply blocks may be called from any queue;
/// the handler delivers them to PassKit once, on main, with a 25-second fallback.
@objc public class ApplePayHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    public typealias ShippingContactCompletion = (PKPaymentRequestShippingContactUpdate) -> Void
    public typealias ShippingMethodCompletion = (PKPaymentRequestShippingMethodUpdate) -> Void

    /// The current sheet controller. Observe only; do not replace it during checkout.
    @objc public var paymentController: PKPaymentAuthorizationController?
    /// Observes each authorization attempt after its PassKit reply, not the final dismissal.
    @objc public var didAuthorizePayment: ((PKPaymentAuthorizationResult) -> Void)?
    /// Legacy synchronous notification. Use updateShippingContact for asynchronous recalculation.
    @objc public var didSelectShippingContact: ((PKContact) -> Void)?
    /// Legacy synchronous shipping update. Overridden by updateShippingMethod when configured.
    @objc public var onShippingMethodDidChange: ((PKShippingMethod) -> PKPaymentRequestShippingMethodUpdate)?
    /// Synchronous card update. Replaced by the block supplied to each startPayment call.
    @objc public var onDidSelectPaymentMethod: ((PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate)?
    /// Synchronous coupon update. Asynchronous coupon recalculation is not supported by this callback.
    @objc public var onChangeCouponCode: ((String) -> PKPaymentRequestCouponCodeUpdate)?

    /// Async callbacks take precedence over their synchronous counterparts. Complete within 25 seconds.
    @objc public var updateShippingContact: ((PKContact, @escaping ShippingContactCompletion) -> Void)?
    /// Recalculate totals for the selected method. Takes precedence over onShippingMethodDidChange.
    @objc public var updateShippingMethod: ((PKShippingMethod, @escaping ShippingMethodCompletion) -> Void)?
    /// Submit the complete payment to your backend and return its authorization result.
    /// This overrides the URL-based transport, allowing arbitrary merchant backend contracts.
    @objc public var authorizePayment: ((PKPayment, @escaping (PKPaymentAuthorizationResult) -> Void) -> Void)?
    /// Final session result, after dismissal or failed presentation. Called once per accepted start.
    @objc public var didFinish: ((ApplePayCompletionStatus) -> Void)?

    private var paymentStatus: PKPaymentAuthorizationStatus = .failure
    private var attemptedAuthorization = false
    private var completion: ((Bool) -> Void)?
    private let transport: ApplePayPaymentTransport?
    private var sessionID: UUID?
    private var task: URLSessionDataTask?
    internal var request: PKPaymentRequest?
    internal var callbackTimeout: TimeInterval = 25
    internal var controllerFactory: (PKPaymentRequest) -> PKPaymentAuthorizationController = { request in
        PKPaymentAuthorizationController(paymentRequest: request)
    }

    /// Use with `authorizePayment` to implement your own backend contract.
    @objc override public init() {
        transport = nil
        super.init()
    }

    /// Default transport POSTs token.paymentData (JSON), paymentMethod and transactionIdentifier.
    /// Success requires HTTP 200 and a JSON object containing `success: true`.
    @objc public init(processPaymentServerUrl: URL, urlSession: URLSession = .shared) {
        transport = ApplePayPaymentTransport(url: processPaymentServerUrl, session: urlSession)
        super.init()
    }

    /// Checks device capability and, during checkout, the request's networks and capabilities.
    /// Before starting, use PassKit's network-aware check if the actual card eligibility is required.
    @objc public func supportsApplePay() -> Bool {
        guard let request else {
            return PKPaymentAuthorizationController.canMakePayments()
        }
        return PKPaymentAuthorizationController.canMakePayments() &&
            PKPaymentAuthorizationController.canMakePayments(
                usingNetworks: request.supportedNetworks, capabilities: request.merchantCapabilities
            )
    }

    /// Presents one session. The handler must be retained until completion.
    /// A concurrent start is rejected with false without replacing the active checkout or invoking didFinish.
    /// The Boolean observer runs immediately before didFinish; true means the final attempt succeeded.
    @objc public func startPayment(
        request: PKPaymentRequest,
        onDidSelectPaymentMethod: @escaping @convention(block) (PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate,
        completion: @escaping @convention(block) (Bool) -> Void
    ) {
        guard sessionID == nil else {
            completion(false)
            return
        }
        self.request = request
        self.completion = completion
        self.onDidSelectPaymentMethod = onDidSelectPaymentMethod
        paymentStatus = .failure
        attemptedAuthorization = false
        let identifier = UUID()
        sessionID = identifier
        let controller = controllerFactory(request)
        paymentController = controller
        controller.delegate = self
        controller.present { [weak self] presented in
            DispatchQueue.main.async {
                guard let self, self.sessionID == identifier, !presented else {
                    return
                }
                self.finish(.failure)
            }
        }
    }

    private func finish(_ status: ApplePayCompletionStatus) {
        guard sessionID != nil else {
            return
        }
        sessionID = nil
        task?.cancel()
        task = nil
        paymentController = nil
        request = nil
        onDidSelectPaymentMethod = nil
        let callback = completion
        let finishCallback = didFinish
        completion = nil
        callback?(status == .success)
        finishCallback?(status)
    }

    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        guard controller === paymentController, let identifier = sessionID else {
            return
        }
        let status: ApplePayCompletionStatus = paymentStatus == .success ? .success :
            (attemptedAuthorization ? .failure : .cancelled)
        controller.dismiss { [weak self] in
            guard self?.sessionID == identifier else {
                return
            }
            self?.finish(status)
        }
    }

    /// Ensures a callback completes once, on main, before PassKit's deadline. Late replies are ignored.
    private func reply<Value>(fallback: Value, completion: @escaping (Value) -> Void) -> (Value) -> Void {
        let identifier = sessionID
        var completed = false
        var timeout: DispatchWorkItem?
        let respond: (Value) -> Void = { [weak self] value in
            let deliver = {
                guard !completed else {
                    return
                }
                completed = true
                timeout?.cancel()
                timeout = nil
                guard let self, self.sessionID == identifier else {
                    return
                }
                completion(value)
            }
            if Thread.isMainThread { deliver() } else { DispatchQueue.main.async(execute: deliver) }
        }
        let work = DispatchWorkItem { respond(fallback) }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + callbackTimeout, execute: work)
        return respond
    }

    private var failure: PKPaymentAuthorizationResult {
        PKPaymentAuthorizationResult(status: .failure, errors: [
            NSError(
                domain: "PCPClient.ApplePay",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Payment could not be completed. Please retry."]
            )
        ])
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        guard controller === paymentController, sessionID != nil else {
            completion(failure)
            return
        }
        attemptedAuthorization = true
        paymentStatus = .failure
        let respond = reply(fallback: failure) { [weak self] result in
            self?.paymentStatus = result.status
            completion(result)
            self?.didAuthorizePayment?(result)
        }
        if let authorizePayment {
            authorizePayment(payment, respond)
            return
        }
        guard let transport else {
            respond(failure)
            return
        }
        let failure = self.failure
        task = transport.authorize(payment) { success in
            respond(success ? PKPaymentAuthorizationResult(status: .success, errors: nil) : failure)
        }
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: request?.paymentSummaryItems ?? [])
        guard controller === paymentController, sessionID != nil else {
            completion(fallback)
            return
        }
        let respond = reply(fallback: fallback) { [weak self] update in
            self?.request?.paymentSummaryItems = update.paymentSummaryItems
            completion(update)
        }
        if let updateShippingMethod {
            updateShippingMethod(shippingMethod, respond)
        } else if let onShippingMethodDidChange {
            respond(onShippingMethodDidChange(shippingMethod))
        } else {
            respond(fallback)
        }
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestShippingContactUpdate(paymentSummaryItems: request?.paymentSummaryItems ?? [])
        fallback.shippingMethods = request?.shippingMethods ?? []
        guard controller === paymentController, sessionID != nil else {
            completion(fallback)
            return
        }
        fallback.errors = [
            PKPaymentRequest.paymentShippingAddressInvalidError(
                withKey: "", localizedDescription: "Shipping update failed. Please retry."
            )
        ]
        let respond = reply(fallback: fallback) { [weak self] update in
            self?.request?.paymentSummaryItems = update.paymentSummaryItems
            self?.request?.shippingMethods = update.shippingMethods
            completion(update)
        }
        if let updateShippingContact {
            updateShippingContact(contact, respond)
        } else {
            didSelectShippingContact?(contact)
            fallback.errors = nil
            respond(fallback)
        }
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler completion: (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: request?.paymentSummaryItems ?? [])
        guard controller === paymentController, sessionID != nil else {
            completion(fallback)
            return
        }
        let update = onChangeCouponCode?(couponCode) ?? fallback
        request?.paymentSummaryItems = update.paymentSummaryItems
        completion(update)
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler completion: (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: request?.paymentSummaryItems ?? [])
        guard controller === paymentController, sessionID != nil else {
            completion(fallback)
            return
        }
        let update = onDidSelectPaymentMethod?(paymentMethod) ?? fallback
        request?.paymentSummaryItems = update.paymentSummaryItems
        completion(update)
    }
}
