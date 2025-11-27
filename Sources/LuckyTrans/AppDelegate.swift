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
        
        // 显示主窗口
        MainWindowManager.shared.showMainWindow()
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
        // 重要：先获取文本，再显示窗口，避免焦点切换导致无法获取其他应用的文本
        
        // 检查权限状态
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // 如果没有权限，先显示窗口再显示错误
        if !hasPermission {
            MainWindowManager.shared.showMainWindow()
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateSelectedText"),
                object: nil,
                userInfo: ["error": "无法获取选中的文本，请确保已授予辅助功能权限。\n\n请在系统设置 > 隐私与安全性 > 辅助功能中启用 LuckyTrans"]
            )
            // 打开系统设置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }
        
        // 先获取选中的文本（在激活窗口之前）
        let capturedText = TextCaptureManager.shared.getSelectedText()
        
        // 现在才显示主窗口
        MainWindowManager.shared.showMainWindow()
        
        // 处理获取到的文本
        if let selectedText = capturedText {
            let trimmedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedText.isEmpty {
                // 更新主窗口的文本
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateSelectedText"),
                    object: nil,
                    userInfo: ["text": trimmedText]
                )
            } else {
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateSelectedText"),
                    object: nil,
                    userInfo: ["error": "无法获取选中的文本。请先选中文本，或尝试在文本编辑器中使用。"]
                )
            }
        } else {
            // 获取失败，在主窗口显示错误
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateSelectedText"),
                object: nil,
                userInfo: ["error": "无法获取选中的文本。请先选中文本，或尝试在文本编辑器中使用。"]
            )
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

