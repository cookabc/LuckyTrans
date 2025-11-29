import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedText: String = ""
    @State private var translation: String = ""
    @State private var isTranslating: Bool = false
    @State private var errorMessage: String?
    @State private var translationTask: Task<Void, Never>?
    
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
        
        // 取消之前的任务
        translationTask?.cancel()
        
        isTranslating = true
        errorMessage = nil
        translation = ""
        
        translationTask = Task {
            do {
                let result = try await TranslationService.shared.translate(
                    text: textToTranslate,
                    targetLanguage: settingsManager.targetLanguage
                )
                
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    translation = result
                    isTranslating = false
                    errorMessage = nil
                }
            } catch let translationError as TranslationError {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    let errorMsg = translationError.error.message
                    let errorType = translationError.error.type ?? "unknown_error"
                    errorMessage = "翻译失败: \(errorMsg) (类型: \(errorType))"
                    isTranslating = false
                }
            } catch let urlError as URLError {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    var errorMsg = "网络连接失败"
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMsg = "未连接到互联网"
                    case .timedOut:
                        errorMsg = "请求超时，请检查网络连接"
                    case .cannotFindHost:
                        errorMsg = "无法找到服务器，请检查 API 端点配置"
                    case .cannotConnectToHost:
                        errorMsg = "无法连接到服务器"
                    default:
                        errorMsg = "网络错误: \(urlError.localizedDescription)"
                    }
                    errorMessage = errorMsg
                    isTranslating = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    errorMessage = "翻译失败: \(error.localizedDescription)"
                    isTranslating = false
                }
            }
        }
    }
    
    private func getSelectedTextFromSystem() {
        if let text = TextCaptureManager.shared.getSelectedText() {
            selectedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            errorMessage = nil
        } else {
            // 检查权限状态
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            if hasPermission {
                errorMessage = "无法获取选中的文本。请先选中文本，或尝试在文本编辑器中使用。"
            } else {
                errorMessage = "无法获取选中的文本，请确保已授予辅助功能权限"
            }
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    // 获取翻译方向显示文本
    private var translationDirection: String {
        let source = "Auto"
        let target = settingsManager.targetLanguage
        return "\(source) → \(target)"
    }
    
    var body: some View {
        ZStack {
            // 增强的毛玻璃背景
            Color.clear
                .background(.ultraThinMaterial)
            
            VStack(spacing: 24) {
                // 标题栏（带毛玻璃效果）
                HStack {
                    HStack(spacing: 12) {
                        Text(translationDirection)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // 语言选择器（简化版）
                        Picker("", selection: $settingsManager.targetLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    // 获取选中文本按钮（简化）
                    Button(action: getSelectedTextFromSystem) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("AI 获取选中文本")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: openSettingsWindow) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .help("设置")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // 原文输入区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("原文")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $selectedText)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 180)
                        
                        if selectedText.isEmpty {
                            Text("输入要翻译的文本,或点击「获取选中文本」按钮")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 16)
                                .padding(.top, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    
                    if let error = errorMessage, !error.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 24)
                
                // 翻译按钮
                Button(action: translateText) {
                    HStack(spacing: 8) {
                        if isTranslating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                                .fontWeight(.semibold)
                        }
                        Text(isTranslating ? "翻译中..." : "翻译")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isTranslating || selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 24)
                
                // 翻译结果区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("翻译")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                if isTranslating {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(0.9)
                                            .padding(.vertical, 50)
                                        Spacer()
                                    }
                                } else if !translation.isEmpty {
                                    Text(translation)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                } else if let error = errorMessage, !error.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.body)
                                            .foregroundColor(.red)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                } else {
                                    HStack {
                                        Spacer()
                                        Text("翻译结果将显示在这里")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 50)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 180)
                        
                        // 按钮在底部右侧
                        if !translation.isEmpty {
                            HStack(spacing: 12) {
                                // 复制按钮
                                Button(action: {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(translation, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("复制翻译结果")
                                
                                // 扬声器按钮
                                Button(action: {
                                    // TODO: 实现文本转语音功能
                                }) {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("朗读翻译结果")
                            }
                            .padding(16)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 650, minHeight: 600)
        .onAppear {
            // 首次启动时，如果没有配置 API Key，自动打开设置窗口
            if !settingsManager.hasAPIKey() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak settingsManager] in
                    // 检查窗口是否仍然存在
                    guard settingsManager != nil else { return }
                    openSettingsWindow()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateSelectedText"))) { notification in
            // 监听快捷键触发的文本更新通知
            if let text = notification.userInfo?["text"] as? String {
                selectedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                errorMessage = nil
            } else if let error = notification.userInfo?["error"] as? String {
                errorMessage = error
            }
        }
        .onDisappear {
            // 窗口关闭时，取消所有异步任务
            translationTask?.cancel()
            translationTask = nil
            isTranslating = false
        }
    }
}
