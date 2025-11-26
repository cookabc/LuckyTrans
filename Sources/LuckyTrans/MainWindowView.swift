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
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("LuckyTrans")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: openSettingsWindow) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("设置")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 主要内容区域
            VStack(spacing: 0) {
                // 工具栏
                HStack(spacing: 12) {
                    // 目标语言选择
                    HStack(spacing: 8) {
                        Text("目标语言")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $settingsManager.targetLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    Spacer()
                    
                    // 获取选中文本按钮
                    Button(action: getSelectedTextFromSystem) {
                        Label("获取选中文本", systemImage: "text.cursor")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                Divider()
                
                // 原文输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("原文")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $selectedText)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(4)
                            .frame(minHeight: 150)
                        
                        if selectedText.isEmpty {
                            Text("输入要翻译的文本，或点击「获取选中文本」按钮")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    
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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // 翻译按钮
                HStack {
                    Button(action: translateText) {
                        HStack(spacing: 8) {
                            if isTranslating {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            Text(isTranslating ? "翻译中..." : "翻译")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isTranslating || selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                Divider()
                
                // 翻译结果区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("翻译")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if !translation.isEmpty {
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(translation, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("复制翻译结果")
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if isTranslating {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                        Text("翻译中...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
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
                    .frame(minHeight: 150)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
        .onDisappear {
            // 窗口关闭时，取消所有异步任务
            translationTask?.cancel()
            translationTask = nil
            isTranslating = false
        }
    }
}
