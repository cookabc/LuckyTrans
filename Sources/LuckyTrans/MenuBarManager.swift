import AppKit
import SwiftUI

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    
    override private init() {}
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "LuckyTrans")
        }
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // 划词翻译 (Selection Translate)
        let selectionTranslateItem = NSMenuItem(title: "划词翻译", action: #selector(handleSelectionTranslate), keyEquivalent: "d")
        selectionTranslateItem.keyEquivalentModifierMask = [.option]
        selectionTranslateItem.image = NSImage(systemSymbolName: "text.magnifyingglass", accessibilityDescription: nil)
        selectionTranslateItem.target = self
        menu.addItem(selectionTranslateItem)
        
        // 截图翻译 (Screenshot Translate)
        let screenshotTranslateItem = NSMenuItem(title: "截图翻译", action: #selector(handleScreenshotTranslate), keyEquivalent: "s")
        screenshotTranslateItem.keyEquivalentModifierMask = [.option]
        screenshotTranslateItem.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil)
        screenshotTranslateItem.target = self
        menu.addItem(screenshotTranslateItem)
        
        // 输入翻译 (Input Translate)
        let inputTranslateItem = NSMenuItem(title: "输入翻译", action: #selector(handleInputTranslate), keyEquivalent: "a")
        inputTranslateItem.keyEquivalentModifierMask = [.option]
        inputTranslateItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        inputTranslateItem.target = self
        menu.addItem(inputTranslateItem)
        
        // 剪贴板翻译
        let clipboardTranslateItem = NSMenuItem(title: "剪贴板翻译", action: #selector(handleClipboardTranslate), keyEquivalent: "")
        clipboardTranslateItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        clipboardTranslateItem.target = self
        menu.addItem(clipboardTranslateItem)
        
        // 显示翻译窗口
        let showWindowItem = NSMenuItem(title: "显示翻译窗口", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        showWindowItem.target = self
        menu.addItem(showWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // OCR Items (Placeholders)
        let screenshotOCRItem = NSMenuItem(title: "截图 OCR", action: nil, keyEquivalent: "s")
        screenshotOCRItem.keyEquivalentModifierMask = [.option, .shift]
        screenshotOCRItem.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)
        menu.addItem(screenshotOCRItem)
        
        let silentOCRItem = NSMenuItem(title: "静默截图 OCR", action: nil, keyEquivalent: "c")
        silentOCRItem.keyEquivalentModifierMask = [.option]
        silentOCRItem.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil)
        menu.addItem(silentOCRItem)
        
        let finderOCRItem = NSMenuItem(title: "访达选图 OCR", action: nil, keyEquivalent: "")
        finderOCRItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        menu.addItem(finderOCRItem)
        
        let clipboardOCRItem = NSMenuItem(title: "剪贴板 OCR", action: nil, keyEquivalent: "")
        clipboardOCRItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        menu.addItem(clipboardOCRItem)
        
        let showOCRWindowItem = NSMenuItem(title: "显示 OCR 窗口", action: nil, keyEquivalent: "")
        showOCRWindowItem.image = NSImage(systemSymbolName: "list.bullet.rectangle", accessibilityDescription: nil)
        menu.addItem(showOCRWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "偏好设置", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Version Info
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let versionItem = NSMenuItem(title: "LuckyTrans \(version)", action: nil, keyEquivalent: "")
            versionItem.isEnabled = false
            menu.addItem(versionItem)
        }
        
        // More Submenu
        let moreItem = NSMenuItem(title: "更多", action: nil, keyEquivalent: "")
        moreItem.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: nil)
        let moreMenu = NSMenu()
        moreMenu.addItem(NSMenuItem(title: "检查更新", action: nil, keyEquivalent: ""))
        moreMenu.addItem(NSMenuItem(title: "反馈", action: nil, keyEquivalent: ""))
        moreItem.submenu = moreMenu
        menu.addItem(moreItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // Actions
    @objc private func handleSelectionTranslate() {
        // 触发划词翻译 (通过 Notification 通知 AppDelegate)
        NotificationCenter.default.post(name: NSNotification.Name("TriggerSelectionTranslate"), object: nil)
    }
    
    @objc private func handleScreenshotTranslate() {
        // TODO: Implement screenshot translate
        print("Screenshot Translate triggered")
    }
    
    @objc private func handleInputTranslate() {
        // 触发输入翻译 (打开主窗口)
        MainWindowManager.shared.showMainWindow()
    }
    
    @objc private func handleClipboardTranslate() {
        // 触发剪贴板翻译
        if let string = NSPasteboard.general.string(forType: .string) {
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateSelectedText"),
                object: nil,
                userInfo: ["text": string]
            )
            MainWindowManager.shared.showMainWindow()
        }
    }
    
    @objc private func showMainWindow() {
        MainWindowManager.shared.showMainWindow()
    }
    
    @objc private func showSettings() {
        SettingsWindowManager.shared.showSettings()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func remove() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }
}
