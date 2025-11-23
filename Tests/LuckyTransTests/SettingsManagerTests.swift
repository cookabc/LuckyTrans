import XCTest
@testable import LuckyTrans

final class SettingsManagerTests: XCTestCase {
    var settingsManager: SettingsManager!
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager.shared
    }
    
    func testDefaultValues() {
        XCTAssertEqual(settingsManager.apiEndpoint, Config.defaultAPIEndpoint)
        XCTAssertEqual(settingsManager.targetLanguage, Config.defaultTargetLanguage)
    }
    
    func testAPIEndpointUpdate() {
        let newEndpoint = "https://api.example.com/v1/chat/completions"
        settingsManager.apiEndpoint = newEndpoint
        
        XCTAssertEqual(settingsManager.apiEndpoint, newEndpoint)
        
        // 验证已保存到 UserDefaults
        let saved = UserDefaults.standard.string(forKey: "apiEndpoint")
        XCTAssertEqual(saved, newEndpoint)
    }
    
    func testTargetLanguageUpdate() {
        let newLanguage = "English"
        settingsManager.targetLanguage = newLanguage
        
        XCTAssertEqual(settingsManager.targetLanguage, newLanguage)
        
        // 验证已保存到 UserDefaults
        let saved = UserDefaults.standard.string(forKey: "targetLanguage")
        XCTAssertEqual(saved, newLanguage)
    }
    
    func testAPIKeyStorage() {
        let testKey = "test-api-key-12345"
        
        // 保存 API Key
        let saveResult = settingsManager.saveAPIKey(testKey)
        XCTAssertTrue(saveResult)
        
        // 读取 API Key
        let retrievedKey = settingsManager.getAPIKey()
        XCTAssertEqual(retrievedKey, testKey)
        
        // 验证已保存
        XCTAssertTrue(settingsManager.hasAPIKey())
    }
    
    func testAPIKeyUpdate() {
        let firstKey = "first-key"
        let secondKey = "second-key"
        
        settingsManager.saveAPIKey(firstKey)
        XCTAssertEqual(settingsManager.getAPIKey(), firstKey)
        
        settingsManager.saveAPIKey(secondKey)
        XCTAssertEqual(settingsManager.getAPIKey(), secondKey)
        XCTAssertNotEqual(settingsManager.getAPIKey(), firstKey)
    }
}

