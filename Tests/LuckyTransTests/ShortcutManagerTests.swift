import XCTest
@testable import LuckyTrans

final class ShortcutManagerTests: XCTestCase {
    func testShortcutManagerInitialization() {
        let manager = ShortcutManager()
        XCTAssertNotNil(manager)
    }
    
    func testShortcutManagerUnregister() {
        let manager = ShortcutManager()
        // 测试注销不会崩溃
        manager.unregister()
        // 再次注销应该也是安全的
        manager.unregister()
    }
    
    func testFourCharCodeFromString() {
        let code = FourCharCode(fromString: "LTrn")
        XCTAssertNotEqual(code, 0)
    }
}

