import Cocoa
import SwiftUI
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var translationWindow: FloatingTranslationWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用保存的主题设置（SettingsManager 初始化时会自动应用）
        // 这里确保在窗口创建前应用主题
        _ = SettingsManager.shared
        
        // 配置快捷键处理器
        setupShortcuts()
        
        // 监听来自菜单栏的触发通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTriggerSelectionTranslate),
            name: NSNotification.Name("TriggerSelectionTranslate"),
            object: nil
        )
        
        // 检查辅助功能权限
        checkAccessibilityPermission()
        
        // 显示主窗口
        MainWindowManager.shared.showMainWindow()
    }
    
    private func setupShortcuts() {
        // 注册动作处理器
        EnhancedShortcutManager.shared.registerActionHandler(for: .translateSelection) { [weak self] in
            self?.handleSelectionTranslate()
        }
        
        EnhancedShortcutManager.shared.registerActionHandler(for: .screenshotOCR) {
            // TODO: 实现截图 OCR
            print("触发截图 OCR")
            Task { @MainActor in
                SimpleOCREngine.shared.captureAndRecognize { result in
                    // Handle result
                    switch result {
                    case .success(let text):
                        // Show translation window with text
                        DispatchQueue.main.async { [weak self] in
                            self?.showTranslationWindow(with: .loading(text))
                            // Trigger translation
                            self?.translateText(text)
                        }
                    case .failure(let error):
                        print("OCR Error: \(error)")
                    }
                }
            }
        }
        
        EnhancedShortcutManager.shared.registerActionHandler(for: .openSettings) {
            SettingsWindowManager.shared.showSettings()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        translationWindow?.close()
        translationWindow = nil
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 即使主窗口关闭，应用也不退出（因为有菜单栏图标）
        return false
    }
    
    @objc private func handleTriggerSelectionTranslate() {
        handleSelectionTranslate()
    }
    
    private func checkAccessibilityPermission() {
        // 检查是否已经授予权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // 如果权限已授予，直接返回
        if accessEnabled {
            return
        }
        
        // 检查用户是否已经看到过提示（避免每次都弹出）
        let hasShownAlert = UserDefaults.standard.bool(forKey: "hasShownAccessibilityAlert")
        
        // 如果已经显示过提示，就不再自动弹出
        if hasShownAlert {
            return
        }
        
        // 只在首次启动且未授予权限时提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showAccessibilityPermissionAlert()
        }
    }
    
    private func showAccessibilityPermissionAlert() {
        // 标记已经显示过提示
        UserDefaults.standard.set(true, forKey: "hasShownAccessibilityAlert")
        
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "LuckyTrans 需要辅助功能权限来获取您选中的文本。请在系统设置中授予权限。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

extension AppDelegate {
    private func handleSelectionTranslate() {
        // 1. 检查权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !hasPermission {
            // 没有权限，引导用户去设置
            MainWindowManager.shared.showMainWindow()
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateSelectedText"),
                object: nil,
                userInfo: ["error": "无法获取选中的文本，请确保已授予辅助功能权限。\n\n请在系统设置 > 隐私与安全性 > 辅助功能中启用 LuckyTrans"]
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }
        
        // 2. 获取文本
        let capturedText = TextCaptureManager.shared.getSelectedText()
        
        guard let text = capturedText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
             MainWindowManager.shared.showMainWindow()
             NotificationCenter.default.post(
                 name: NSNotification.Name("UpdateSelectedText"),
                 object: nil,
                 userInfo: ["error": "未检测到选中的文本。请先选中文本。"]
             )
            return
        }
        
        // 3. 执行翻译
        translateText(text)
    }
    
    private func translateText(_ text: String) {
        showTranslationWindow(with: .loading(text))
        
        Task {
            do {
                let targetLang = SettingsManager.shared.targetLanguage
                let translation = try await TranslationServiceManager.shared.translate(text: text, to: targetLang)
                
                await MainActor.run {
                    showTranslationWindow(with: .success(original: text, translation: translation))
                }
            } catch {
                await MainActor.run {
                    showTranslationWindow(with: .error(error.localizedDescription))
                }
            }
        }
    }
    
    private func showTranslationWindow(with state: TranslationWindowState) {
        if translationWindow == nil {
            translationWindow = FloatingTranslationWindow()
        }
        translationWindow?.show(with: state)
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "错误"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
