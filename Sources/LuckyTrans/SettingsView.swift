import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var apiEndpoint: String = Config.defaultAPIEndpoint
    @State private var modelName: String = Config.defaultModelName
    @State private var hasSavedKey: Bool = false
    
    private let languages = ["中文", "English", "日本語", "한국어", "Français", "Deutsch", "Español", "Italiano", "Português", "Русский"]
    
    var body: some View {
        Form {
            Section(header: Text("API 配置")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API 端点")
                        .font(.headline)
                    HStack {
                        TextField("API Endpoint", text: $apiEndpoint)
                            .textFieldStyle(.roundedBorder)
                        Button("保存") {
                            settingsManager.apiEndpoint = apiEndpoint
                        }
                        .buttonStyle(.bordered)
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
                            // 使用 SecureField，如果有已保存的 key 但输入框为空，显示占位符
                            SecureField(hasSavedKey && apiKey.isEmpty ? "••••••••••••" : "API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button(showAPIKey ? "隐藏" : "显示") {
                            if !showAPIKey {
                                // 点击"显示"时，加载真实的 key
                                if apiKey.isEmpty && hasSavedKey {
                                    if let savedKey = settingsManager.getAPIKey() {
                                        apiKey = savedKey
                                    }
                                }
                            } else {
                                // 点击"隐藏"时，如果已保存，清空输入框（SecureField 会显示星号占位符）
                                if hasSavedKey {
                                    apiKey = ""
                                }
                            }
                            showAPIKey.toggle()
                        }
                    }
                    Button("保存 API Key") {
                        if settingsManager.saveAPIKey(apiKey) {
                            hasSavedKey = true
                            // 保存后，如果不显示，清空输入框（SecureField 会显示星号占位符）
                            if !showAPIKey {
                                apiKey = ""
                            }
                            // 显示成功提示
                            let alert = NSAlert()
                            alert.messageText = "保存成功"
                            alert.informativeText = "API Key 已保存"
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
                    .disabled(apiKey.isEmpty && !hasSavedKey)
                    
                    if settingsManager.hasAPIKey() {
                        Text("已保存 API Key")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Section(header: Text("翻译设置")) {
                HStack {
                    Picker("目标语言", selection: $settingsManager.targetLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    Button("保存") {
                        // targetLanguage 通过 @Published 自动保存，这里只是确认
                    }
                    .buttonStyle(.bordered)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("模型名称")
                        .font(.headline)
                    HStack {
                        TextField("Model Name", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: modelName) { newValue in
                                settingsManager.modelName = newValue
                            }
                        Button("保存") {
                            settingsManager.modelName = modelName
                        }
                        .buttonStyle(.bordered)
                    }
                    Text("例如: gpt-3.5-turbo, gpt-4, glm-4.6 等")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            modelName = settingsManager.modelName
            hasSavedKey = settingsManager.hasAPIKey()
            // 如果有已保存的 key，默认显示星号（通过 SecureField）
            if hasSavedKey {
                // 不直接设置 apiKey，让 SecureField 显示星号
                // 用户点击"显示"时再加载真实值
            } else if let savedKey = settingsManager.getAPIKey() {
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

