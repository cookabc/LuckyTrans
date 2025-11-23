import Cocoa
import SwiftUI
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var shortcutManager: ShortcutManager?
    private var translationWindow: FloatingTranslationWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标，仅显示在菜单栏
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化快捷键管理器
        shortcutManager = ShortcutManager()
        shortcutManager?.delegate = self
        
        // 初始化菜单栏
        MenuBarManager.shared.setup()
        
        // 检查辅助功能权限
        checkAccessibilityPermission()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        shortcutManager?.unregister()
    }
    
    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showAccessibilityPermissionAlert()
            }
        }
    }
    
    private func showAccessibilityPermissionAlert() {
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
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            return
        }
        
        // 获取选中的文本
        guard let selectedText = TextCaptureManager.shared.getSelectedText() else {
            showError("无法获取选中的文本，请确保已授予辅助功能权限")
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

