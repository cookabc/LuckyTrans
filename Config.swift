import Foundation

struct Config {
    // 默认 API 端点
    static let defaultAPIEndpoint = "https://api.openai.com/v1/chat/completions"
    
    // 默认快捷键
    static let defaultShortcutKey = "T"
    static let defaultShortcutModifiers: NSEvent.ModifierFlags = [.command, .shift]
    
    // 默认目标语言
    static let defaultTargetLanguage = "中文"
    
    // 应用标识
    static let bundleIdentifier = "com.luckytrans.app"
    
    // Keychain 服务名
    static let keychainService = "LuckyTransAPIKey"
}

