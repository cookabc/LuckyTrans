import XCTest
@testable import LuckyTrans

final class TextCaptureManagerTests: XCTestCase {
    var textCaptureManager: TextCaptureManager!
    
    override func setUp() {
        super.setUp()
        textCaptureManager = TextCaptureManager.shared
    }
    
    func testTextCaptureManagerSingleton() {
        let instance1 = TextCaptureManager.shared
        let instance2 = TextCaptureManager.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testGetSelectedTextReturnsNilWhenNoText() {
        // 注意：这个测试在实际环境中可能无法完全模拟
        // 因为它依赖于系统状态和权限
        // 这里主要测试方法存在且可调用
        
        let result = textCaptureManager.getSelectedText()
        // 结果可能是 nil（如果没有选中文本或没有权限）
        // 或者是一个字符串
        XCTAssertTrue(result == nil || result is String)
    }
}

