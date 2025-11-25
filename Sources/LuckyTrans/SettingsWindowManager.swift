import SwiftUI
import AppKit

class SettingsWindowManager: ObservableObject {
    static let shared = SettingsWindowManager()
    
    private var settingsWindow: NSWindow?
    
    private init() {}
    
    func showSettings() {
        // 如果窗口已存在，显示它
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新的设置窗口
        let settingsView = SettingsView()
            .environmentObject(SettingsManager.shared)
        
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 500, height: 600)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 650),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "设置"
        window.contentViewController = hostingController
        // 应用当前的主题设置
        let appearanceMode = SettingsManager.shared.appearanceMode
        let appearance: NSAppearance?
        switch appearanceMode {
        case .system:
            appearance = nil
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        }
        window.appearance = appearance ?? NSAppearance.currentDrawing()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.settingsWindow = window
        
        // 窗口关闭时清理
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settingsWindow = nil
        }
    }
}

