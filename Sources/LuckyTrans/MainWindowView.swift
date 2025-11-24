import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedText: String = ""
    @State private var translation: String = ""
    @State private var isTranslating: Bool = false
    @State private var errorMessage: String?
    
    private let languages = ["中文", "English", "日本語", "한국어", "Français", "Deutsch", "Español", "Italiano", "Português", "Русский"]
    
    private func openSettingsWindow() {
        SettingsWindowManager.shared.showSettings()
    }
    
    private func translateText() {
        let textToTranslate = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToTranslate.isEmpty else {
            errorMessage = "请输入要翻译的文本"
            return
        }
        
        guard settingsManager.hasAPIKey() else {
            errorMessage = "请先在设置中配置 API Key"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                openSettingsWindow()
            }
            return
        }
        
        isTranslating = true
        errorMessage = nil
        translation = ""
        
        Task {
            do {
                let result = try await TranslationService.shared.translate(
                    text: textToTranslate,
                    targetLanguage: settingsManager.targetLanguage
                )
                
                await MainActor.run {
                    translation = result
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "翻译失败: \(error.localizedDescription)"
                    isTranslating = false
                }
            }
        }
    }
    
    private func getSelectedTextFromSystem() {
        if let text = TextCaptureManager.shared.getSelectedText() {
            selectedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            errorMessage = "无法获取选中的文本，请确保已授予辅助功能权限"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                Text("LuckyTrans")
                    .font(.headline)
                Spacer()
                Button(action: openSettingsWindow) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("设置")
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
            
            // 目标语言选择
            HStack {
                Text("目标语言:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $settingsManager.targetLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 150)
                
                Spacer()
                
                Button(action: getSelectedTextFromSystem) {
                    Label("获取选中文本", systemImage: "text.cursor")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            
            // 原文输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("原文:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $selectedText)
                    .font(.system(.body, design: .default))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            // 翻译按钮
            Button(action: translateText) {
                HStack {
                    if isTranslating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                        Text("翻译中...")
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("翻译")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isTranslating || selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
            
            // 翻译结果
            VStack(alignment: .leading, spacing: 8) {
                Text("翻译:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else if translation.isEmpty && !isTranslating {
                        Text("翻译结果将显示在这里")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text(translation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
                .frame(height: 120)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 600, height: 500)
        .onAppear {
            // 首次启动时，如果没有配置 API Key，自动打开设置窗口
            if !settingsManager.hasAPIKey() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    openSettingsWindow()
                }
            }
        }
    }
}

