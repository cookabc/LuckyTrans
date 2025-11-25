import Foundation
import AppKit

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
    
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }
    
    enum AppearanceMode: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var displayName: String {
            switch self {
            case .system: return "跟随系统"
            case .light: return "浅色"
            case .dark: return "深色"
            }
        }
    }
    
    private init() {
        // 从 UserDefaults 加载配置
        self.apiEndpoint = UserDefaults.standard.string(forKey: "apiEndpoint") ?? Config.defaultAPIEndpoint
        self.targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? Config.defaultTargetLanguage
        self.modelName = UserDefaults.standard.string(forKey: "modelName") ?? "gpt-3.5-turbo"
        
        // 加载主题模式设置
        let savedMode = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: savedMode) ?? .system
        
        // 应用保存的主题设置
        applyAppearance()
    }
    
    private func applyAppearance() {
        let appearance: NSAppearance?
        switch appearanceMode {
        case .system:
            appearance = nil // nil 表示跟随系统
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        }
        
        NSApp.appearance = appearance
        
        // 更新所有窗口的外观
        for window in NSApplication.shared.windows {
            window.appearance = appearance ?? NSAppearance.currentDrawing()
        }
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

