import Foundation

struct TranslationResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    
    struct Choice: Codable {
        let index: Int?
        let message: Message
        let finishReason: String?
        
        struct Message: Codable {
            let role: String?
            let content: String
        }
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    var translation: String? {
        // 兼容不同的响应格式
        if let firstChoice = choices.first {
            return firstChoice.message.content
        }
        return nil
    }
}

struct TranslationError: Codable, Error, LocalizedError {
    let error: ErrorDetail
    
    struct ErrorDetail: Codable {
        let message: String
        let type: String?
        let code: String?
    }
    
    var localizedDescription: String {
        return error.message
    }
    
    var errorDescription: String? {
        return error.message
    }
    
    var failureReason: String? {
        return error.type
    }
}

