import Foundation
import Security

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
    
    private let keychainService = Config.keychainService
    
    private init() {
        // 从 UserDefaults 加载配置
        self.apiEndpoint = UserDefaults.standard.string(forKey: "apiEndpoint") ?? Config.defaultAPIEndpoint
        self.targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? Config.defaultTargetLanguage
        self.modelName = UserDefaults.standard.string(forKey: "modelName") ?? "gpt-3.5-turbo"
    }
    
    // API Key 存储到 Keychain
    func saveAPIKey(_ apiKey: String) -> Bool {
        guard let data = apiKey.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "apiKey",
            kSecValueData as String: data
        ]
        
        // 先删除旧的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "apiKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}

