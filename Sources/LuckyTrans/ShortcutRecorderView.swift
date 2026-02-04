import SwiftUI
import AppKit
import Carbon

// MARK: - Shortcut Recorder View (NSViewRepresentable)

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo
    var actionType: ShortcutActionType?
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = LTDesign.CornerRadius.small
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = NSColor.secondaryLabelColor.withAlphaComponent(0.2).cgColor
        containerView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        let textField = ClickableTextField()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        textField.placeholderString = "点击录制"
        textField.stringValue = formatShortcut(keyCombo)
        textField.coordinator = context.coordinator
        
        let button = NSButton()
        button.isBordered = false
        button.title = ""
        button.target = context.coordinator
        button.action = #selector(Coordinator.buttonClicked)
        button.bezelStyle = .rounded
        button.alphaValue = 0.01
        
        containerView.addSubview(textField)
        containerView.addSubview(button)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add clear button (xmark) if shortcut is set
        let clearButton = NSButton()
        clearButton.symbolConfiguration = .init(scale: .small)
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "清除")
        clearButton.isBordered = false
        clearButton.bezelStyle = .inline
        clearButton.contentTintColor = .tertiaryLabelColor
        clearButton.target = context.coordinator
        clearButton.action = #selector(Coordinator.clearButtonClicked)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isHidden = !keyCombo.isValid
        
        containerView.addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),
            
            clearButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalToConstant: 16),
            
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor), // Don't cover clear button
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        context.coordinator.textField = textField
        context.coordinator.containerView = containerView
        context.coordinator.clearButton = clearButton
        context.coordinator.keyComboBinding = _keyCombo
        context.coordinator.actionType = actionType
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let textField = nsView.subviews.first(where: { $0 is ClickableTextField }) as? ClickableTextField {
            if !context.coordinator.isRecording {
                textField.stringValue = formatShortcut(keyCombo)
            }
            textField.coordinator = context.coordinator
        }
        
        // Update clear button visibility
        if let clearButton = nsView.subviews.first(where: { ($0 as? NSButton)?.action == #selector(Coordinator.clearButtonClicked) }) as? NSButton {
             clearButton.isHidden = !keyCombo.isValid || context.coordinator.isRecording
        }
        
        context.coordinator.keyComboBinding = _keyCombo
        context.coordinator.actionType = actionType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(keyCombo: _keyCombo)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var textField: NSTextField?
        var containerView: NSView?
        var clearButton: NSButton?
        var isRecording = false
        var keyComboBinding: Binding<KeyCombo>
        var actionType: ShortcutActionType?
        
        var eventMonitor: Any?
        var timeoutTimer: Timer?
        
        init(keyCombo: Binding<KeyCombo>) {
            self.keyComboBinding = keyCombo
            super.init()
        }
        
        @objc func buttonClicked() {
            handleClick()
        }
        
        @objc func clearButtonClicked() {
            cancelRecording()
            keyComboBinding.wrappedValue = .zero
        }
        
        func handleClick() {
            guard let textField = textField, !isRecording else { return }
            
            textField.window?.makeFirstResponder(textField)
            
            isRecording = true
            textField.stringValue = "按下快捷键..."
            textField.textColor = .white
            clearButton?.isHidden = true
            
            // Update container style with animation
            containerView?.layer?.backgroundColor = NSColor.systemBlue.cgColor
            containerView?.layer?.borderColor = NSColor.systemBlue.cgColor
            
            // Add pulse animation
            addPulseAnimation()
            
            // Start timeout timer (5 seconds)
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.cancelRecording()
            }
            
            // Start listening for keyboard events
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                return self?.handleKeyEvent(event) ?? event
            }
        }
        
        func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
            guard isRecording else { return event }
            
            // Handle Escape to cancel
            if event.keyCode == kVK_Escape {
                cancelRecording()
                return nil
            }
            
            // Only process keyDown events (not just modifiers)
            guard event.type == .keyDown else { return event }
            
            // Get modifiers
            var modifiers: Int = 0
            if event.modifierFlags.contains(.command) { modifiers |= cmdKey }
            if event.modifierFlags.contains(.option) { modifiers |= optionKey }
            if event.modifierFlags.contains(.control) { modifiers |= controlKey }
            if event.modifierFlags.contains(.shift) { modifiers |= shiftKey }
            
            // Require at least one modifier OR function key
            // For simplicity, we enforce modifiers for most keys to avoid typing conflict
            let isFunctionKey = (event.modifierFlags.contains(.function))
            if modifiers == 0 && !isFunctionKey {
                 // Ignore plain keys without modifiers
                 return event
            }
            
            let keyCombo = KeyCombo(keyCode: Int(event.keyCode), modifiers: modifiers)
            
            // Check for conflicts
            if let actionType = actionType {
                let validation = EnhancedShortcutManager.shared.validate(keyCombo, observing: actionType)
                if case .conflict(let msg) = validation {
                    showConflictWarning(message: msg)
                    return nil // Consume event
                }
            }
            
            // Update shortcut
            keyComboBinding.wrappedValue = keyCombo
            
            finishRecording()
            return nil
        }
        
        private func showConflictWarning(message: String) {
            // Flash red
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                self?.containerView?.layer?.backgroundColor = NSColor.systemBlue.cgColor
            }
            containerView?.layer?.backgroundColor = NSColor.systemRed.cgColor
            CATransaction.commit()
            
            let originalText = textField?.stringValue
            textField?.stringValue = message
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if self?.isRecording == true {
                    self?.textField?.stringValue = "按下快捷键..."
                }
            }
        }
        
        private func addPulseAnimation() {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.8
            animation.toValue = 1.0
            animation.duration = 0.8
            animation.autoreverses = true
            animation.repeatCount = .infinity
            containerView?.layer?.add(animation, forKey: "pulse")
        }
        
        private func removePulseAnimation() {
            containerView?.layer?.removeAnimation(forKey: "pulse")
        }
        
        func cancelRecording() {
            isRecording = false
            updateTextFieldDisplay()
            resetStyle()
            removePulseAnimation()
            cleanup()
        }
        
        func finishRecording() {
            isRecording = false
            updateTextFieldDisplay()
            resetStyle()
            removePulseAnimation()
            cleanup()
            
            // Success feedback
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                self?.containerView?.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
            }
            containerView?.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.3).cgColor
            CATransaction.commit()
        }
        
        private func cleanup() {
            timeoutTimer?.invalidate()
            timeoutTimer = nil
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            
            // Show clear button again if valid
            if keyComboBinding.wrappedValue.isValid {
                 clearButton?.isHidden = false
            }
        }
        
        private func resetStyle() {
            textField?.textColor = .labelColor
            containerView?.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
            containerView?.layer?.borderColor = NSColor.secondaryLabelColor.withAlphaComponent(0.2).cgColor
        }
        
        private func updateTextFieldDisplay() {
            guard let textField = textField else { return }
            textField.stringValue = formatShortcut(keyComboBinding.wrappedValue)
        }
        
        // Helper
        private func formatShortcut(_ combo: KeyCombo) -> String {
            guard combo.isValid else { return "未设置" }
            var parts: [String] = []
            
            if combo.modifiers & cmdKey != 0 { parts.append("⌘") }
            if combo.modifiers & optionKey != 0 { parts.append("⌥") }
            if combo.modifiers & controlKey != 0 { parts.append("⌃") }
            if combo.modifiers & shiftKey != 0 { parts.append("⇧") }
            
            if let keyChar = keyCodeToChar(UInt32(combo.keyCode)) {
                parts.append(keyChar)
            } else {
                parts.append("Key(\(combo.keyCode))")
            }
            
            return parts.joined()
        }
        
        private func keyCodeToChar(_ keyCode: UInt32) -> String? {
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
                0x33: "Delete", 0x35: "Esc"
            ]
            return keyMap[keyCode]
        }
    }
}

// MARK: - Clickable Text Field

class ClickableTextField: NSTextField {
    weak var coordinator: ShortcutRecorderView.Coordinator?
    
    override func mouseDown(with event: NSEvent) {
        coordinator?.handleClick()
    }
    
    override var acceptsFirstResponder: Bool { true }
}

// MARK: - Helper

private func formatShortcut(_ combo: KeyCombo) -> String {
    guard combo.isValid else { return "点击录制" }
    var parts: [String] = []
    
    // Carbon modifiers mapping matches what we use in KeyCombo
    if combo.modifiers & cmdKey != 0 { parts.append("⌘") }
    if combo.modifiers & optionKey != 0 { parts.append("⌥") }
    if combo.modifiers & controlKey != 0 { parts.append("⌃") }
    if combo.modifiers & shiftKey != 0 { parts.append("⇧") }
    
    // Basic key mapping
    // This duplicates the method inside Coordinator, but useful for initial render
    // Ideally share this logic
    return parts.joined() + (getKeyChar(UInt32(combo.keyCode)) ?? "Key")
}

private func getKeyChar(_ keyCode: UInt32) -> String? {
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
        0x33: "Delete", 0x35: "Esc"
    ]
    return keyMap[keyCode]
}
