import Foundation

struct TranslationRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    init(text: String, targetLanguage: String) {
        self.model = "gpt-3.5-turbo"
        self.temperature = 0.3
        
        let systemPrompt = "You are a professional translator. Translate the following text to \(targetLanguage). Only return the translation, without any explanations or additional text."
        
        self.messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: text)
        ]
    }
}

