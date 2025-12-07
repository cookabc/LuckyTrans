import Foundation
import AppKit
import ServiceManagement
import Carbon

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
    
    @Published var shortcutKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(shortcutKeyCode), forKey: "shortcutKeyCode")
            updateShortcut()
        }
    }
    
    @Published var shortcutModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(Int(shortcutModifiers), forKey: "shortcutModifiers")
            updateShortcut()
        }
    }

    // 常规设置
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            applyLaunchAtLogin()
        }
    }
    
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
            applyMenuBarVisibility()
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
    
    enum TranslationMode: String, CaseIterable {
        case standard = "standard"
        case polish = "polish"
        case summary = "summary"
        
        var displayName: String {
            switch self {
            case .standard: return "标准翻译"
            case .polish: return "润色"
            case .summary: return "总结"
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
        
        let savedTranslationMode = UserDefaults.standard.string(forKey: "translationMode") ?? "standard"
        self.translationMode = TranslationMode(rawValue: savedTranslationMode) ?? .standard
        
        // 加载快捷键设置
        let savedKeyCode = UserDefaults.standard.integer(forKey: "shortcutKeyCode")
        let savedModifiers = UserDefaults.standard.integer(forKey: "shortcutModifiers")
        
        if savedKeyCode > 0 && savedModifiers > 0 {
            self.shortcutKeyCode = UInt32(savedKeyCode)
            self.shortcutModifiers = UInt32(savedModifiers)
        } else {
            // 默认快捷键：Cmd + T
            self.shortcutKeyCode = 0x11 // 'T' key
            self.shortcutModifiers = UInt32(cmdKey)
        }
        // 加载常规设置
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.showInMenuBar = UserDefaults.standard.object(forKey: "showInMenuBar") as? Bool ?? true
        
        // 应用保存的主题设置
        applyAppearance()
        applyMenuBarVisibility()
    }
    
    @Published var translationMode: TranslationMode {
        didSet {
            UserDefaults.standard.set(translationMode.rawValue, forKey: "translationMode")
        }
    }
    
    private func updateShortcut() {
        // 通知 ShortcutManager 更新快捷键
        NotificationCenter.default.post(name: NSNotification.Name("ShortcutDidChange"), object: nil)
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

    private func applyMenuBarVisibility() {
        if showInMenuBar {
            MenuBarManager.shared.setup()
        } else {
            MenuBarManager.shared.remove()
        }
    }
    
    private func applyLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("LaunchAtLogin update failed: \(error)")
            }
        } else {
            print("LaunchAtLogin not supported on this macOS version")
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
