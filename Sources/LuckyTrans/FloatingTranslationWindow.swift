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
        
        // 设置初始位置（屏幕右上角）
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 400
            let windowHeight: CGFloat = 200
            let x = screenRect.maxX - windowWidth - 20
            let y = screenRect.maxY - windowHeight - 20
            
            self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
    }
    
    func show(with state: TranslationWindowState) {
        let translationView = TranslationView(state: state) {
            self.close()
        }
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: translationView)
            contentView = hostingView
        } else {
            hostingView?.rootView = translationView
        }
        
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 淡入动画
        alphaValue = 0
        animator().alphaValue = 1.0
        
        // 自动关闭（成功时，延迟 15 秒）
        if case .success = state {
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                self.closeWithAnimation()
            }
        }
        
        // 错误状态不自动关闭，让用户手动关闭
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
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 10)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("翻译结果")
                        .font(.headline)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                switch state {
                case .loading(let text):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原文:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(text)
                            .font(.body)
                            .lineLimit(3)
                        
                        Spacer()
                        
                        HStack {
                            ProgressView()
                            Text("翻译中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                case .success(let original, let translation):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原文:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(original)
                            .font(.body)
                            .lineLimit(3)
                        
                        Divider()
                        
                        Text("翻译:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(translation)
                            .font(.body)
                            .lineLimit(5)
                        
                        Spacer()
                    }
                    
                case .error(let message):
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("翻译失败")
                                .font(.headline)
                        }
                        Text(message)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(5)
                        
                        Spacer()
                        
                        Button("打开设置") {
                            if #available(macOS 13, *) {
                                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                            } else {
                                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                            }
                            self.onClose()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .frame(width: 400, height: 200)
    }
}

