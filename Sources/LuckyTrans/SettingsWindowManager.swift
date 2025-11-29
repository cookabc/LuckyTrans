import SwiftUI
import AppKit
import QuartzCore

// 设置窗口也使用自定义窗口类，禁用关闭动画
class NonAnimatedSettingsWindow: NSWindow {
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
    }
    
    override func performClose(_ sender: Any?) {
        // 拦截 performClose，直接关闭而不使用动画
        self.close()
    }
}

class SettingsWindowManager: ObservableObject {
    static let shared = SettingsWindowManager()
    
    private var settingsWindow: NSWindow?
    private var windowDelegate: WindowCloseDelegate?
    
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
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 750, height: 600)
        
        // 使用自定义窗口类，禁用关闭动画
        // 初始高度设置为 600，宽度调整为 750 以适应侧边栏
        let window = NonAnimatedSettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 设置最小尺寸，允许用户自由调整到更大的尺寸
        window.minSize = NSSize(width: 700, height: 500)
        
        window.title = "设置"
        window.titlebarAppearsTransparent = false
        window.toolbar = nil
        window.contentViewController = hostingController
        
        // 隐藏标题栏上的图标
        window.showsToolbarButton = false
        
        // 隐藏标题栏右侧的导航按钮（在窗口显示后处理）
        
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
        
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 延迟隐藏标题栏右侧的导航按钮
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hideTitleBarButtons(window: window)
        }
        
        self.settingsWindow = window
        
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
                self.settingsWindow = nil
                self.windowDelegate = nil
            }
        }
        
        // 拦截窗口关闭，禁用动画
        windowDelegate = WindowCloseDelegate()
        window.delegate = windowDelegate
    }
    
    private func hideTitleBarButtons(window: NSWindow) {
        // 移除所有标题栏附件视图控制器（这些通常包含导航按钮）
        let accessories = window.titlebarAccessoryViewControllers
        for i in stride(from: accessories.count - 1, through: 0, by: -1) {
            window.removeTitlebarAccessoryViewController(at: i)
        }
        
        func shouldKeep(_ view: NSView) -> Bool {
            let standardButtons = [
                window.standardWindowButton(.closeButton),
                window.standardWindowButton(.miniaturizeButton),
                window.standardWindowButton(.zoomButton)
            ]
            return standardButtons.contains { $0 === view }
        }
        
        func hideNonStandardControls(in view: NSView) {
            // 隐藏除标准三键外的所有控制视图（包括 NSSegmentedControl 等）
            if let control = view as? NSControl, !shouldKeep(control) {
                control.isHidden = true
            }
            for subview in view.subviews {
                hideNonStandardControls(in: subview)
            }
        }
        
        if let titlebarView = window.standardWindowButton(.closeButton)?.superview {
            hideNonStandardControls(in: titlebarView)
        }
    }
}
