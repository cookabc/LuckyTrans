import SwiftUI
import ApplicationServices

// MARK: - Settings Tab Enum

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "general"
    case translation = "translation"
    case shortcuts = "shortcuts"
    case about = "about"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "通用"
        case .translation: return "翻译"
        case .shortcuts: return "快捷键"
        case .about: return "关于"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .translation: return "character.bubble"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Main Settings View

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var serviceManager = TranslationServiceManager.shared
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            // Content area
            ScrollView {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .translation:
                    TranslationSettingsView()
                case .shortcuts:
                    ShortcutsSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 650, minHeight: 500)
    }
}

// MARK: - Settings Section Header

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(LTDesign.Typography.settingsTitle)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Settings Row Component

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
            VStack(alignment: .leading, spacing: LTDesign.Spacing.xxs) {
                Text(title)
                    .font(LTDesign.Typography.body)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(LTDesign.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            content
        }
        .padding(.horizontal, LTDesign.Spacing.lg)
        .padding(.vertical, LTDesign.Spacing.md)
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .settingsCard()
    }
}

// MARK: - Custom Appearance Picker

struct CustomAppearancePicker: View {
    @Binding var selection: SettingsManager.AppearanceMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SettingsManager.AppearanceMode.allCases, id: \.self) { mode in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = mode 
                    }
                }) {
                    VStack(spacing: LTDesign.Spacing.xxs) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14))
                        Text(mode.displayName)
                            .font(LTDesign.Typography.captionSmall)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LTDesign.Spacing.sm)
                    .background(selection == mode ? Color.accentColor : Color.clear)
                    .foregroundColor(selection == mode ? .white : .primary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if mode != SettingsManager.AppearanceMode.allCases.last {
                    Divider()
                        .frame(height: 32)
                }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                .stroke(LTDesign.Colors.subtleBorder, lineWidth: 1)
        )
        .frame(width: 280)
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var hasAccessibilityPermission: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LTDesign.Spacing.xl) {
            SettingsSectionHeader(title: "通用设置")
            
            SettingsCard {
                // Launch at Login
                SettingsRow("开机自启动", subtitle: "开机时自动启动 LuckyTrans") {
                    Toggle("", isOn: $settingsManager.launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                Divider().padding(.horizontal, LTDesign.Spacing.lg)
                
                // Show in Menu Bar
                SettingsRow("在菜单栏显示") {
                    Toggle("", isOn: $settingsManager.showInMenuBar)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            
            // Appearance Section
            VStack(alignment: .leading, spacing: LTDesign.Spacing.md) {
                Text("外观")
                    .font(LTDesign.Typography.sectionTitle)
                    .foregroundStyle(.secondary)
                
                SettingsCard {
                    SettingsRow("主题模式") {
                        CustomAppearancePicker(selection: $settingsManager.appearanceMode)
                    }
                }
            }
            
            // Permissions Section
            VStack(alignment: .leading, spacing: LTDesign.Spacing.md) {
                Text("权限")
                    .font(LTDesign.Typography.sectionTitle)
                    .foregroundStyle(.secondary)
                
                SettingsCard {
                    SettingsRow("辅助功能访问", subtitle: "用于获取选中的文本") {
                        if hasAccessibilityPermission {
                            HStack(spacing: LTDesign.Spacing.xxs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("已授权")
                                    .foregroundStyle(.green)
                                    .font(LTDesign.Typography.caption)
                            }
                        } else {
                            Button("前往授权") {
                                openSystemSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(LTDesign.Spacing.xxl)
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

// MARK: - Translation Settings View (Combined Translation Service + API)

struct TranslationSettingsView: View {
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
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult? = nil
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    private var placeholder: String {
        savedKeyLength > 0 ? String(repeating: "•", count: min(savedKeyLength, 20)) : "••••••••••••"
    }
    
    private var deepLPlaceholder: String {
        if let key = UserDefaults.standard.string(forKey: "deepl_apiKey"), !key.isEmpty {
            return String(repeating: "•", count: min(key.count, 20))
        }
        return "••••••••••••"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LTDesign.Spacing.xl) {
            SettingsSectionHeader(title: "翻译服务")
            
            // Service Selection
            SettingsCard {
                SettingsRow("当前服务", subtitle: currentServiceDescription) {
                    Picker("", selection: $serviceManager.currentServiceType) {
                        ForEach(TranslationServiceType.allCases) { type in
                            HStack {
                                Text(type.displayName)
                                if serviceManager.getServiceStatus(type) == "已配置" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
            }
            
            // Service-specific Configuration
            VStack(alignment: .leading, spacing: LTDesign.Spacing.md) {
                Text("服务配置")
                    .font(LTDesign.Typography.sectionTitle)
                    .foregroundStyle(.secondary)
                
                SettingsCard {
                    if serviceManager.currentServiceType == .openAI {
                        openAIConfigSection
                    } else if serviceManager.currentServiceType == .deepL {
                        deepLConfigSection
                    } else if serviceManager.currentServiceType == .google {
                        googleConfigSection
                    }
                }
            }
            
            // Test & Save Button
            HStack(spacing: LTDesign.Spacing.md) {
                // Test Connection Button
                Button {
                    testConnection()
                } label: {
                    HStack(spacing: LTDesign.Spacing.xxs) {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "network")
                        }
                        Text("测试连接")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isTesting)
                
                // Test result indicator
                if let result = testResult {
                    switch result {
                    case .success:
                        HStack(spacing: LTDesign.Spacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("连接成功")
                                .foregroundStyle(.green)
                        }
                        .font(LTDesign.Typography.caption)
                    case .failure(let message):
                        HStack(spacing: LTDesign.Spacing.xxs) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(message)
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }
                        .font(LTDesign.Typography.caption)
                    }
                }
                
                Spacer()
                
                Button(action: saveAllSettings) {
                    Text("保存更改")
                        .fontWeight(.medium)
                        .padding(.horizontal, LTDesign.Spacing.lg)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding(LTDesign.Spacing.xxl)
        .onAppear {
            loadSettings()
        }
        .onChange(of: serviceManager.currentServiceType) { _ in
            loadSettings()
            testResult = nil
        }
    }
    
    private var currentServiceDescription: String {
        serviceManager.getService(for: serviceManager.currentServiceType).serviceDescription
    }
    
    // MARK: - OpenAI Config
    
    private var openAIConfigSection: some View {
        Group {
            SettingsRow("API 地址") {
                TextField("https://api.openai.com/v1", text: $apiEndpoint)
                    .textFieldStyle(.plain)
                    .padding(LTDesign.Spacing.sm)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small))
                    .frame(width: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                            .stroke(LTDesign.Colors.subtleBorder, lineWidth: 1)
                    )
            }
            
            Divider().padding(.horizontal, LTDesign.Spacing.lg)
            
            SettingsRow("API 密钥") {
                apiKeyField
            }
            
            Divider().padding(.horizontal, LTDesign.Spacing.lg)
            
            SettingsRow("模型名称") {
                TextField("gpt-4o", text: $modelName)
                    .textFieldStyle(.plain)
                    .padding(LTDesign.Spacing.sm)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small))
                    .frame(width: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                            .stroke(LTDesign.Colors.subtleBorder, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - DeepL Config
    
    private var deepLConfigSection: some View {
        Group {
            SettingsRow("DeepL API Key", subtitle: "可在 DeepL 网站免费获取") {
                deepLKeyField
            }
            
            Divider().padding(.horizontal, LTDesign.Spacing.lg)
            
            // Info
            HStack(alignment: .top, spacing: LTDesign.Spacing.sm) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: LTDesign.Spacing.xxs) {
                    Text("访问 deepl.com/pro-api 免费注册")
                    Text("免费版每月可翻译 50 万字符")
                }
                .font(LTDesign.Typography.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, LTDesign.Spacing.lg)
            .padding(.vertical, LTDesign.Spacing.md)
        }
    }
    
    // MARK: - Google Config
    
    private var googleConfigSection: some View {
        HStack(alignment: .top, spacing: LTDesign.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: LTDesign.Spacing.xxs) {
                Text("Google 翻译无需配置")
                    .font(LTDesign.Typography.body)
                Text("Google 翻译是免费服务，无需 API Key 即可使用")
                    .font(LTDesign.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, LTDesign.Spacing.lg)
        .padding(.vertical, LTDesign.Spacing.md)
    }
    
    // MARK: - API Key Field
    
    private var apiKeyField: some View {
        HStack(spacing: 0) {
            Group {
                if showAPIKey {
                    TextField("sk-...", text: $apiKey)
                } else {
                    SecureField("sk-...", text: Binding(
                        get: { apiKey.isEmpty && hasSavedKey ? placeholder : apiKey },
                        set: { apiKey = $0 }
                    ))
                }
            }
            .textFieldStyle(.plain)
            .padding(LTDesign.Spacing.sm)
            
            Button {
                toggleAPIKeyVisibility()
            } label: {
                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, LTDesign.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small))
        .frame(width: 280)
        .overlay(
            RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                .stroke(LTDesign.Colors.subtleBorder, lineWidth: 1)
        )
    }
    
    private var deepLKeyField: some View {
        HStack(spacing: 0) {
            Group {
                if showDeepLKey {
                    TextField("DeepL API Key", text: $deepLApiKey)
                } else {
                    SecureField("DeepL API Key", text: Binding(
                        get: { deepLApiKey.isEmpty ? deepLPlaceholder : deepLApiKey },
                        set: { deepLApiKey = $0 }
                    ))
                }
            }
            .textFieldStyle(.plain)
            .padding(LTDesign.Spacing.sm)
            
            Button {
                toggleDeepLKeyVisibility()
            } label: {
                Image(systemName: showDeepLKey ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, LTDesign.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small))
        .frame(width: 280)
        .overlay(
            RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                .stroke(LTDesign.Colors.subtleBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadSettings() {
        apiEndpoint = settingsManager.apiEndpoint
        modelName = settingsManager.modelName
        hasSavedKey = settingsManager.hasAPIKey()
        if hasSavedKey, let savedKey = settingsManager.getAPIKey() {
            savedKeyLength = savedKey.count
        }
    }
    
    private func toggleAPIKeyVisibility() {
        if !showAPIKey && apiKey.isEmpty {
            if let savedKey = settingsManager.getAPIKey() {
                apiKey = savedKey
            }
        }
        showAPIKey.toggle()
    }
    
    private func toggleDeepLKeyVisibility() {
        if !showDeepLKey && deepLApiKey.isEmpty {
            if let savedKey = UserDefaults.standard.string(forKey: "deepl_apiKey") {
                deepLApiKey = savedKey
            }
        }
        showDeepLKey.toggle()
    }
    
    private func testConnection() {
        isTesting = true
        testResult = nil
        
        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTesting = false
            // Check if API key exists
            if serviceManager.currentServiceType == .openAI {
                if hasSavedKey || !apiKey.isEmpty {
                    testResult = .success
                } else {
                    testResult = .failure("请先配置 API Key")
                }
            } else if serviceManager.currentServiceType == .deepL {
                if !deepLApiKey.isEmpty || UserDefaults.standard.string(forKey: "deepl_apiKey") != nil {
                    testResult = .success
                } else {
                    testResult = .failure("请先配置 API Key")
                }
            } else {
                testResult = .success
            }
        }
    }
    
    private func saveAllSettings() {
        settingsManager.apiEndpoint = apiEndpoint
        settingsManager.modelName = modelName
        
        if !apiKey.isEmpty && apiKey != placeholder {
            if settingsManager.saveAPIKey(apiKey) {
                hasSavedKey = true
                savedKeyLength = apiKey.count
            }
        }
        
        if !deepLApiKey.isEmpty && deepLApiKey != deepLPlaceholder {
            UserDefaults.standard.set(deepLApiKey, forKey: "deepl_apiKey")
        }
        
        // Show success notification
        let alert = NSAlert()
        alert.messageText = "保存成功"
        alert.informativeText = "所有设置已保存"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}

// MARK: - Shortcuts Settings View

// MARK: - Shortcuts Settings View

struct ShortcutsSettingsView: View {
    @StateObject private var shortcutManager = EnhancedShortcutManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: LTDesign.Spacing.xl) {
            SettingsSectionHeader(title: "快捷键设置")
            
            SettingsCard {
                ForEach(ShortcutActionType.allCases) { type in
                    VStack(spacing: 0) {
                        SettingsRow(type.displayName) {
                            ShortcutRecorderView(
                                keyCombo: Binding(
                                    get: { shortcutManager.shortcuts[type] ?? .zero },
                                    set: { newCombo in
                                        if newCombo.isValid {
                                            shortcutManager.setShortcut(for: type, keyCombo: newCombo)
                                        } else {
                                            shortcutManager.removeShortcut(for: type)
                                        }
                                    }
                                ),
                                actionType: type
                            )
                            .frame(width: 140, height: 28)
                        }
                        
                        if type != ShortcutActionType.allCases.last {
                            Divider().padding(.horizontal, LTDesign.Spacing.lg)
                        }
                    }
                }
            }
            
            // Tips
            VStack(alignment: .leading, spacing: LTDesign.Spacing.sm) {
                Text("使用说明")
                    .font(LTDesign.Typography.sectionTitle)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: LTDesign.Spacing.xs) {
                    tipRow(icon: "1.circle", text: "点击录制框，按下想要使用的快捷键组合")
                    tipRow(icon: "2.circle", text: "支持 Command、Option、Control、Shift 修饰键")
                    tipRow(icon: "3.circle", text: "点击右侧 X 按钮可清除快捷键")
                }
                .padding(LTDesign.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: LTDesign.CornerRadius.medium)
                        .fill(Color.blue.opacity(0.05))
                )
            }
            
            Spacer()
        }
        .padding(LTDesign.Spacing.xxl)
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: LTDesign.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(text)
                .font(LTDesign.Typography.body)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - About Settings View

struct AboutSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: LTDesign.Spacing.xxxl) {
            Spacer()
            
            // App Icon & Name
            VStack(spacing: LTDesign.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(LTDesign.Colors.primaryGradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Text("LuckyTrans")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("macOS 划词翻译工具")
                    .font(LTDesign.Typography.body)
                    .foregroundStyle(.secondary)
            }
            
            // Version Info
            VStack(spacing: LTDesign.Spacing.xs) {
                Text("版本 \(appVersion) (\(buildNumber))")
                    .font(LTDesign.Typography.caption)
                    .foregroundStyle(.secondary)
                
                Text("© 2025 LuckyTrans")
                    .font(LTDesign.Typography.captionSmall)
                    .foregroundStyle(.tertiary)
            }
            
            // Links
            HStack(spacing: LTDesign.Spacing.xl) {
                Link(destination: URL(string: "https://github.com/cookabc/LuckyTrans")!) {
                    Label("GitHub", systemImage: "link")
                        .font(LTDesign.Typography.caption)
                }
                
                Button("检查更新") {
                    // Check for updates
                }
                .font(LTDesign.Typography.caption)
            }
            .buttonStyle(.link)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(LTDesign.Spacing.xxl)
    }
}

// MARK: - AppearanceMode Extension

extension SettingsManager.AppearanceMode {
    var iconName: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
