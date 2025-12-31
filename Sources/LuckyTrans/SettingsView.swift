import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var serviceManager = TranslationServiceManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // General Section
                GeneralSettingsView()

                // Translation Service Section
                TranslationServiceSettingsView()

                // API Section
                APIModelsSettingsView()
            }
            .padding(30)
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}


// 通用设置行组件
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    
    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// 自定义主题选择器，确保宽度一致
struct CustomAppearancePicker: View {
    @Binding var selection: SettingsManager.AppearanceMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SettingsManager.AppearanceMode.allCases, id: \.self) { mode in
                Button(action: { selection = mode }) {
                    Text(mode.displayName)
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(selection == mode ? Color.accentColor : Color.clear)
                        .foregroundColor(selection == mode ? .white : .primary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if mode != SettingsManager.AppearanceMode.allCases.last {
                    Divider()
                        .frame(height: 16)
                }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .frame(width: 340)
    }
}

// General 设置页面
struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var hasAccessibilityPermission: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("常规")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 0) {
                // 开机自启动
                SettingsRow("开机自启动") {
                    Toggle("", isOn: $settingsManager.launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                Divider()
                
                // 在菜单栏显示
                SettingsRow("在菜单栏显示") {
                    Toggle("", isOn: $settingsManager.showInMenuBar)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                Divider()
                
                // 主题模式
                SettingsRow("主题模式") {
                    CustomAppearancePicker(selection: $settingsManager.appearanceMode)
                }
                
                Divider()
                
                // 唤起按键
                SettingsRow("唤起按键") {
                    ShortcutRecorderView(
                        keyCode: $settingsManager.shortcutKeyCode,
                        modifiers: $settingsManager.shortcutModifiers
                    )
                    .frame(width: 340, height: 28)
                }
                
                Divider()
                
                // 辅助功能权限
                SettingsRow("辅助功能访问", subtitle: "用于获取选中的文本") {
                    if hasAccessibilityPermission {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已授权")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                    } else {
                        Button("授权") {
                            openSystemSettings()
                        }
                        .controlSize(.small)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
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

// API & Models 设置页面
struct APIModelsSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var serviceManager = TranslationServiceManager.shared
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var apiEndpoint: String = Config.defaultAPIEndpoint
    @State private var modelName: String = Config.defaultModelName
    @State private var hasSavedKey: Bool = false
    @State private var savedKeyLength: Int = 0
    @State private var deepLApiKey: String = ""
    @State private var showDeepLKey: Bool = false

    // 生成与实际 key 长度相同的占位符
    private var placeholder: String {
        if savedKeyLength > 0 {
            return String(repeating: "•", count: savedKeyLength)
        }
        return "••••••••••••" // 默认占位符
    }

    private var deepLPlaceholder: String {
        if let key = UserDefaults.standard.string(forKey: "deepl_apiKey"), !key.isEmpty {
            return String(repeating: "•", count: key.count)
        }
        return "••••••••••••"
    }

    private var isCurrentServiceOpenAI: Bool {
        serviceManager.currentServiceType == .openAI
    }

    private var isCurrentServiceDeepL: Bool {
        serviceManager.currentServiceType == .deepL
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API 与模型")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 0) {
                // 根据当前服务显示不同的配置项

                // OpenAI 配置
                if isCurrentServiceOpenAI {
                    openAIConfigSection
                }

                // DeepL 配置
                if isCurrentServiceDeepL {
                    deepLConfigSection
                }

                // Google 配置（无需配置）
                if serviceManager.currentServiceType == .google {
                    googleConfigSection
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // 保存按钮
            HStack {
                Spacer()
                Button(action: saveAllSettings) {
                    Text("保存更改")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)
            }
        }
        .onAppear {
            apiEndpoint = settingsManager.apiEndpoint
            modelName = settingsManager.modelName
            hasSavedKey = settingsManager.hasAPIKey()
            // 如果有已保存的 key，获取其长度并设置占位符
            if hasSavedKey, let savedKey = settingsManager.getAPIKey() {
                savedKeyLength = savedKey.count
            }
        }
        .onChange(of: serviceManager.currentServiceType) { _ in
            // 切换服务时刷新状态
            hasSavedKey = settingsManager.hasAPIKey()
            if hasSavedKey, let savedKey = settingsManager.getAPIKey() {
                savedKeyLength = savedKey.count
            }
        }
    }

    // MARK: - Service Config Sections

    private var openAIConfigSection: some View {
        Group {
            // API 地址
            SettingsRow("API 地址") {
                TextField("https://...", text: $apiEndpoint)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .frame(width: 340)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }

            Divider()

            // API 密钥
            SettingsRow("API 密钥") {
                apiKeyField
            }

            Divider()

            // 模型名称
            SettingsRow("模型名称") {
                TextField("gpt-3.5-turbo", text: $modelName)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .frame(width: 340)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    private var deepLConfigSection: some View {
        Group {
            // DeepL API 密钥
            SettingsRow("DeepL API Key", subtitle: "可在 DeepL 网站免费获取") {
                HStack(spacing: 0) {
                    if showDeepLKey {
                        TextField("DeepL API Key", text: $deepLApiKey)
                            .textFieldStyle(.plain)
                            .padding(6)
                    } else {
                        SecureField("DeepL API Key", text: Binding(
                            get: { deepLApiKey.isEmpty ? deepLPlaceholder : deepLApiKey },
                            set: { deepLApiKey = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .padding(6)
                    }

                    Button(action: {
                        if !showDeepLKey && deepLApiKey.isEmpty {
                            if let savedKey = UserDefaults.standard.string(forKey: "deepl_apiKey") {
                                deepLApiKey = savedKey
                            }
                        }
                        showDeepLKey.toggle()
                    }) {
                        Image(systemName: showDeepLKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .frame(width: 340)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }

            Divider()

            // 说明文字
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("使用说明")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 访问 https://www.deepl.com/pro-api 免费注册")
                    Text("• 创建 API Key 后在此配置")
                    Text("• 免费版每月可翻译 50 万字符")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var googleConfigSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Google 翻译无需配置")
                        .font(.subheadline)
                }
                Text("Google 翻译是免费服务，无需 API Key 即可使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Helper Views

    private var apiKeyField: some View {
        HStack(spacing: 0) {
            if showAPIKey {
                TextField("sk-...", text: $apiKey)
                    .textFieldStyle(.plain)
                    .padding(6)
            } else {
                SecureField("sk-...", text: Binding(
                    get: { apiKey.isEmpty && hasSavedKey ? placeholder : apiKey },
                    set: { apiKey = $0 }
                ))
                .textFieldStyle(.plain)
                .padding(6)
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
                        apiKey = ""
                    }
                }
                showAPIKey.toggle()
            }) {
                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .frame(width: 340)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func saveAllSettings() {
        // 保存 OpenAI 设置
        settingsManager.apiEndpoint = apiEndpoint
        settingsManager.modelName = modelName

        // 保存 OpenAI API Key
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

        // 保存 DeepL API Key
        if !deepLApiKey.isEmpty && deepLApiKey != deepLPlaceholder {
            UserDefaults.standard.set(deepLApiKey, forKey: "deepl_apiKey")
        }

        // 显示成功提示
        let alert = NSAlert()
        alert.messageText = "保存成功"
        alert.informativeText = "所有设置已保存"
        alert.alertStyle = .informational
        alert.runModal()
    }
}

// MARK: - Translation Service Settings

struct TranslationServiceSettingsView: View {
    @StateObject private var serviceManager = TranslationServiceManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("翻译服务")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 0) {
                // 服务选择
                SettingsRow("翻译服务", subtitle: "选择用于翻译的服务提供商") {
                    Picker("", selection: $serviceManager.currentServiceType) {
                        ForEach(TranslationServiceType.allCases) { type in
                            HStack {
                                Text(type.displayName)
                                if serviceManager.getServiceStatus(type) == "已配置" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }

                Divider()

                // 服务描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("服务说明")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(currentServiceDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private var currentServiceDescription: String {
        serviceManager.getService(for: serviceManager.currentServiceType).serviceDescription
    }
}
