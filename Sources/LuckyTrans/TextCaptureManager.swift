import Cocoa
import ApplicationServices

class TextCaptureManager {
    static let shared = TextCaptureManager()
    
    private init() {}
    
    func getSelectedText() -> String? {
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
            return nil
        }
        
        // 获取当前焦点应用
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let pid = focusedApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
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
        
        // 获取选中文本
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
        // 保存当前剪贴板内容
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        
        // 模拟 Cmd+C
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // 'C' key
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        keyDownEvent?.flags = .maskCommand
        keyUpEvent?.flags = .maskCommand
        
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
        
        // 等待剪贴板更新
        Thread.sleep(forTimeInterval: 0.1)
        
        // 获取新内容
        let newContents = pasteboard.string(forType: .string)
        
        // 恢复原剪贴板内容
        if let previous = previousContents {
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
        }
        
        return newContents
    }
}

