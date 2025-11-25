import SwiftUI
import AppKit
import QuartzCore

// 自定义窗口类，禁用所有关闭动画
class NonAnimatedWindow: NSWindow {
    private var isClosing = false
    
    override func close() {
        // 防止重复关闭
        guard !isClosing else { return }
        isClosing = true
        
        // 在关闭前禁用所有动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 移除所有动画字典
        self.animations.removeAll()
        
        // 立即隐藏窗口，不使用动画
        self.orderOut(nil)
        
        // 强制完成所有待处理的动画
        CATransaction.flush()
        CATransaction.commit()
        
        // 不调用 super.close()，直接清理资源
        // 这样可以避免系统创建动画对象
        self.contentViewController = nil
        self.delegate = nil
        
        // 通知窗口已关闭
        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: self)
        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: self)
    }
    
    override func performClose(_ sender: Any?) {
        // 拦截 performClose，直接关闭而不使用动画
        self.close()
    }
}

// 窗口关闭代理，禁用关闭动画
class WindowCloseDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        // 禁用所有动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        window.animations.removeAll()
        CATransaction.commit()
    }
}

class MainWindowManager: ObservableObject {
    static let shared = MainWindowManager()
    
    private var mainWindow: NSWindow?
    private var windowDelegate: WindowCloseDelegate?
    
    private init() {}
    
    func showMainWindow() {
        // 如果窗口已存在，显示它
        if let window = mainWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新的主窗口
        let mainView = MainWindowView()
            .environmentObject(SettingsManager.shared)
        
        let hostingController = NSHostingController(rootView: mainView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 650, height: 600)
        
        // 使用自定义窗口类，禁用关闭动画
        let window = NonAnimatedWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "LuckyTrans"
        window.contentViewController = hostingController
        window.center()
        
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
        
        // 禁用窗口关闭动画，直接关闭
        window.isReleasedWhenClosed = false
        // 在创建时就禁用所有动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        window.animations.removeAll()
        CATransaction.commit()
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.mainWindow = window
        
        // 窗口关闭时清理，但不退出应用
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            // 禁用所有动画，防止崩溃
            window.animations.removeAll()
            // 立即清理引用
            if let self = self {
                self.mainWindow = nil
                self.windowDelegate = nil
            }
        }
        
        // 拦截窗口关闭，禁用动画
        windowDelegate = WindowCloseDelegate()
        window.delegate = windowDelegate
    }
    
    func closeMainWindow() {
        if let window = mainWindow {
            // 禁用关闭动画
            window.animations.removeAll()
            window.close()
            mainWindow = nil
            windowDelegate = nil
        }
    }
}

