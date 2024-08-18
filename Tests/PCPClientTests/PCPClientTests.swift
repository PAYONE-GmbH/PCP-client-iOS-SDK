import XCTest
@testable import PCPClient

final class PCPClientTests: XCTestCase {
    func testExample() throws {
        let sut = PCPClient()

        let result = sut.frameworkName(isShortName: true)

        XCTAssertEqual(result, "PCPC")
    }
}
