import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedText: String = ""
    @State private var translation: String = ""
    @State private var isTranslating: Bool = false
    @State private var errorMessage: String?
    @State private var translationTask: Task<Void, Never>?
    
    private let languages = ["中文", "英语", "日语", "韩语", "法语", "德语", "西班牙语", "意大利语", "葡萄牙语", "俄语"]
    
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
        let source = "自动"
        let target = settingsManager.targetLanguage
        return "\(source) → \(target)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏区域
            HStack(alignment: .center) {
                // 语言选择
                HStack(spacing: 8) {
                    Text("自动")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    
                    Picker("", selection: $settingsManager.targetLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 110)
                    .labelsHidden()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                Spacer()
                
                // 工具按钮组
                HStack(spacing: 12) {
                    // 获取选中文本按钮
                    Button(action: getSelectedTextFromSystem) {
                        Image(systemName: "text.cursor")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("获取选中文本")
                    
                    // 设置按钮
                    Button(action: openSettingsWindow) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("设置")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
                .opacity(0.5)
            
            // 主要内容区域
            ScrollView {
                VStack(spacing: 20) {
                    // 原文输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("原文", systemImage: "text.quote")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            if !selectedText.isEmpty {
                                Button(action: { selectedText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if selectedText.isEmpty {
                                Text("输入要翻译的文本，或点击上方「获取选中文本」按钮")
                                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            
                            TextEditor(text: $selectedText)
                                .font(.system(size: 15))
                                .lineSpacing(4)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                        }
                        .padding(12)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                        
                        if let error = errorMessage, !error.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                            }
                            .font(.caption)
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // 翻译按钮
                    Button(action: translateText) {
                        HStack(spacing: 8) {
                            if isTranslating {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isTranslating ? "正在翻译..." : "开始翻译")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                    .foregroundColor(.white)
                    .disabled(isTranslating || selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((isTranslating || selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1)
                    
                    // 翻译结果区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("译文", systemImage: "character.book.closed")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            if !translation.isEmpty {
                                HStack(spacing: 16) {
                                    Button(action: {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(translation, forType: .string)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("复制")
                                    
                                    Button(action: {
                                        // TODO: TTS
                                    }) {
                                        Image(systemName: "speaker.wave.2")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("朗读")
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if isTranslating {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("AI 正在思考中...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 40)
                                    Spacer()
                                }
                            } else if !translation.isEmpty {
                                Text(translation)
                                    .font(.system(size: 15))
                                    .lineSpacing(4)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 12) {
                                        Image(systemName: "globe.asia.australia")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                        Text("翻译结果将显示在这里")
                                            .font(.callout)
                                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                    }
                                    .padding(.vertical, 40)
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                        .frame(minHeight: 150, alignment: .top)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .padding(24)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 500)
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
