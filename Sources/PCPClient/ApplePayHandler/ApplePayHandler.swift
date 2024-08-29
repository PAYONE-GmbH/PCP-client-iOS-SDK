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

public class ApplePayHandler: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    public var paymentController: PKPaymentAuthorizationViewController?
    public var didAuthorizePayment: ((PKPaymentAuthorizationResult) -> Void)?
    public var didSelectShippingContact: ((PKContact) -> Void)?

    public var onShippingMethodDidChange: ((PKShippingMethod) -> PKPaymentRequestShippingMethodUpdate)?
    public var onDidSelectPaymentMethod: ((PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate)?
    public var onChangeCouponCode: ((String) -> PKPaymentRequestCouponCodeUpdate)?

    private var paymentStatus: PKPaymentAuthorizationStatus = .failure
    private var completion: ((Bool) -> Void)?
    private let processPaymentServerUrl: URL
    private var request: PKPaymentRequest?

    public init(
        processPaymentServerUrl: URL
    ) {
        self.processPaymentServerUrl = processPaymentServerUrl
    }

    public func supportsApplePay() -> Bool {
        guard let request else {
            return PKPaymentAuthorizationViewController.canMakePayments()
        }
        return PKPaymentAuthorizationViewController.canMakePayments() &&
            PKPaymentAuthorizationViewController.canMakePayments(
                usingNetworks: request.supportedNetworks,
                capabilities: request.merchantCapabilities
            )
    }

    public func startPaymentAndReturnViewController(
        request: PKPaymentRequest,
        onDidSelectPaymentMethod: @escaping @convention(block) (PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate,
        completion: @escaping (Bool) -> Void
    ) -> UIViewController? {
        startPayment(request: request, onDidSelectPaymentMethod: onDidSelectPaymentMethod, completion: completion)
        return paymentController
    }

    public func startAndPresentPayment(
        request: PKPaymentRequest,
        on viewController: UIViewController,
        onDidSelectPaymentMethod: @escaping @convention(block) (PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate,
        completion: @escaping @convention(block) (Bool) -> Void
    ) {
        startPayment(request: request, onDidSelectPaymentMethod: onDidSelectPaymentMethod, completion: completion)
        if let paymentController {
            viewController.present(paymentController, animated: true)
        }
    }

    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        PCPLogger.info("Dismisses PKPaymentAuthorizationViewController.")
        controller.dismiss(animated: true, completion: nil)
        completion?(paymentStatus == .success)
    }

    public func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
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

        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                PCPLogger.error(error.localizedDescription)
                self?.paymentStatus = .failure
                let result = PKPaymentAuthorizationResult(status: .failure, errors: [error])
                completion(result)
                self?.didAuthorizePayment?(result)
            } else if let data = data {
                let str = String(data: data, encoding: .utf8)
                PCPLogger.info("Received data:\n\(str ?? "")")
                self?.paymentStatus = .success
                let result = PKPaymentAuthorizationResult(status: .success, errors: nil)
                completion(result)
                self?.didAuthorizePayment?(result)
            }

        }

        task.resume()
    }

    public func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        guard let request else {
            PCPLogger.error("Shipping method was changed but not request object was set.")
            self.completion?(false)
            return
        }

        guard let onShippingMethodDidChange else {
            PCPLogger.error("No onShippingMethodDidChange defined.")
            self.completion?(false)
            return
        }
        var paymentSummaryItems = request.paymentSummaryItems
        paymentSummaryItems.append(PKPaymentSummaryItem(label: shippingMethod.label, amount: shippingMethod.amount))
        PCPLogger.info("Shipping method selected..")
        completion(onShippingMethodDidChange(shippingMethod))
    }

    public func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
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

    public func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
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

    public func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect paymentMethod: PKPaymentMethod,
        handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        guard let onDidSelectPaymentMethod else {
            PCPLogger.error("No onDidSelectPaymentMethod defined.")
            self.completion?(false)
            return
        }
        completion(onDidSelectPaymentMethod(paymentMethod))
    }

    private func startPayment(
        request: PKPaymentRequest,
        onDidSelectPaymentMethod: @escaping @convention(block) (PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate,
        completion: @escaping @convention(block) (Bool) -> Void
    ) {
        PCPLogger.info("Starts payment request.")
        self.request = request
        self.completion = completion
        self.onDidSelectPaymentMethod = onDidSelectPaymentMethod
        self.paymentController = PKPaymentAuthorizationViewController(paymentRequest: request)
        paymentController?.delegate = self
    }
}
