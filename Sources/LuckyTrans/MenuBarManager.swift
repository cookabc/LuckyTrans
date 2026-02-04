import AppKit
import SwiftUI
import Vision

// MARK: - Menu Bar Status

enum MenuBarStatus {
    case normal
    case translating
    case error
    
    var iconName: String {
        switch self {
        case .normal: return "globe"
        case .translating: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle"
        }
    }
}

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var overlayWindow: NSWindow?
    private var floatingWindow: FloatingTranslationWindow?
    private var rotationTimer: Timer?
    private var currentStatus: MenuBarStatus = .normal
    
    override private init() {}
    
    func setup() {
        // Prevent duplicate setup
        if statusItem != nil { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: MenuBarStatus.normal.iconName, accessibilityDescription: "LuckyTrans")
            button.image?.isTemplate = true
        }
        
        updateMenu()
    }
    
    // MARK: - Status Icon Management
    
    func setStatus(_ status: MenuBarStatus) {
        guard status != currentStatus else { return }
        currentStatus = status
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let button = self.statusItem?.button else { return }
            
            // Stop any existing animation
            self.stopRotationAnimation()
            
            // Update icon
            button.image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "LuckyTrans")
            button.image?.isTemplate = true
            
            // Apply status-specific styling
            switch status {
            case .translating:
                self.startRotationAnimation()
            case .error:
                button.contentTintColor = .systemRed
                // Auto-reset to normal after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    if self?.currentStatus == .error {
                        self?.setStatus(.normal)
                    }
                }
            case .normal:
                button.contentTintColor = nil
            }
        }
    }
    
    private func startRotationAnimation() {
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let button = self?.statusItem?.button else { return }
            // Rotate the icon by changing its drawing
            if let image = button.image {
                let rotated = image.rotated(by: 30)
                button.image = rotated
            }
        }
    }
    
    private func stopRotationAnimation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // MARK: Brand Header
        let headerItem = NSMenuItem()
        let headerView = NSHostingView(rootView: MenuBarHeaderView())
        headerView.frame = NSRect(x: 0, y: 0, width: 220, height: 50)
        headerItem.view = headerView
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // MARK: Translation Section
        let translateSectionItem = createSectionHeader("翻译")
        menu.addItem(translateSectionItem)
        
        let selectionTranslateItem = NSMenuItem(title: "划词翻译", action: #selector(handleSelectionTranslate), keyEquivalent: "d")
        selectionTranslateItem.keyEquivalentModifierMask = [.option]
        selectionTranslateItem.image = NSImage(systemSymbolName: "text.magnifyingglass", accessibilityDescription: nil)
        selectionTranslateItem.target = self
        menu.addItem(selectionTranslateItem)
        
        let screenshotTranslateItem = NSMenuItem(title: "截图翻译", action: #selector(handleScreenshotTranslate), keyEquivalent: "s")
        screenshotTranslateItem.keyEquivalentModifierMask = [.option]
        screenshotTranslateItem.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil)
        screenshotTranslateItem.target = self
        menu.addItem(screenshotTranslateItem)
        
        let inputTranslateItem = NSMenuItem(title: "输入翻译", action: #selector(handleInputTranslate), keyEquivalent: "a")
        inputTranslateItem.keyEquivalentModifierMask = [.option]
        inputTranslateItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        inputTranslateItem.target = self
        menu.addItem(inputTranslateItem)
        
        let clipboardTranslateItem = NSMenuItem(title: "剪贴板翻译", action: #selector(handleClipboardTranslate), keyEquivalent: "")
        clipboardTranslateItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        clipboardTranslateItem.target = self
        menu.addItem(clipboardTranslateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // MARK: OCR Section
        let ocrSectionItem = createSectionHeader("文字识别")
        menu.addItem(ocrSectionItem)
        
        let screenshotOCRItem = NSMenuItem(title: "截图 OCR", action: #selector(handleScreenshotOCR), keyEquivalent: "s")
        screenshotOCRItem.keyEquivalentModifierMask = [.option, .shift]
        screenshotOCRItem.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)
        screenshotOCRItem.target = self
        menu.addItem(screenshotOCRItem)
        
        let silentOCRItem = NSMenuItem(title: "静默截图 OCR", action: #selector(handleSilentScreenshotOCR), keyEquivalent: "c")
        silentOCRItem.keyEquivalentModifierMask = [.option]
        silentOCRItem.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil)
        silentOCRItem.target = self
        menu.addItem(silentOCRItem)
        
        let clipboardOCRItem = NSMenuItem(title: "剪贴板 OCR", action: #selector(handleClipboardOCR), keyEquivalent: "")
        clipboardOCRItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        clipboardOCRItem.target = self
        menu.addItem(clipboardOCRItem)
        
        let finderOCRItem = NSMenuItem(title: "访达选图 OCR", action: #selector(handleFinderOCR), keyEquivalent: "")
        finderOCRItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        finderOCRItem.target = self
        menu.addItem(finderOCRItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // MARK: Windows Section
        let showWindowItem = NSMenuItem(title: "显示翻译窗口", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        showWindowItem.target = self
        menu.addItem(showWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // MARK: Settings & Quit
        let settingsItem = NSMenuItem(title: "偏好设置...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let quitItem = NSMenuItem(title: "退出 LuckyTrans", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func createSectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title.uppercased(), action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title.uppercased(),
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        return item
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

    @objc private func handleSilentScreenshotOCR() {
        presentSelectionOverlay { [weak self] rect in
            guard let self = self, let rect = rect else { return }
            guard let image = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else { return }
            let text = self.recognizeText(from: image).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    @objc private func handleFinderOCR() {
        let script = """
        tell application "Finder"
            set theSelection to selection
            if (count of theSelection) = 0 then
                return ""
            end if
            set theItem to item 1 of theSelection as alias
            POSIX path of theItem
        end tell
        """
        if let text = runAppleScript(script), !text.isEmpty {
            let url = URL(fileURLWithPath: text)
            if let image = NSImage(contentsOf: url), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let result = recognizeText(from: cgImage).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !result.isEmpty else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result, forType: .string)
                NotificationCenter.default.post(name: NSNotification.Name("UpdateSelectedText"), object: nil, userInfo: ["text": result])
                MainWindowManager.shared.showMainWindow()
            }
        }
    }

    private func runAppleScript(_ source: String) -> String? {
        let appleScript = NSAppleScript(source: source)
        var error: NSDictionary?
        let output = appleScript?.executeAndReturnError(&error)
        if let e = error {
            print("AppleScript error: \(e)")
            return nil
        }
        return output?.stringValue
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
        // 使用 SimpleOCREngine 进行 OCR
        let nsImage = NSImage(cgImage: image, size: .zero)

        // 同步调用异步方法（为了兼容现有代码）
        let semaphore = DispatchSemaphore(value: 0)
        var result: String = ""

        Task {
            do {
                let ocrResult = try await SimpleOCREngine.shared.recognizeText(from: nsImage)
                result = ocrResult.mergedText
            } catch {
                print("OCR Error: \(error.localizedDescription)")
                result = ""
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 10) // 10秒超时
        return result
    }

    /// 异步版本的 OCR 方法，用于获取完整的 OCR 结果
    private func recognizeTextAsync(from image: CGImage) async throws -> OCRResult {
        let nsImage = NSImage(cgImage: image, size: .zero)
        return try await SimpleOCREngine.shared.recognizeText(from: nsImage)
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

// MARK: - NSImage Rotation Extension

extension NSImage {
    func rotated(by degrees: CGFloat) -> NSImage {
        let radians = degrees * .pi / 180
        let newSize = CGSize(width: size.width, height: size.height)
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        let context = NSGraphicsContext.current!
        context.saveGraphicsState()
        
        let transform = NSAffineTransform()
        transform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        transform.rotate(byDegrees: degrees)
        transform.translateX(by: -size.width / 2, yBy: -size.height / 2)
        transform.concat()
        
        draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        
        context.restoreGraphicsState()
        newImage.lockFocus()
        
        return newImage
    }
}
