import Cocoa
import ApplicationServices

class TextCaptureManager {
    static let shared = TextCaptureManager()
    
    private init() {}
    
    func getSelectedText() -> String? {
        // 方法 0: 检查是否为浏览器，优先使用 AppleScript
        if let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           isBrowser(bundleID) {
            if let text = getSelectedTextFromBrowser(bundleID) {
                print("TextCapture: 从浏览器 AppleScript 获取到文本: \(text.prefix(50))")
                return text
            }
        }

        // 方法 1: 使用辅助功能 API 获取选中文本
        if let text = getSelectedTextViaAccessibility() {
            return text
        }

        // 方法 2: 使用剪贴板作为备选方案
        return getSelectedTextViaClipboard()
    }
    
    private func getSelectedTextViaAccessibility() -> String? {
        // 检查权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        guard AXIsProcessTrustedWithOptions(options as CFDictionary) else {
            print("TextCapture: 辅助功能权限未授予")
            return nil
        }
        
        // 获取当前焦点应用
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else {
            print("TextCapture: 无法获取当前焦点应用")
            return nil
        }
        
        let pid = focusedApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        print("TextCapture: 当前焦点应用: \(focusedApp.localizedName ?? "未知") (PID: \(pid))")
        
        // 方法 1: 尝试从焦点元素获取
        if let text = getSelectedTextFromFocusedElement(appElement: appElement) {
            print("TextCapture: 从焦点元素获取到文本: \(text.prefix(50))")
            return text
        }
        
        // 方法 2: 尝试从所有窗口获取
        if let text = getSelectedTextFromAllWindows(appElement: appElement) {
            print("TextCapture: 从窗口获取到文本: \(text.prefix(50))")
            return text
        }
        
        print("TextCapture: 无法通过辅助功能 API 获取选中文本")
        return nil
    }
    
    private func getSelectedTextFromFocusedElement(appElement: AXUIElement) -> String? {
        // 获取焦点窗口
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        
        guard result == .success, let window = focusedWindow else {
            return nil
        }
        
        // 获取焦点元素（通常是文本字段或文本视图）
        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(
            window as! AXUIElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard focusResult == .success, let element = focusedElement else {
            return nil
        }
        
        // 尝试直接获取选中文本
        var selectedText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        
        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            return text
        }
        
        // 如果直接获取失败，尝试获取所有文本然后提取选中部分
        return getSelectedTextFromElement(element as! AXUIElement)
    }
    
    private func getSelectedTextFromAllWindows(appElement: AXUIElement) -> String? {
        // 获取所有窗口
        var windows: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windows
        )
        
        guard result == .success, let windowsArray = windows as? [AXUIElement] else {
            return nil
        }
        
        // 遍历所有窗口，查找有选中文本的
        for window in windowsArray {
            // 尝试从窗口的主元素获取选中文本
            if let text = getSelectedTextFromWindow(window) {
                return text
            }
        }
        
        return nil
    }
    
    private func getSelectedTextFromWindow(_ window: AXUIElement) -> String? {
        // 获取窗口的所有子元素
        var children: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            window,
            kAXChildrenAttribute as CFString,
            &children
        )
        
        guard result == .success, let childrenArray = children as? [AXUIElement] else {
            return nil
        }
        
        // 递归查找有选中文本的元素
        for child in childrenArray {
            // 检查是否有选中文本
            var selectedText: AnyObject?
            if AXUIElementCopyAttributeValue(child, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
               let text = selectedText as? String, !text.isEmpty {
                return text
            }
            
            // 递归检查子元素
            if let text = getSelectedTextFromWindow(child) {
                return text
            }
        }
        
        return nil
    }
    
    private func getSelectedTextFromElement(_ element: AXUIElement) -> String? {
        // 获取选中范围
        var selectedRange: AnyObject?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRange
        )
        
        guard rangeResult == .success else {
            return nil
        }
        
        // 获取所有文本
        var allText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &allText
        )
        
        guard textResult == .success, let text = allText as? String else {
            return nil
        }
        
        // 解析选中范围（AXValue 格式）
        if CFGetTypeID(selectedRange as CFTypeRef) == AXValueGetTypeID() {
            let rangeValue = selectedRange as! AXValue
            var range = CFRange()
            if AXValueGetValue(rangeValue, .cfRange, &range) {
                let start = text.index(text.startIndex, offsetBy: range.location)
                let end = text.index(start, offsetBy: range.length)
                return String(text[start..<end])
            }
        }
        
        return nil
    }
    
    private func getSelectedTextViaClipboard() -> String? {
        print("TextCapture: 剪贴板方法已禁用，因其可能干扰用户操作")
        // 剪贴板方法会干扰用户的正常工作流程，不再使用
        return nil
    }
}

