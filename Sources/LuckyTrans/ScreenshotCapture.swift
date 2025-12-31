import Foundation
import AppKit
import SwiftUI

/// 屏幕区域捕获管理器
///
/// 功能：
/// - 全屏遮罩覆盖
/// - 区域选择框
/// - 快捷键确认/取消
@MainActor
public class ScreenshotCapture: NSObject {
    // MARK: - Types

    public typealias CaptureCompletion = (NSImage?) -> Void

    // MARK: - Properties

    private var captureWindow: ScreenshotWindow?
    private var completion: CaptureCompletion?

    // MARK: - Public Methods

    /// 开始屏幕区域捕获
    ///
    /// - Parameter completion: 完成回调，返回捕获的图像
    public func startCapture(completion: @escaping CaptureCompletion) {
        self.completion = completion

        // 获取所有屏幕
        let screens = NSScreen.screens
        guard let mainScreen = screens.first else {
            completion(nil)
            return
        }

        // 创建遮罩窗口
        let window = ScreenshotWindow(screen: mainScreen, allScreens: screens)
        window.onCaptureComplete = { [weak self] image in
            self?.endCapture(with: image)
        }
        window.onCancel = { [weak self] in
            self?.endCapture(with: nil)
        }

        self.captureWindow = window
        window.makeKeyAndOrderFront(nil)

        // 进入屏幕捕获模式
        NSApp.setActivationPolicy(.accessory)
    }

    /// 结束捕获
    private func endCapture(with image: NSImage?) {
        captureWindow?.close()
        captureWindow = nil

        // 恢复应用状态
        NSApp.setActivationPolicy(.regular)

        completion?(image)
        completion = nil
    }
}

// MARK: - Screenshot Window

/// 截图选择窗口
private class ScreenshotWindow: NSWindow {
    var onCaptureComplete: ((NSImage) -> Void)?
    var onCancel: (() -> Void)?

    private var allScreens: [NSScreen]
    private var startPoint: NSPoint?
    private var currentRect: NSRect = .zero
    private var trackingArea: NSTrackingArea?

    // 视觉元素
    private var overlayView: OverlayView?
    private var selectionBox: NSBox?
    private var infoLabel: NSTextField?

    init(screen: NSScreen, allScreens: [NSScreen]) {
        self.allScreens = allScreens

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow(screen: screen)
    }

    private func setupWindow(screen: NSScreen) {
        // 窗口属性
        self.level = .screenSaver
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.isOpaque = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 创建遮罩视图
        let overlay = OverlayView(frame: screen.frame)
        overlay.onMouseMoved = { [weak self] point in
            self?.handleMouseMoved(point)
        }
        overlay.onMouseDragged = { [weak self] point in
            self?.handleMouseDragged(point)
        }
        overlay.onMouseUp = { [weak self] point in
            self?.handleMouseUp(point)
        }

        self.contentView = overlay
        self.overlayView = overlay

        // 创建信息标签
        setupInfoLabel()

        // 注册键盘事件
        setupLocalEvents()
    }

    private func setupInfoLabel() {
        let label = NSTextField(labelWithString: "拖拽选择区域 | Enter: 确认 | Esc: 取消")
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        label.layer?.cornerRadius = 8

        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView?.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.contentView!.centerXAnchor),
            label.topAnchor.constraint(equalTo: self.contentView!.topAnchor, constant: 20),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])

        self.infoLabel = label
    }

    private func setupLocalEvents() {
        // 监听键盘事件
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
    }

    // MARK: - Event Handlers

    private func handleKeyDown(_ event: NSEvent) {
        switch event.keyCode {
        case 36:  // Enter
            confirmCapture()
        case 53:  // Esc
            cancelCapture()
        default:
            break
        }
    }

    private func handleMouseMoved(_ point: NSPoint) {
        startPoint = point
    }

    private func handleMouseDragged(_ point: NSPoint) {
        guard let start = startPoint else { return }

        let rect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )

        currentRect = rect
        updateSelectionBox(rect)
    }

    private func handleMouseUp(_ point: NSPoint) {
        // 鼠标松开后，可以再次按下确认或取消
    }

    private func updateSelectionBox(_ rect: NSRect) {
        // 移除旧的选择框
        selectionBox?.removeFromSuperview()

        // 创建新的选择框
        let box = NSBox(frame: rect)
        box.boxType = .custom
        box.fillColor = .clear
        box.borderColor = NSColor.systemBlue
        box.borderWidth = 2
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.2).cgColor

        self.contentView?.addSubview(box)
        self.selectionBox = box
    }

    private func confirmCapture() {
        guard !currentRect.isEmpty else {
            cancelCapture()
            return
        }

        // 截取选定区域
        if let image = captureScreenRect(currentRect) {
            onCaptureComplete?(image)
        } else {
            onCancel?()
        }
    }

    private func cancelCapture() {
        onCancel?()
    }

    private func captureScreenRect(_ rect: NSRect) -> NSImage? {
        let screen = NSScreen.screens.first { $0.frame.contains(rect) }
        guard let screen = screen else { return nil }

        // 转换为屏幕坐标
        let screenRect = convertToScreenCoordinates(rect, screen: screen)

        // 使用 CGWindowListCreateImage 截图
        let cgImage = CGDisplayCreateImage(
            UInt32(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID),
            rect: screenRect
        )

        guard let cgImage = cgImage else { return nil }

        return NSImage(cgImage: cgImage, size: rect.size)
    }

    private func convertToScreenCoordinates(_ rect: NSRect, screen: NSScreen) -> CGRect {
        let screenFrame = screen.frame
        let flippedY = screenFrame.height - rect.maxY
        return CGRect(x: rect.origin.x, y: flippedY, width: rect.width, height: rect.height)
    }
}

// MARK: - Overlay View

/// 遮罩视图，用于捕获鼠标事件
private class OverlayView: NSView {
    var onMouseMoved: ((NSPoint) -> Void)?
    var onMouseDragged: ((NSPoint) -> Void)?
    var onMouseUp: ((NSPoint) -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 绘制半透明遮罩
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()
    }

    func acceptsFirstResponder() -> Bool {
        return true
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        onMouseMoved?(point)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        onMouseMoved?(point)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        onMouseDragged?(point)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        onMouseUp?(point)
    }
}
