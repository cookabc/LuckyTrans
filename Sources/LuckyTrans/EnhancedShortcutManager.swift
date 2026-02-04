import Cocoa
import Carbon
import SwiftUI

class EnhancedShortcutManager: ObservableObject {
    static let shared = EnhancedShortcutManager()
    
    // Published dictionary of current shortcuts
    @Published var shortcuts: [ShortcutActionType: KeyCombo] = [:]
    
    // Delegates to handle actions
    typealias ActionHandler = () -> Void
    private var actionHandlers: [ShortcutActionType: ActionHandler] = [:]
    
    // Carbon Event references
    private var hotKeyRefs: [ShortcutActionType: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?
    
    private let defaultsKey = "LuckyTrans_Shortcuts_Config"
    
    private init() {
        loadShortcuts()
        setupEventHandler()
        registerAllShortcuts()
    }
    
    deinit {
        unregisterAll()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
    
    // MARK: - Public API
    
    func setShortcut(for type: ShortcutActionType, keyCombo: KeyCombo) {
        // Unregister old
        unregisterShortcut(type)
        
        // Update model
        shortcuts[type] = keyCombo
        saveShortcuts()
        
        // Register new
        registerShortcut(type, keyCombo: keyCombo)
    }
    
    func getShortcut(for type: ShortcutActionType) -> KeyCombo? {
        return shortcuts[type]
    }
    
    func removeShortcut(for type: ShortcutActionType) {
        unregisterShortcut(type)
        shortcuts.removeValue(forKey: type)
        saveShortcuts()
    }
    
    func registerActionHandler(for type: ShortcutActionType, handler: @escaping ActionHandler) {
        actionHandlers[type] = handler
    }
    
    // MARK: - Persistence
    
    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([ShortcutActionType: KeyCombo].self, from: data) {
            self.shortcuts = saved
        } else {
            // Load defaults
            for type in ShortcutActionType.allCases {
                if let defaultCombo = type.defaultKeyCombo {
                    shortcuts[type] = defaultCombo
                }
            }
        }
        
        // Legacy migration: check SettingsManager if nothing found
        // (Simplified for now, assuming new system takes over)
    }
    
    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    // MARK: - Carbon Events
    
    private func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
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
                // Recover the manager instance
                let manager = Unmanaged<EnhancedShortcutManager>.fromOpaque(userData!).takeUnretainedValue()
                
                // Find which action triggered this
                // signature is 'LTrn', id is the index or rawValue hash? 
                // We'll use id as the hash of the action string to map back.
                
                DispatchQueue.main.async {
                    manager.handleHotKeyTrigger(id: hotKeyID.id)
                }
            }
            
            return noErr
        }
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        
        if status != noErr {
            print("❌ Failed to install global event handler: \(status)")
        }
    }
    
    private func registerAllShortcuts() {
        for (type, combo) in shortcuts {
            registerShortcut(type, keyCombo: combo)
        }
    }
    
    private func getID(for type: ShortcutActionType) -> UInt32 {
        // Use the index in allCases + 1 ensures unique positive ID
        if let index = ShortcutActionType.allCases.firstIndex(of: type) {
            return UInt32(index + 1)
        }
        return 0
    }
    
    private func getType(forID id: UInt32) -> ShortcutActionType? {
        let index = Int(id) - 1
        let allCases = ShortcutActionType.allCases
        if index >= 0 && index < allCases.count {
            return allCases[index]
        }
        return nil
    }

    private func registerShortcut(_ type: ShortcutActionType, keyCombo: KeyCombo) {
        guard keyCombo.isValid else { return }
        
        let hotKeyID = EventHotKeyID(signature: FourCharCode(fromString: "LTrn"), id: getID(for: type))
        var ref: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            keyCombo.carbonKeyCode,
            keyCombo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        
        if status == noErr {
            hotKeyRefs[type] = ref
            print("✅ Registered shortcut for \(type.displayName): \(keyCombo.carbonKeyCode)")
        } else {
            print("❌ Failed to register shortcut for \(type.displayName): \(status)")
        }
    }
    
    private func unregisterShortcut(_ type: ShortcutActionType) {
        if let ref = hotKeyRefs[type] {
            UnregisterEventHotKey(ref)
            hotKeyRefs.removeValue(forKey: type)
        }
    }
    
    private func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }
    
    private func handleHotKeyTrigger(id: UInt32) {
        // Find action by ID
        if let type = getType(forID: id) {
            print("🚀 Executing action: \(type.displayName)")
            actionHandlers[type]?()
        }
    }
    
    // MARK: - Validation
    
    func validate(_ keyCombo: KeyCombo, observing type: ShortcutActionType) -> ValidationResult {
        // Check system conflicts
        if isSystemConflict(keyCombo) {
            return .conflict("与系统快捷键冲突")
        }
        
        // Check app conflicts (other actions)
        for (otherType, otherCombo) in shortcuts {
            if otherType != type && otherCombo == keyCombo {
                return .conflict("与 \(otherType.displayName) 冲突")
            }
        }
        
        return .valid
    }
    
    private func isSystemConflict(_ keyCombo: KeyCombo) -> Bool {
        // Common system shortcuts
        let conflicts: [KeyCombo] = [
            KeyCombo(keyCode: kVK_ANSI_Q, modifiers: cmdKey), // Cmd+Q
            KeyCombo(keyCode: kVK_ANSI_W, modifiers: cmdKey), // Cmd+W
            KeyCombo(keyCode: kVK_Tab, modifiers: cmdKey),    // Cmd+Tab
            KeyCombo(keyCode: kVK_Space, modifiers: cmdKey),  // Spotlight (defaults)
        ]
        return conflicts.contains(keyCombo)
    }
}

enum ValidationResult {
    case valid
    case conflict(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .conflict: return false
        }
    }
    
    var message: String? {
        switch self {
        case .valid: return nil
        case .conflict(let msg): return msg
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


