import SwiftUI
import ApplicationServices

// 设置页面枚举
enum SettingsPage: String, CaseIterable, Identifiable {
    case general
    case apiModels
    case shortcuts
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "General"
        case .apiModels: return "API & Models"
        case .shortcuts: return "Shortcuts"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .apiModels: return "globe"
        case .shortcuts: return "keyboard"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedPage: SettingsPage = .apiModels
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            SettingsSidebar(selectedPage: $selectedPage)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } detail: {
            // 内容区域
            Group {
                switch selectedPage {
                case .general:
                    GeneralSettingsView()
                case .apiModels:
                    APIModelsSettingsView()
                case .shortcuts:
                    ShortcutsSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 750, height: 600)
    }
}

// 侧边栏组件
struct SettingsSidebar: View {
    @Binding var selectedPage: SettingsPage
    
    var body: some View {
        List(selection: $selectedPage) {
            ForEach(SettingsPage.allCases) { page in
                Label(page.title, systemImage: page.icon)
                    .tag(page)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Settings")
    }
}

// General 设置页面
struct GeneralSettingsView: View {
    var body: some View {
        VStack {
            Text("General Settings")
                .font(.title2)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// API & Models 设置页面
struct APIModelsSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var apiEndpoint: String = Config.defaultAPIEndpoint
    @State private var modelName: String = Config.defaultModelName
    @State private var hasSavedKey: Bool = false
    @State private var savedKeyLength: Int = 0
    
    // 生成与实际 key 长度相同的占位符
    private var placeholder: String {
        if savedKeyLength > 0 {
            return String(repeating: "•", count: savedKeyLength)
        }
        return "••••••••••••" // 默认占位符
    }
    
    // 可用的模型列表
    private let availableModels = ["GLM-4.6", "gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // API 配置部分
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Configuration")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    // API 端点
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Endpoint")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ScrollableTextField(text: $apiEndpoint, placeholder: "")
                            .frame(height: 24)
                    }
                    
                    Divider()
                    
                    // API Key
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            ScrollableTextField(
                                text: Binding(
                                    get: {
                                        // 如果隐藏且已保存，返回占位符
                                        if !showAPIKey && hasSavedKey {
                                            return placeholder
                                        }
                                        return apiKey
                                    },
                                    set: { newValue in
                                        // 如果输入的是占位符，忽略
                                        if newValue != placeholder {
                                            apiKey = newValue
                                        }
                                    }
                                ),
                                placeholder: "",
                                isSecure: !showAPIKey
                            )
                            .id("apiKey_\(showAPIKey)") // 通过 id 强制重新创建视图以切换安全模式
                            .frame(height: 24)
                            
                            // 眼睛图标按钮
                            Button(action: {
                                if !showAPIKey {
                                    // 点击"显示"时，加载真实的 key
                                    if apiKey.isEmpty || apiKey == placeholder {
                                        if let savedKey = settingsManager.getAPIKey() {
                                            apiKey = savedKey
                                        }
                                    }
                                } else {
                                    // 点击"隐藏"时，如果已保存，恢复占位符
                                    if hasSavedKey {
                                        apiKey = placeholder
                                    }
                                }
                                showAPIKey.toggle()
                            }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help(showAPIKey ? "隐藏" : "显示")
                        }
                    }
                    
                    Divider()
                    
                    // 模型名称
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $modelName) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(height: 24)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // 外观部分
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    // 主题模式
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme Mode")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $settingsManager.appearanceMode) {
                            ForEach(SettingsManager.AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
            }
            .padding()
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            apiEndpoint = settingsManager.apiEndpoint
            modelName = settingsManager.modelName
            hasSavedKey = settingsManager.hasAPIKey()
            // 如果有已保存的 key，获取其长度并设置占位符
            if hasSavedKey, let savedKey = settingsManager.getAPIKey() {
                savedKeyLength = savedKey.count
                apiKey = placeholder
            }
        }
    }
    
    private func saveAllSettings() {
        // 保存所有设置
        settingsManager.apiEndpoint = apiEndpoint
        settingsManager.modelName = modelName
        
        // 保存 API Key（如果输入框有内容且不是占位符）
        if !apiKey.isEmpty && apiKey != placeholder {
            if settingsManager.saveAPIKey(apiKey) {
                hasSavedKey = true
                savedKeyLength = apiKey.count
                // 保存后，如果不显示，恢复占位符
                if !showAPIKey {
                    apiKey = placeholder
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
}

// Shortcuts 设置页面
struct ShortcutsSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var hasAccessibilityPermission: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 快捷键部分
                VStack(alignment: .leading, spacing: 16) {
                    Text("Shortcut")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shortcut Recorder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ShortcutRecorderView(
                            keyCode: $settingsManager.shortcutKeyCode,
                            modifiers: $settingsManager.shortcutModifiers
                        )
                        .frame(height: 24)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // 权限部分
                VStack(alignment: .leading, spacing: 16) {
                    Text("Permissions")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accessibility API Access")
                                .font(.subheadline)
                            Text("Required for text selection capture")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if hasAccessibilityPermission {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        } else {
                            Button("Open System Settings") {
                                openSystemSettings()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkAccessibilityPermission()
        }
    }
    
    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

