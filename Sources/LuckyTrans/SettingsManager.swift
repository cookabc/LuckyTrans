import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var apiEndpoint: String {
        didSet {
            UserDefaults.standard.set(apiEndpoint, forKey: "apiEndpoint")
        }
    }
    
    @Published var targetLanguage: String {
        didSet {
            UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage")
        }
    }
    
    @Published var modelName: String {
        didSet {
            UserDefaults.standard.set(modelName, forKey: "modelName")
        }
    }
    
    private init() {
        // 从 UserDefaults 加载配置
        self.apiEndpoint = UserDefaults.standard.string(forKey: "apiEndpoint") ?? Config.defaultAPIEndpoint
        self.targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? Config.defaultTargetLanguage
        self.modelName = UserDefaults.standard.string(forKey: "modelName") ?? "gpt-3.5-turbo"
    }
    
    // API Key 存储到 UserDefaults（不再使用 Keychain，避免每次启动需要密码）
    func saveAPIKey(_ apiKey: String) -> Bool {
        guard !apiKey.isEmpty else { return false }
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        return true
    }
    
    func getAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: "apiKey")
    }
    
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil && !getAPIKey()!.isEmpty
    }
}

