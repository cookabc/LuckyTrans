import XCTest
@testable import LuckyTrans

final class TranslationServiceTests: XCTestCase {
    var translationService: TranslationService!
    var settingsManager: SettingsManager!
    
    override func setUp() {
        super.setUp()
        translationService = TranslationService.shared
        settingsManager = SettingsManager.shared
    }
    
    func testTranslationRequestEncoding() throws {
        let request = TranslationRequest(text: "Hello", targetLanguage: "中文")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        XCTAssertNotNil(data)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TranslationRequest.self, from: data)
        
        XCTAssertEqual(decoded.model, "gpt-3.5-turbo")
        XCTAssertEqual(decoded.messages.count, 2)
        XCTAssertEqual(decoded.messages[0].role, "system")
        XCTAssertEqual(decoded.messages[1].role, "user")
        XCTAssertEqual(decoded.messages[1].content, "Hello")
    }
    
    func testTranslationResponseDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-3.5-turbo",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "你好"
                },
                "finish_reason": "stop"
            }]
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TranslationResponse.self, from: data)
        
        XCTAssertEqual(response.id, "chatcmpl-123")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.translation, "你好")
    }
    
    func testTranslationErrorDecoding() throws {
        let json = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "invalid_request_error",
                "code": "invalid_api_key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let error = try JSONDecoder().decode(TranslationError.self, from: data)
        
        XCTAssertEqual(error.error.message, "Invalid API key")
        XCTAssertEqual(error.error.type, "invalid_request_error")
        XCTAssertEqual(error.error.code, "invalid_api_key")
    }
}

