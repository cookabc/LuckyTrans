import Foundation

struct TranslationRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    init(text: String, targetLanguage: String, mode: SettingsManager.TranslationMode, model: String = "gpt-3.5-turbo") {
        self.model = model
        self.temperature = 0.3
        
        let systemPrompt: String
        switch mode {
        case .standard:
            systemPrompt = "You are a professional translator. Translate the following text to \(targetLanguage). Only return the translation."
        case .polish:
            systemPrompt = "You are a professional editor. Polish the following text in \(targetLanguage) with clear, natural, and fluent style. Return only the polished text."
        case .summary:
            systemPrompt = "You are a helpful assistant. Summarize the following content in \(targetLanguage) concisely. Return only the summary."
        }
        
        self.messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: text)
        ]
    }
}
