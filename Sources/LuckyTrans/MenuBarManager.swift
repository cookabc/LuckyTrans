import AppKit
import SwiftUI
import Vision

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var overlayWindow: NSWindow?
    private var floatingWindow: FloatingTranslationWindow?
    
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
        let screenshotOCRItem = NSMenuItem(title: "截图 OCR", action: #selector(handleScreenshotOCR), keyEquivalent: "s")
        screenshotOCRItem.keyEquivalentModifierMask = [.option, .shift]
        screenshotOCRItem.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)
        screenshotOCRItem.target = self
        menu.addItem(screenshotOCRItem)
        
        let silentOCRItem = NSMenuItem(title: "静默截图 OCR", action: nil, keyEquivalent: "c")
        silentOCRItem.keyEquivalentModifierMask = [.option]
        silentOCRItem.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil)
        menu.addItem(silentOCRItem)
        
        let finderOCRItem = NSMenuItem(title: "访达选图 OCR", action: nil, keyEquivalent: "")
        finderOCRItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        menu.addItem(finderOCRItem)
        
        let clipboardOCRItem = NSMenuItem(title: "剪贴板 OCR", action: #selector(handleClipboardOCR), keyEquivalent: "")
        clipboardOCRItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        clipboardOCRItem.target = self
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
        presentSelectionOverlay { [weak self] rect in
            guard let self = self, let rect = rect else { return }
            guard let image = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                self.showError("无法截取屏幕，请在系统设置中授予屏幕录制权限")
                return
            }
            let recognized = self.recognizeText(from: image)
            let text = recognized.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                self.showError("未识别到文字")
                return
            }
            if self.floatingWindow == nil { self.floatingWindow = FloatingTranslationWindow() }
            self.floatingWindow?.show(with: .loading(text))
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let target = SettingsManager.shared.targetLanguage
                    let t = try await TranslationService.shared.translate(text: text, targetLanguage: target)
                    await MainActor.run {
                        self.floatingWindow?.show(with: .success(original: text, translation: t))
                    }
                } catch {
                    await MainActor.run {
                        self.floatingWindow?.show(with: .error(error.localizedDescription))
                    }
                }
            }
        }
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

    @objc private func handleScreenshotOCR() {
        presentSelectionOverlay { [weak self] rect in
            guard let self = self, let rect = rect else { return }
            guard let image = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                self.showError("无法截取屏幕，请在系统设置中授予屏幕录制权限")
                return
            }
            let text = self.recognizeText(from: image).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                self.showError("未识别到文字")
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            NotificationCenter.default.post(name: NSNotification.Name("UpdateSelectedText"), object: nil, userInfo: ["text": text])
            MainWindowManager.shared.showMainWindow()
        }
    }

    @objc private func handleClipboardOCR() {
        let pasteboard = NSPasteboard.general
        if let data = pasteboard.data(forType: .tiff), let image = NSImage(data: data), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let text = recognizeText(from: cgImage).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { showError("剪贴板图片未识别到文字"); return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            NotificationCenter.default.post(name: NSNotification.Name("UpdateSelectedText"), object: nil, userInfo: ["text": text])
            MainWindowManager.shared.showMainWindow()
        } else {
            showError("剪贴板不包含图片")
        }
    }

    private func presentSelectionOverlay(completion: @escaping (CGRect?) -> Void) {
        guard let screen = NSScreen.main else { completion(nil); return }
        let frame = screen.frame
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let view = SelectionOverlayView(frame: frame)
        view.onComplete = { [weak self] rect in
            self?.overlayWindow?.orderOut(nil)
            self?.overlayWindow = nil
            completion(rect)
        }
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        overlayWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    private func recognizeText(from image: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: "\n")
        } catch {
            return ""
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "错误"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

class SelectionOverlayView: NSView {
    var onComplete: ((CGRect?) -> Void)?
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.withAlphaComponent(0.2).setFill()
        dirtyRect.fill()
        if let s = startPoint, let c = currentPoint {
            let rect = NSRect(x: min(s.x, c.x), y: min(s.y, c.y), width: abs(c.x - s.x), height: abs(c.y - s.y))
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()
            NSColor.systemBlue.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = event.locationInWindow
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = event.locationInWindow
        guard let s = startPoint, let c = currentPoint else { onComplete?(nil); return }
        let rect = NSRect(x: min(s.x, c.x), y: min(s.y, c.y), width: abs(c.x - s.x), height: abs(c.y - s.y))
        let screenOrigin = window?.frame.origin ?? .zero
        let global = NSRect(x: rect.origin.x + screenOrigin.x, y: rect.origin.y + screenOrigin.y, width: rect.size.width, height: rect.size.height)
        onComplete?(global)
    }
}
