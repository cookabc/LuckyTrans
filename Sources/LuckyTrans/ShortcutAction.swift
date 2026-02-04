import Foundation
import Carbon

/// 定义快捷键组合
struct KeyCombo: Codable, Equatable, Hashable {
    let keyCode: Int
    let modifiers: Int
    
    var carbonKeyCode: UInt32 { UInt32(keyCode) }
    var carbonModifiers: UInt32 { UInt32(modifiers) }
    
    static let zero = KeyCombo(keyCode: -1, modifiers: 0)
    
    var isValid: Bool {
        return keyCode >= 0
    }
}

/// 定义应用支持的快捷键动作类型
enum ShortcutActionType: String, CaseIterable, Codable, Identifiable {
    case translateSelection = "translate_selection"
    case screenshotOCR = "screenshot_ocr"
    case openSettings = "open_settings"
    case toggleMiniWindow = "toggle_mini_window"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .translateSelection: return "划词翻译"
        case .screenshotOCR: return "截图 OCR"
        case .openSettings: return "打开设置"
        case .toggleMiniWindow: return "显示/隐藏迷你窗口"
        }
    }
    
    var defaultKeyCombo: KeyCombo? {
        switch self {
        case .translateSelection:
            // Cmd + Shift + T
            return KeyCombo(keyCode: kVK_ANSI_T, modifiers: cmdKey | shiftKey)
        case .screenshotOCR:
            // Cmd + Shift + O
            return KeyCombo(keyCode: kVK_ANSI_O, modifiers: cmdKey | shiftKey)
        case .openSettings:
            // Cmd + ,
            return KeyCombo(keyCode: kVK_ANSI_Comma, modifiers: cmdKey)
        default:
            return nil
        }
    }
}

/// 快捷键动作模型
struct ShortcutAction: Identifiable {
    let type: ShortcutActionType
    var keyCombo: KeyCombo
    
    var id: String { type.rawValue }
    
    var title: String { type.displayName }
}
