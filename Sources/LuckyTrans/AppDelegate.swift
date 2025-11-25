import Cocoa
import SwiftUI
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var shortcutManager: ShortcutManager?
    private var translationWindow: FloatingTranslationWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 保持 Dock 图标可见，这样用户可以看到主窗口
        // NSApp.setActivationPolicy(.accessory)  // 注释掉，保留 Dock 图标
        
        // 应用保存的主题设置（SettingsManager 初始化时会自动应用）
        // 这里确保在窗口创建前应用主题
        _ = SettingsManager.shared
        
        // 初始化快捷键管理器
        shortcutManager = ShortcutManager()
        shortcutManager?.delegate = self
        
        // 初始化菜单栏
        MenuBarManager.shared.setup()
        
        // 检查辅助功能权限
        checkAccessibilityPermission()
        
        // 激活应用并显示窗口
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        shortcutManager?.unregister()
        translationWindow?.close()
        translationWindow = nil
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 即使主窗口关闭，应用也不退出（因为有菜单栏图标）
        return false
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

extension AppDelegate: ShortcutManagerDelegate {
    func shortcutDidTrigger() {
        handleTranslationRequest()
    }
    
    private func handleTranslationRequest() {
        // 检查 API Key 是否配置
        guard SettingsManager.shared.hasAPIKey() else {
            showError("请先在设置中配置 API Key")
            // 打开设置窗口
            SettingsWindowManager.shared.showSettings()
            return
        }
        
        // 检查权限状态
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // 如果没有权限，提示用户
        if !hasPermission {
            showError("无法获取选中的文本，请确保已授予辅助功能权限。\n\n请在系统设置 > 隐私与安全性 > 辅助功能中启用 LuckyTrans")
            // 打开系统设置
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        
        // 获取选中的文本
        guard let selectedText = TextCaptureManager.shared.getSelectedText() else {
            showError("无法获取选中的文本。\n\n可能的原因：\n1. 当前应用不支持文本选择\n2. 请先选中文本再按快捷键\n3. 尝试在文本编辑器或浏览器中使用")
            return
        }
        
        let trimmedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return
        }
        
        // 显示加载状态
        showTranslationWindow(with: .loading(trimmedText))
        
        // 执行翻译
        Task {
            do {
                let translation = try await TranslationService.shared.translate(
                    text: trimmedText,
                    targetLanguage: SettingsManager.shared.targetLanguage
                )
                
                await MainActor.run {
                    showTranslationWindow(with: .success(original: trimmedText, translation: translation))
                }
            } catch let translationError as TranslationError {
                await MainActor.run {
                    showTranslationWindow(with: .error(translationError.localizedDescription))
                }
            } catch {
                await MainActor.run {
                    showTranslationWindow(with: .error("翻译失败: \(error.localizedDescription)"))
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

