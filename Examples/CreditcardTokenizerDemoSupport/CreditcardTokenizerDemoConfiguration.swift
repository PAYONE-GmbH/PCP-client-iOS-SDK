// Example-only configuration; optional tokens are intended for short-lived manual tests.
import Foundation
import PCPClient

@objc public final class CreditcardTokenizerDemoConfiguration: NSObject {
    @objc public let tokenizerURL: URL
    @objc public let localHTMLBaseURL: URL?
    @objc public let mode: String
    @objc public let locale: String
    @objc public let iframeWrapperID: String
    @objc public let submitButtonSelector: String
    @objc public let iframeHeight: Double
    @objc public let iframeWidth: Double
    @objc public let allowedCardSchemes: [String]
    @objc public let showCardholderName: Bool
    @objc public let includeSensitiveDiagnosticData: Bool
    @objc public var token: String?

    @objc public init(tokenizerURL: URL, localHTMLBaseURL: URL?, mode: String, locale: String,
                      iframeWrapperID: String, submitButtonSelector: String, iframeHeight: Double, iframeWidth: Double,
                      allowedCardSchemes: [String], showCardholderName: Bool, includeSensitiveDiagnosticData: Bool) {
        self.tokenizerURL = tokenizerURL
        self.localHTMLBaseURL = localHTMLBaseURL
        self.mode = mode
        self.locale = locale
        self.iframeWrapperID = iframeWrapperID
        self.submitButtonSelector = submitButtonSelector
        self.iframeHeight = iframeHeight
        self.iframeWidth = iframeWidth
        self.allowedCardSchemes = allowedCardSchemes
        self.showCardholderName = showCardholderName
        self.includeSensitiveDiagnosticData = includeSensitiveDiagnosticData
        super.init()
    }

    @objc(loadFromBundle:error:)
    public static func load(from bundle: Bundle) throws -> CreditcardTokenizerDemoConfiguration {
        guard let resource = bundle.url(forResource: "CreditcardTokenizerDemoConfiguration", withExtension: "plist"),
              let values = try PropertyListSerialization.propertyList(from: Data(contentsOf: resource), format: nil) as? [String: Any],
              let mode = values["mode"] as? String, ["test", "live"].contains(mode),
              let locale = values["locale"] as? String, !locale.isEmpty,
              let wrapper = values["iframeWrapperID"] as? String, !wrapper.isEmpty,
              let selector = values["submitButtonSelector"] as? String, !selector.isEmpty,
              let height = values["iframeHeight"] as? Double, height > 0,
              let width = values["iframeWidth"] as? Double, width > 0,
              let schemes = values["allowedCardSchemes"] as? [String],
              let showName = values["showCardholderName"] as? Bool,
              let sensitive = values["includeSensitiveDiagnosticData"] as? Bool else { throw invalidConfiguration }
        let pageURL: URL
        if let remote = values["pageURL"] as? String, !remote.isEmpty {
            guard let url = URL(string: remote), url.scheme == "https", url.host != nil else { throw invalidConfiguration }
            pageURL = url
        } else {
            guard let name = values["htmlResourceName"] as? String,
                  let url = bundle.url(forResource: name, withExtension: "html") else { throw invalidConfiguration }
            pageURL = url
        }
        let baseURL = (values["localHTMLBaseURL"] as? String).flatMap(URL.init(string:))
        if pageURL.isFileURL && (baseURL?.scheme != "https" || baseURL?.host == nil) { throw invalidConfiguration }
        if let token = values["token"], !(token is String) { throw invalidConfiguration }
        let configuration = CreditcardTokenizerDemoConfiguration(
            tokenizerURL: pageURL, localHTMLBaseURL: baseURL, mode: mode, locale: locale,
            iframeWrapperID: wrapper, submitButtonSelector: selector, iframeHeight: height, iframeWidth: width,
            allowedCardSchemes: schemes, showCardholderName: showName, includeSensitiveDiagnosticData: sensitive
        )
        configuration.token = values["token"] as? String
        return configuration
    }

    private static var invalidConfiguration: NSError {
        NSError(domain: "CreditcardTokenizerDemo.Configuration", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "CreditcardTokenizerDemoConfiguration.plist fehlt oder ist ungültig."
        ])
    }

    func makeSDKConfiguration(token: String, success: @escaping (Int, String, CardDetails, String) -> Void,
                              failure: @escaping (Int, [String: Any]) -> Void) -> CreditcardTokenizerConfig {
        CreditcardTokenizerConfig(
            iframeConfig: IframeConfig(iframeWrapperId: iframeWrapperID, height: iframeHeight, width: iframeWidth),
            uiConfig: nil, locale: locale, token: token, mode: mode, allowedCardSchemes: allowedCardSchemes,
            customTextConfig: nil, submitButtonConfig: SubmitButtonConfig(selector: submitButtonSelector),
            showCardholderName: showCardholderName,
            tokenizationSuccessCallback: success, tokenizationFailureCallback: failure
        )
    }
}
