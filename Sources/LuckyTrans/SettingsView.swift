import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var apiEndpoint: String = Config.defaultAPIEndpoint
    @State private var modelName: String = Config.defaultModelName
    @State private var hasSavedKey: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("API 配置")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // API 端点
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("API 端点")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            TextField("https://api.openai.com/v1/chat/completions", text: $apiEndpoint)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Divider()
                        
                        // API Key
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("API Key")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            HStack(spacing: 8) {
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
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        Divider()
                        
                        // 模型名称
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("模型名称")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            TextField("gpt-3.5-turbo", text: $modelName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("外观")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // 主题模式
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("主题模式")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Picker("", selection: $settingsManager.appearanceMode) {
                                ForEach(SettingsManager.AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("其他")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // 快捷键
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("快捷键")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            ShortcutRecorderView(
                                keyCode: $settingsManager.shortcutKeyCode,
                                modifiers: $settingsManager.shortcutModifiers
                            )
                            .frame(height: 24)
                        }
                        
                        Divider()
                        
                        // 权限
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("权限")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Button("检查辅助功能权限") {
                                checkAccessibilityPermission()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            
            // 底部保存按钮
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Spacer()
                    Button("保存") {
                        saveAllSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(width: 550, height: 650)
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

