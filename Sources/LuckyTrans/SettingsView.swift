import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var apiEndpoint: String = Config.defaultAPIEndpoint
    
    private let languages = ["中文", "English", "日本語", "한국어", "Français", "Deutsch", "Español", "Italiano", "Português", "Русский"]
    
    var body: some View {
        Form {
            Section(header: Text("API 配置")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API 端点")
                        .font(.headline)
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: apiEndpoint) { newValue in
                            settingsManager.apiEndpoint = newValue
                        }
                    Text("支持 OpenAI compatible API，如本地部署的模型服务")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("示例: https://api.openai.com/v1/chat/completions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.headline)
                    HStack {
                        if showAPIKey {
                            TextField("API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button(showAPIKey ? "隐藏" : "显示") {
                            showAPIKey.toggle()
                        }
                    }
                    Button("保存 API Key") {
                        if settingsManager.saveAPIKey(apiKey) {
                            apiKey = ""
                            // 显示成功提示
                            let alert = NSAlert()
                            alert.messageText = "保存成功"
                            alert.informativeText = "API Key 已安全保存到 Keychain"
                            alert.alertStyle = .informational
                            alert.runModal()
                        } else {
                            // 显示错误提示
                            let alert = NSAlert()
                            alert.messageText = "保存失败"
                            alert.informativeText = "无法保存 API Key，请重试"
                            alert.alertStyle = .warning
                            alert.runModal()
                        }
                    }
                    .disabled(apiKey.isEmpty)
                    
                    if settingsManager.hasAPIKey() {
                        Text("已保存 API Key")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Section(header: Text("翻译设置")) {
                Picker("目标语言", selection: $settingsManager.targetLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
            }
            
            Section(header: Text("快捷键")) {
                Text("默认快捷键: ⌘⇧T")
                    .font(.body)
                Text("快捷键配置功能即将推出")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("权限")) {
                Button("检查辅助功能权限") {
                    checkAccessibilityPermission()
                }
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            apiEndpoint = settingsManager.apiEndpoint
            if let savedKey = settingsManager.getAPIKey() {
                apiKey = savedKey
            }
        }
    }
    
    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "请在系统设置 > 隐私与安全性 > 辅助功能中授予 LuckyTrans 权限"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "取消")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            let alert = NSAlert()
            alert.messageText = "权限已授予"
            alert.informativeText = "辅助功能权限已正确配置"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}

