import XCTest
@testable import Notchmark

final class NotchmarkTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: NotchmarkApp.self), "NotchmarkApp")
    }
}
