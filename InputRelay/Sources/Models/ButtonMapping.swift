import Foundation
import Carbon

/// 映射动作类型
enum MappingAction: Codable, Equatable {
    case keyboardShortcut(KeyboardShortcut)
    case mouseAction(MouseAction)
    case customScript(String)
    case mouseMovement(axis: MouseAxis, sensitivity: Float)
    
    enum MouseAxis: String, Codable {
        case horizontal
        case vertical
    }

    var displayName: String {
        switch self {
        case .keyboardShortcut(let shortcut): return shortcut.displayString
        case .mouseAction(let action): return action.rawValue
        case .customScript(let script): return "脚本: \(script.prefix(30))"
        case .mouseMovement(let axis, _): return "鼠标\(axis == .horizontal ? "水平" : "垂直")移动"
        }
    }
}

/// 键盘快捷键定义
struct KeyboardShortcut: Codable, Equatable {
    let keyCode: Int  // CGKeyCode
    let modifiers: ModifierFlags
    
    struct ModifierFlags: OptionSet, Codable, Equatable {
        let rawValue: UInt32
        
        static let command = ModifierFlags(rawValue: 1 << 0)
        static let shift = ModifierFlags(rawValue: 1 << 1)
        static let option = ModifierFlags(rawValue: 1 << 2)
        static let control = ModifierFlags(rawValue: 1 << 3)
        
        var cgEventFlags: CGEventFlags {
            var flags: CGEventFlags = []
            if contains(.command) { flags.insert(.maskCommand) }
            if contains(.shift) { flags.insert(.maskShift) }
            if contains(.option) { flags.insert(.maskAlternate) }
            if contains(.control) { flags.insert(.maskControl) }
            return flags
        }
    }
    
    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }
    
    private func keyCodeToString(_ code: Int) -> String {
        // 常见按键映射
        switch code {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_ANSI_A...kVK_ANSI_Z:
            return String(UnicodeScalar(code - kVK_ANSI_A + 65)!)
        default: return "Key\(code)"
        }
    }
}

/// 鼠标动作
enum MouseAction: String, Codable {
    case leftClick = "Left Click"
    case rightClick = "Right Click"
    case middleClick = "Middle Click"
    case scrollUp = "Scroll Up"
    case scrollDown = "Scroll Down"
}

/// 单个按键的映射配置
struct ButtonMapping: Codable, Identifiable {
    let id: UUID
    let button: GamepadButton
    var action: MappingAction
    var enabled: Bool
    
    init(id: UUID = UUID(), button: GamepadButton, action: MappingAction, enabled: Bool = true) {
        self.id = id
        self.button = button
        self.action = action
        self.enabled = enabled
    }
}
