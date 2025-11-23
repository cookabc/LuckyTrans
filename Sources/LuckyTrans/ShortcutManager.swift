import Cocoa
import Carbon

protocol ShortcutManagerDelegate: AnyObject {
    func shortcutDidTrigger()
}

class ShortcutManager {
    weak var delegate: ShortcutManagerDelegate?
    
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyID = EventHotKeyID(signature: FourCharCode(fromString: "LTrn"), id: 1)
    
    init() {
        registerShortcut()
    }
    
    deinit {
        unregister()
    }
    
    func registerShortcut() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // 安装事件处理器
        InstallApplicationEventHandler({ (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let err = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if err == noErr {
                if let manager = Unmanaged<ShortcutManager>.fromOpaque(userData!).takeUnretainedValue() as ShortcutManager? {
                    DispatchQueue.main.async {
                        manager.delegate?.shortcutDidTrigger()
                    }
                }
            }
            
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)
        
        // 注册快捷键：Cmd + Shift + T
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(0x11) // 'T' key
        
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            self.hotKeyRef = hotKeyRef
        }
    }
    
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}

extension FourCharCode {
    init(fromString string: String) {
        var result: FourCharCode = 0
        for (index, char) in string.utf8.prefix(4).enumerated() {
            result |= FourCharCode(char) << (8 * (3 - index))
        }
        self = result
    }
}

