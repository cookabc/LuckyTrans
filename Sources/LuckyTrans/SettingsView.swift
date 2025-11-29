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
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
                .background(Color(NSColor.controlBackgroundColor))
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
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    EmptyView()
                }
            }
            .toolbar(.hidden, for: .windowToolbar)
        }
        .toolbar(.hidden, for: .windowToolbar)
        .frame(width: 700, height: 500)
    }
}

// 侧边栏组件
struct SettingsSidebar: View {
    @Binding var selectedPage: SettingsPage
    
    var body: some View {
        List(selection: $selectedPage) {
            ForEach(SettingsPage.allCases) { page in
                Label {
                    Text(page.title)
                        .font(.system(size: 13, weight: .medium))
                } icon: {
                    Image(systemName: page.icon)
                        .foregroundColor(.accentColor)
                }
                .tag(page)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
    }
}

// General 设置页面
struct GeneralSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("General")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Preferences")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Launch at login", isOn: .constant(false)) // Placeholder
                        Toggle("Show in menu bar", isOn: .constant(true)) // Placeholder
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding(30)
        }
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
            return String(repeating: "•", count: min(savedKeyLength, 20))
        }
        return "••••••••••••" // 默认占位符
    }
    
    // 可用的模型列表
    private let availableModels = ["GLM-4.6", "gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("API & Models")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // API 配置部分
                VStack(alignment: .leading, spacing: 16) {
                    Label("Configuration", systemImage: "server.rack")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // API 端点
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Endpoint")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("https://api.example.com/v1", text: $apiEndpoint)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // API Key
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 0) {
                                if showAPIKey {
                                    TextField("sk-...", text: $apiKey)
                                        .textFieldStyle(.plain)
                                        .padding(10)
                                } else {
                                    SecureField("sk-...", text: Binding(
                                        get: { apiKey.isEmpty && hasSavedKey ? placeholder : apiKey },
                                        set: { apiKey = $0 }
                                    ))
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                }
                                
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
                                            apiKey = "" // Clear to show placeholder in get binding
                                        }
                                    }
                                    showAPIKey.toggle()
                                }) {
                                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 10)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
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
                            .labelsHidden()
                            .frame(maxWidth: 200)
                        }
                    }
                    .padding(20)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 外观部分
                VStack(alignment: .leading, spacing: 16) {
                    Label("Appearance", systemImage: "paintpalette")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // 主题模式
                        HStack {
                            Text("Theme Mode")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $settingsManager.appearanceMode) {
                                ForEach(SettingsManager.AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                    }
                    .padding(20)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 保存按钮
                HStack {
                    Spacer()
                    Button(action: saveAllSettings) {
                        Text("Save Changes")
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.accentColor)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(30)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            apiEndpoint = settingsManager.apiEndpoint
            modelName = settingsManager.modelName
            hasSavedKey = settingsManager.hasAPIKey()
            // 如果有已保存的 key，获取其长度并设置占位符
            if hasSavedKey, let savedKey = settingsManager.getAPIKey() {
                savedKeyLength = savedKey.count
                // apiKey 初始为空，由 Binding 处理显示 placeholder
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
            VStack(alignment: .leading, spacing: 24) {
                Text("Shortcuts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 快捷键部分
                VStack(alignment: .leading, spacing: 16) {
                    Label("Global Shortcut", systemImage: "keyboard")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activation Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ShortcutRecorderView(
                                keyCode: $settingsManager.shortcutKeyCode,
                                modifiers: $settingsManager.shortcutModifiers
                            )
                            .frame(height: 28)
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 权限部分
                VStack(alignment: .leading, spacing: 16) {
                    Label("Permissions", systemImage: "lock.shield")
                        .font(.headline)
                    
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Accessibility Access")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Required to capture selected text from other apps.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if hasAccessibilityPermission {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Granted")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        } else {
                            Button("Open Settings") {
                                openSystemSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(30)
        }
        .background(Color(NSColor.windowBackgroundColor))
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

