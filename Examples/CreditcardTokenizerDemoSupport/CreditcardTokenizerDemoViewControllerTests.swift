import PCPClient
import UIKit
import XCTest

final class CreditcardTokenizerDemoViewControllerTests: XCTestCase {
    private func configuration() -> CreditcardTokenizerDemoConfiguration {
        CreditcardTokenizerDemoConfiguration(
            tokenizerURL: URL(string: "https://merchant.example/form")!, localHTMLBaseURL: nil,
            mode: "test", locale: "de_DE", iframeWrapperID: "payment-IFrame", submitButtonSelector: "#submit",
            iframeHeight: 400, iframeWidth: 400, allowedCardSchemes: ["visa"], showCardholderName: true,
            includeSensitiveDiagnosticData: false
        )
    }

    func testProvidedTokenLoadsFormAndHidesEditorUntilReplacementIsRequested() throws {
        let settings = configuration()
        settings.token = "  initial-test-token\n"
        let controller = CreditcardTokenizerDemoViewController(configuration: settings)
        controller.loadViewIfNeeded()

        let editor = try XCTUnwrap(find("tokenizer.tokenEditor", in: controller.view) as? UIStackView)
        let input = try XCTUnwrap(find("tokenizer.tokenInput", in: controller.view) as? UITextView)
        let change = try XCTUnwrap(find("tokenizer.changeToken", in: controller.view) as? UIButton)
        let load = try XCTUnwrap(find("tokenizer.loadToken", in: controller.view) as? UIButton)
        let firstForm = try XCTUnwrap(controller.children.first as? CreditcardTokenizerViewController)
        let status = try XCTUnwrap(find("tokenizer.status", in: controller.view) as? UILabel)
        XCTAssertFalse(status.isHidden)
        firstForm.onDiagnosticEvent?("Response · getPaymentPage", ["statusCode": 200])
        XCTAssertTrue(status.isHidden)

        XCTAssertEqual(controller.children.count, 1)
        XCTAssertTrue(editor.isHidden)
        XCTAssertFalse(change.isHidden)
        XCTAssertEqual(change.title(for: .normal), "Neuen Token benutzen")
        XCTAssertEqual(input.text, "initial-test-token")

        try press(change)

        XCTAssertFalse(editor.isHidden)
        XCTAssertTrue(change.isHidden)
        XCTAssertEqual(input.text, "")
        XCTAssertTrue(controller.children.first === firstForm)

        // An empty replacement must not discard the existing form or hide the editor.
        try press(load)
        XCTAssertTrue(controller.children.first === firstForm)
        XCTAssertFalse(editor.isHidden)

        input.text = "replacement-test-token"
        try press(load)

        XCTAssertEqual(controller.children.count, 1)
        XCTAssertFalse(controller.children.first === firstForm)
        XCTAssertTrue(editor.isHidden)
        XCTAssertFalse(change.isHidden)
        XCTAssertFalse(status.isHidden)
        firstForm.onDiagnosticEvent?("Response · getPaymentPage", ["statusCode": 200])
        XCTAssertFalse(status.isHidden, "An old form must not clear the new form's loading status")
        let replacement = try XCTUnwrap(controller.children.first as? CreditcardTokenizerViewController)
        replacement.onDiagnosticEvent?("Response · getPaymentPage", ["statusCode": 200])
        XCTAssertTrue(status.isHidden)
    }

    func testAbsentAndBlankTokensLeaveInputVisibleWithoutLoadingForm() throws {
        for token in [nil, "", " \n\t"] as [String?] {
            let settings = configuration()
            settings.token = token
            let controller = CreditcardTokenizerDemoViewController(configuration: settings)
            controller.loadViewIfNeeded()
            XCTAssertTrue(controller.children.isEmpty)
            XCTAssertFalse(try XCTUnwrap(find("tokenizer.tokenEditor", in: controller.view)).isHidden)
            XCTAssertTrue(try XCTUnwrap(find("tokenizer.changeToken", in: controller.view)).isHidden)
            XCTAssertEqual((find("tokenizer.tokenInput", in: controller.view) as? UITextView)?.text, "")
        }
    }

    func testOriginalInitializerStillSupportsManualTokenEntry() throws {
        let controller = CreditcardTokenizerDemoViewController(configuration: configuration())
        controller.loadViewIfNeeded()
        let input = try XCTUnwrap(find("tokenizer.tokenInput", in: controller.view) as? UITextView)
        let load = try XCTUnwrap(find("tokenizer.loadToken", in: controller.view) as? UIButton)
        input.text = "manually-entered-test-token"
        try press(load)

        XCTAssertEqual(controller.children.count, 1)
        XCTAssertFalse(try XCTUnwrap(find("tokenizer.tokenEditor", in: controller.view)).isHidden)
    }

    // Package tests have no UIApplication to dispatch UIControl.sendActions.
    // Invoke the actual registered target/action rather than a separate test-only method.
    private func press(_ button: UIButton) throws {
        let target = try XCTUnwrap(button.allTargets.first as? NSObject)
        let action = try XCTUnwrap(button.actions(forTarget: target, forControlEvent: .touchUpInside)?.first)
        target.perform(NSSelectorFromString(action))
    }

    private func find(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        for child in view.subviews {
            if let match = find(identifier, in: child) { return match }
        }
        return nil
    }
}
