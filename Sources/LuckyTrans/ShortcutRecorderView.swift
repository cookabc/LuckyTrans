import SwiftUI
import AppKit
import Carbon

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @State private var isRecording = false
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBordered = true
        textField.backgroundColor = .controlBackgroundColor
        textField.alignment = .center
        textField.placeholderString = "点击设置快捷键"
        textField.stringValue = formatShortcut(keyCode: keyCode, modifiers: modifiers)
        
        // 添加点击手势
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick))
        textField.addGestureRecognizer(clickGesture)
        
        context.coordinator.textField = textField
        context.coordinator.parent = self
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = formatShortcut(keyCode: keyCode, modifiers: modifiers)
        context.coordinator.keyCode = keyCode
        context.coordinator.modifiers = modifiers
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        weak var parent: ShortcutRecorderView?
        var textField: NSTextField?
        var isRecording = false
        var keyCode: UInt32
        var modifiers: UInt32
        var eventMonitor: Any?
        
        init(_ parent: ShortcutRecorderView) {
            self.parent = parent
            self.keyCode = parent.keyCode
            self.modifiers = parent.modifiers
        }
        
        @objc func handleClick() {
            guard parent != nil else { return }
            isRecording = true
            textField?.stringValue = "按下快捷键..."
            textField?.backgroundColor = .selectedControlColor
            
            // 开始监听键盘事件
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                return self?.handleKeyEvent(event) ?? event
            }
        }
        
        func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
            guard isRecording, let parent = parent else { return event }
            
            // 忽略某些特殊键
            if event.keyCode == 53 { // Escape
                cancelRecording()
                return nil
            }
            
            // 只处理 keyDown 事件
            guard event.type == .keyDown else {
                return event
            }
            
            // 获取修饰键
            var carbonModifiers: UInt32 = 0
            if event.modifierFlags.contains(.command) {
                carbonModifiers |= UInt32(cmdKey)
            }
            if event.modifierFlags.contains(.option) {
                carbonModifiers |= UInt32(optionKey)
            }
            if event.modifierFlags.contains(.control) {
                carbonModifiers |= UInt32(controlKey)
            }
            if event.modifierFlags.contains(.shift) {
                carbonModifiers |= UInt32(shiftKey)
            }
            
            // 确保至少有一个修饰键
            guard carbonModifiers > 0 else {
                return event
            }
            
            // 更新快捷键
            keyCode = UInt32(event.keyCode)
            modifiers = carbonModifiers
            
            parent.keyCode = keyCode
            parent.modifiers = modifiers
            
            finishRecording()
            return nil
        }
        
        func cancelRecording() {
            isRecording = false
            textField?.stringValue = parent?.formatShortcut(keyCode: keyCode, modifiers: modifiers) ?? ""
            textField?.backgroundColor = .controlBackgroundColor
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        
        func finishRecording() {
            isRecording = false
            textField?.stringValue = parent?.formatShortcut(keyCode: keyCode, modifiers: modifiers) ?? ""
            textField?.backgroundColor = .controlBackgroundColor
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    func formatShortcut(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        
        // 将 keyCode 转换为字符
        if let keyChar = keyCodeToChar(keyCode) {
            parts.append(keyChar)
        } else {
            parts.append("Key(\(keyCode))")
        }
        
        return parts.joined()
    }
    
    func keyCodeToChar(_ keyCode: UInt32) -> String? {
        // 常见键码映射
        let keyMap: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x24: "Return", 0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K",
            0x29: ";", 0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N",
            0x2E: "M", 0x2F: ".", 0x30: "Tab", 0x31: "Space", 0x32: "`",
            0x33: "Delete", 0x35: "Esc", 0x37: "⌘", 0x38: "⇧", 0x39: "Caps",
            0x3A: "⌥", 0x3B: "⌃", 0x3C: "Fn", 0x3D: "F17", 0x3E: "VolumeUp",
            0x3F: "VolumeDown", 0x40: "Mute", 0x41: "F18", 0x43: "F19",
            0x45: "F20", 0x47: "Clear", 0x48: "F3", 0x49: "F16", 0x4A: "F8",
            0x4B: "F11", 0x4C: "F13", 0x4D: "F5", 0x4E: "F6", 0x4F: "F7",
            0x50: "F12", 0x51: "F15", 0x52: "F14", 0x53: "F10", 0x54: "F9",
            0x55: "F4", 0x56: "F2", 0x57: "F1"
        ]
        
        return keyMap[keyCode]
    }
}

