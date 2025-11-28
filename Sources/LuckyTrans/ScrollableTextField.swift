import SwiftUI
import AppKit

struct ScrollableTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    
    func makeNSView(context: Context) -> NSTextField {
        let textField: NSTextField
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.placeholderString = placeholder
        textField.stringValue = text
        
        // 启用水平滚动
        if let cell = textField.cell as? NSTextFieldCell {
            cell.isScrollable = true
            cell.wraps = false
        }
        
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        context.coordinator.isSecure = isSecure
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // 只在文本真正改变时更新，避免循环更新
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        // 更新安全模式状态
        context.coordinator.isSecure = isSecure
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ScrollableTextField
        var textField: NSTextField?
        var isSecure: Bool = false
        
        init(_ parent: ScrollableTextField) {
            self.parent = parent
            self.isSecure = parent.isSecure
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

