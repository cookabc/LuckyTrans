import Cocoa
import Carbon

protocol ShortcutManagerDelegate: AnyObject {
    func shortcutDidTrigger()
}

class ShortcutManager {
    weak var delegate: ShortcutManagerDelegate?
    
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyID = EventHotKeyID(signature: FourCharCode(fromString: "LTrn"), id: 1)
    private var handlerRef: EventHandlerRef?
    
    init() {
        setupEventHandler()
        registerShortcut()
        
        // 监听快捷键变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutDidChange),
            name: NSNotification.Name("ShortcutDidChange"),
            object: nil
        )
    }
    
    deinit {
        unregister()
        if let handlerRef = handlerRef {
            RemoveEventHandler(handlerRef)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func shortcutDidChange() {
        // 重新注册快捷键
        unregister()
        registerShortcut()
    }
    
    private func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // 安装事件处理器
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
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
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        
        guard handlerStatus == noErr else {
            print("Failed to install event handler: \(handlerStatus)")
            return
        }
    }
    
    func registerShortcut() {
        // 从 SettingsManager 获取快捷键设置
        let settings = SettingsManager.shared
        let keyCode = settings.shortcutKeyCode
        let modifiers = settings.shortcutModifiers
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if hotKeyStatus == noErr {
            self.hotKeyRef = hotKeyRef
        } else {
            print("Failed to register hotkey: \(hotKeyStatus)")
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

