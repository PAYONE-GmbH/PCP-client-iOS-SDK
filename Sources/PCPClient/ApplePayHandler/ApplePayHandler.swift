//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//
import Foundation
import PassKit
import SwiftUI

@objc public class ApplePayHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    @objc public var paymentController: PKPaymentAuthorizationController?
    @objc public var didAuthorizePayment: ((PKPaymentAuthorizationResult) -> Void)?
    @objc public var didSelectShippingContact: ((PKContact) -> Void)?

    @objc public var onShippingMethodDidChange: ((PKShippingMethod) -> PKPaymentRequestShippingMethodUpdate)?
    @objc public var onDidSelectPaymentMethod: ((PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate)?
    @objc public var onChangeCouponCode: ((String) -> PKPaymentRequestCouponCodeUpdate)?

    private var paymentStatus: PKPaymentAuthorizationStatus = .failure
    private var completion: ((Bool) -> Void)?
    private let processPaymentServerUrl: URL
    private let urlSession: URLSession
    internal var request: PKPaymentRequest?

    @objc public init(
        processPaymentServerUrl: URL,
        urlSession: URLSession = URLSession.shared
    ) {
        self.processPaymentServerUrl = processPaymentServerUrl
        self.urlSession = urlSession
    }

    @objc public func supportsApplePay() -> Bool {
        guard let request else {
            return PKPaymentAuthorizationController.canMakePayments()
        }
        return PKPaymentAuthorizationController.canMakePayments() &&
            PKPaymentAuthorizationController.canMakePayments(
                usingNetworks: request.supportedNetworks,
                capabilities: request.merchantCapabilities
            )
    }

    @objc public func startPayment(
        request: PKPaymentRequest,
        onDidSelectPaymentMethod: @escaping @convention(block) (PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate,
        completion: @escaping @convention(block) (Bool) -> Void
    ) {
        PCPLogger.info("Starts payment request.")
        self.request = request
        self.completion = completion
        self.onDidSelectPaymentMethod = onDidSelectPaymentMethod
        self.paymentController = PKPaymentAuthorizationController(paymentRequest: request)
        paymentController?.delegate = self
        paymentController?.present()
    }

    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        PCPLogger.info("Dismisses PKPaymentAuthorizationController.")
        controller.dismiss()
        completion?(paymentStatus == .success)
    }

    public func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        let paymentMethodData = payment.token.paymentMethod.network?.rawValue ?? ""
        let transactionIdentifier = payment.token.transactionIdentifier

        let paymentData: [String: Any] = [
            "paymentMethod": paymentMethodData,
            "transactionIdentifier": transactionIdentifier
        ]

        var request = URLRequest(url: processPaymentServerUrl)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: paymentData, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in
            if let error {
                PCPLogger.error(error.localizedDescription)
                self?.paymentStatus = .failure
                let result = PKPaymentAuthorizationResult(status: .failure, errors: [error])
                completion(result)
                self?.didAuthorizePayment?(result)
            } else if let data {
                let dataString = String(decoding: data, as: UTF8.self)
                PCPLogger.info("Received data:\n\(dataString)")
                self?.paymentStatus = .success
                let result = PKPaymentAuthorizationResult(status: .success, errors: nil)
                completion(result)
                self?.didAuthorizePayment?(result)
            }
        }

        task.resume()
    }

    public func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        guard let onShippingMethodDidChange else {
            PCPLogger.error("No onShippingMethodDidChange defined.")
            self.completion?(false)
            return
        }
        PCPLogger.info("Shipping method selected..")
        completion(onShippingMethodDidChange(shippingMethod))
    }

    public func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        guard let request else {
            PCPLogger.error("Shipping contact was changed but not request object was set.")
            self.completion?(false)
            return
        }

        didSelectShippingContact?(contact)
        completion(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: request.paymentSummaryItems))
    }

    public func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        guard let onChangeCouponCode else {
            PCPLogger.error("No onChangeCouponCode defined.")
            self.completion?(false)
            return
        }

        completion(onChangeCouponCode(couponCode))
    }

    public func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        guard let onDidSelectPaymentMethod else {
            PCPLogger.error("No onDidSelectPaymentMethod defined.")
            self.completion?(false)
            return
        }
        completion(onDidSelectPaymentMethod(paymentMethod))
    }
}
