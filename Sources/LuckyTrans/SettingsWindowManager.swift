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
        
        // 使用自定义窗口类，禁用关闭动画
        // 初始高度设置得足够大，确保内容可以完全渲染
        let window = NonAnimatedSettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 只设置最大高度，不设置最小高度（让窗口可以根据内容自适应）
        window.maxSize = NSSize(width: 550, height: 800)
        
        window.title = "设置"
        window.contentViewController = hostingController
        
        // 设置视图大小（初始设置为最大高度，让内容可以完全渲染）
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 550, height: 800)
        
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
        
        self.settingsWindow = window
        
        // 监听内容高度变化通知，调整窗口大小
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsContentHeightChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let window = self.settingsWindow,
                  let height = notification.userInfo?["height"] as? CGFloat else {
                return
            }
            
            // 计算最终窗口高度：内容高度，但不超过最大高度
            let maxHeight: CGFloat = 800
            let finalHeight = min(height, maxHeight)
            
            // 确保高度至少为一个合理的最小值
            let minHeight: CGFloat = 300
            let adjustedHeight = max(finalHeight, minHeight)
            
            // 调整窗口大小，保持窗口顶部位置不变
            var frame = window.frame
            let oldHeight = frame.size.height
            if abs(oldHeight - adjustedHeight) > 1 { // 避免微小的调整
                frame.size.height = adjustedHeight
                frame.origin.y += (oldHeight - adjustedHeight)
                window.setFrame(frame, display: true, animate: false)
            }
        }
        
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
                // 移除内容高度变化监听
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSNotification.Name("SettingsContentHeightChanged"),
                    object: nil
                )
            }
        }
        
        // 拦截窗口关闭，禁用动画
        windowDelegate = WindowCloseDelegate()
        window.delegate = windowDelegate
        
        // 延迟触发一次高度检查，确保视图已完全渲染和布局
        // 使用多个延迟来确保在不同阶段都能正确测量
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.contentView?.needsLayout = true
            window.contentView?.layoutSubtreeIfNeeded()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let contentView = window.contentView {
                    // 设置一个非常大的高度，让内容可以完全展开
                    contentView.frame = NSRect(x: 0, y: 0, width: 550, height: 10000)
                    contentView.layoutSubtreeIfNeeded()
                    
                    // 获取内容的理想大小（不包括标题栏）
                    let fittingSize = contentView.fittingSize
                    
                    // 如果 fittingSize 可用，使用它来调整窗口大小
                    if fittingSize.height > 0 {
                        let maxHeight: CGFloat = 800
                        let finalHeight = min(fittingSize.height, maxHeight)
                        
                        // 调整窗口大小
                        var frame = window.frame
                        let oldHeight = frame.size.height
                        frame.size.height = finalHeight
                        frame.origin.y += (oldHeight - finalHeight)
                        window.setFrame(frame, display: true, animate: false)
                    }
                }
            }
        }
    }
}

