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
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textFieldStyle(.roundedBorder)
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
                            // 使用 SecureField，如果有已保存的 key，使用占位符显示星号
                            SecureField("API Key", text: Binding(
                                get: {
                                    // 如果已保存且当前为空，返回占位符（SecureField 会显示为星号）
                                    if hasSavedKey && (apiKey.isEmpty || apiKey == "••••••••••••") {
                                        return "••••••••••••"
                                    }
                                    return apiKey
                                },
                                set: { newValue in
                                    // 如果输入的是占位符，忽略
                                    if newValue != "••••••••••••" {
                                        apiKey = newValue
                                    }
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        Button(showAPIKey ? "隐藏" : "显示") {
                            if !showAPIKey {
                                // 点击"显示"时，加载真实的 key
                                if apiKey.isEmpty || apiKey == "••••••••••••" {
                                    if let savedKey = settingsManager.getAPIKey() {
                                        apiKey = savedKey
                                    }
                                }
                            } else {
                                // 点击"隐藏"时，如果已保存，恢复占位符
                                if hasSavedKey {
                                    apiKey = "••••••••••••"
                                }
                            }
                            showAPIKey.toggle()
                        }
                    }
                    
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("模型名称")
                        .font(.headline)
                    TextField("Model Name", text: $modelName)
                        .textFieldStyle(.roundedBorder)
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
            
            Section {
                Button("保存所有设置") {
                    saveAllSettings()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            apiEndpoint = settingsManager.apiEndpoint
            modelName = settingsManager.modelName
            hasSavedKey = settingsManager.hasAPIKey()
            // 如果有已保存的 key，设置占位符，SecureField 会显示为星号
            if hasSavedKey {
                apiKey = "••••••••••••"
            }
        }
    }
    
    private func saveAllSettings() {
        // 保存所有设置
        settingsManager.apiEndpoint = apiEndpoint
        settingsManager.modelName = modelName
        
        // 保存 API Key（如果输入框有内容且不是占位符）
        if !apiKey.isEmpty && apiKey != "••••••••••••" {
            if settingsManager.saveAPIKey(apiKey) {
                hasSavedKey = true
                // 保存后，如果不显示，恢复占位符
                if !showAPIKey {
                    apiKey = "••••••••••••"
                }
            }
        }
        
        // 显示成功提示
        let alert = NSAlert()
        alert.messageText = "保存成功"
        alert.informativeText = "所有设置已保存"
        alert.alertStyle = .informational
        alert.runModal()
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

