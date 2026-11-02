import PCPClient
import XCTest

final class CreditcardTokenizerDemoConfigurationTests: XCTestCase {
    func testExplicitParametersProduceSDKConfigurationWithRuntimeToken() {
        let settings = CreditcardTokenizerDemoConfiguration(
            tokenizerURL: URL(string: "https://shop.example/cards")!, localHTMLBaseURL: nil,
            mode: "test", locale: "en_US", iframeWrapperID: "custom-frame", submitButtonSelector: ".pay",
            iframeHeight: 520, iframeWidth: 360, allowedCardSchemes: ["visa"], showCardholderName: false,
            includeSensitiveDiagnosticData: false
        )
        var received = false
        let config = settings.makeSDKConfiguration(token: "runtime-token", success: { _, _, _, _ in }, failure: { _, _ in received = true })
        XCTAssertEqual(config.token, "runtime-token")
        XCTAssertEqual(config.iframeConfig.iframeWrapperId, "custom-frame")
        XCTAssertEqual(config.iframeConfig.height, 520)
        XCTAssertEqual(config.submitButtonConfig.selector, ".pay")
        XCTAssertEqual(config.allowedCardSchemes, ["visa"])
        XCTAssertEqual(config.locale, "en_US")
        XCTAssertFalse(config.showCardholderName)
        config.tokenizationFailureCallback?(403, [:])
        XCTAssertTrue(received)
    }

    func testResourceConfigurationCanResolveHostedPageWithoutBundledHTML() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = try XCTUnwrap(Bundle.module.url(forResource: "CreditcardTokenizerDemoConfiguration", withExtension: "plist"))
        var values = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: source), format: nil) as? [String: Any])
        values["pageURL"] = "https://merchant.example/form"
        values["token"] = "configured-test-token"
        let data = try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
        try data.write(to: directory.appendingPathComponent("CreditcardTokenizerDemoConfiguration.plist"))
        let bundle = try XCTUnwrap(Bundle(url: directory))
        let settings = try CreditcardTokenizerDemoConfiguration.load(from: bundle)
        XCTAssertEqual(settings.tokenizerURL.absoluteString, "https://merchant.example/form")
        XCTAssertEqual(settings.iframeHeight, 400)
        XCTAssertEqual(settings.mode, "test")
        XCTAssertEqual(settings.token, "configured-test-token")
        XCTAssertThrowsError(try CreditcardTokenizerDemoConfiguration.load(from: Bundle(for: NSObject.self)))
    }
}
