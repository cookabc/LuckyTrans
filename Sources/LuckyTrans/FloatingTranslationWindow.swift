import AppKit
import SwiftUI

enum TranslationWindowState {
    case loading(String)
    case success(original: String, translation: String)
    case error(String)
}

class FloatingTranslationWindow: NSWindow {
    private var hostingView: NSHostingView<TranslationView>?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        
        setupWindow()
    }
    
    private func setupWindow() {
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 应用当前的主题设置
        applyAppearance()
        
        // 设置初始位置（屏幕右上角，实际应该跟随鼠标或选区，这里简化处理）
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 450
            let windowHeight: CGFloat = 300 // 增加高度以容纳更多内容
            let x = screenRect.maxX - windowWidth - 50
            let y = screenRect.maxY - windowHeight - 100
            
            self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
    }
    
    private func applyAppearance() {
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
        self.appearance = appearance ?? NSAppearance.currentDrawing()
    }
    
    func show(with state: TranslationWindowState) {
        // 确保应用当前主题设置
        applyAppearance()
        
        let translationView = TranslationView(state: state) {
            self.close()
        }
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: translationView)
            contentView = hostingView
        } else {
            hostingView?.rootView = translationView
        }
        
        // 将窗口定位到鼠标附近
        if let screen = NSScreen.main {
            let mouse = NSEvent.mouseLocation
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 450
            let windowHeight: CGFloat = 300
            var x = mouse.x - windowWidth / 2
            var y = mouse.y - windowHeight - 16
            // 边界限制
            x = max(screenRect.minX + 8, min(x, screenRect.maxX - windowWidth - 8))
            y = max(screenRect.minY + 8, min(y, screenRect.maxY - windowHeight - 8))
            setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 淡入动画
        alphaValue = 0
        animator().alphaValue = 1.0
        
        // 自动关闭（成功时，延迟 30 秒，给用户更多时间阅读）
        if case .success = state {
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                // 如果窗口可见且未被用户交互（简单判断），则关闭
                // 这里为了简单，总是尝试关闭，实际应该检测鼠标位置
                // self.closeWithAnimation() 
                // 用户反馈希望手动关闭或点击外部关闭，暂时不自动关闭以免打断阅读
            }
        }
    }
    
    func closeWithAnimation() {
        animator().alphaValue = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.close()
        }
    }
    
    override func close() {
        super.close()
    }
    
    override func mouseDown(with event: NSEvent) {
        // 允许拖拽
        super.mouseDown(with: event)
    }
}

struct TranslationView: View {
    let state: TranslationWindowState
    let onClose: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        ZStack {
            // 背景 - ClashMac 风格淡色背景
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
            
            // 装饰性边框
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            
            // 顶部装饰条
            VStack {
                HStack {
                    Capsule()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)
                    Spacer()
                }
                .padding(.horizontal)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // 标题栏
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "character.bubble.fill")
                            .foregroundColor(.blue.opacity(0.8))
                        Text("LuckyTrans")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Divider()
                    .opacity(0.5)
                
                switch state {
                case .loading(let text):
                    VStack(alignment: .leading, spacing: 12) {
                        Text(text)
                            .font(.system(size: 14))
                            .lineLimit(3)
                            .foregroundColor(.primary.opacity(0.7))
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("思考中...")
                                .font(.system(size: 13))
                                .foregroundColor(.blue.opacity(0.8))
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                case .success(let original, let translation):
                    VStack(alignment: .leading, spacing: 12) {
                        // 原文引用
                        HStack(alignment: .top, spacing: 4) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 3)
                            Text(original)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(.leading, 4)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        // 翻译结果
                        ScrollView {
                            Text(translation)
                                .font(.system(size: 15, weight: .regular, design: .default))
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                case .error(let message):
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("翻译出错了")
                                .font(.headline)
                        }
                        
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        Button(action: {
                            SettingsWindowManager.shared.showSettings()
                            self.onClose()
                        }) {
                            Text("检查设置")
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue.opacity(0.8))
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 450, height: 300)
    }
}
