//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import XCTest

internal class URLProtocolStub: URLProtocol {
    // This dictionary will store our stubbed responses for different URLs
    internal static var expectedResult: (() -> (Data?, (any Error)?))?
    internal static var invokedURLRequests = [URLRequest]()
    internal static var expectation: XCTestExpectation?

    override internal class func canInit(with _: URLRequest) -> Bool {
        // Allow this protocol to handle all types of requests
        true
    }

    override internal class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Just return the original request
        request
    }

    override internal func startLoading() {
        Self.invokedURLRequests.append(request)
        // Check if we have a stubbed response for this request's URL
        let result = Self.expectedResult?()
        if let data = result?.0 {
            self.client?.urlProtocol(self, didLoad: data)
        } else if let error = result?.1 {
            self.client?.urlProtocol(self, didFailWithError: error)
        }

        // Finish loading
        Self.expectation?.fulfill()
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override internal  func stopLoading() {
        // This method is required but can be left empty in this case
    }
}
