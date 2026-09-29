import Foundation
import CoreGraphics
import Carbon

/// 键盘模拟器 - 负责模拟键盘按键
class KeyboardSimulator {
    private let postSequence: ([CGEvent], Int) -> Void

    init(postEvent: ((CGEvent) -> Void)? = nil) {
        self.postSequence = postEvent.map { sink in { events, _ in events.forEach(sink) } }
            ?? { InputEventSequence.post($0, pauseBefore: $1) }
    }
    
    /// 发送键盘快捷键
    func sendShortcut(_ shortcut: KeyboardShortcut) {
        guard shortcut.isValid else { return }
        let modifierKeys = KeyboardShortcut.ModifierFlags.keyCodes.filter { shortcut.modifiers.contains($0.flag) }
        var flags: KeyboardShortcut.ModifierFlags = []
        var events: [CGEvent] = []
        func append(_ code: Int, down: Bool) -> Bool {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: down) else { return false }
            event.flags = flags.cgEventFlags
            events.append(event)
            return true
        }
        // 先创建完整的按下/松开序列，创建失败时不留下卡住的按键。
        for key in modifierKeys {
            flags.insert(key.flag)
            guard append(key.code, down: true) else { return }
        }
        for code in shortcut.keyCodes {
            guard append(code, down: true) else { return }
        }
        let downCount = events.count
        for code in shortcut.keyCodes.reversed() {
            guard append(code, down: false) else { return }
        }
        for key in modifierKeys.reversed() {
            flags.remove(key.flag)
            guard append(key.code, down: false) else { return }
        }
        postSequence(events, downCount)
    }
    
    /// 发送单个按键（无修饰键）
    func sendKey(_ keyCode: Int) {
        let shortcut = KeyboardShortcut(keyCode: keyCode, modifiers: [])
        sendShortcut(shortcut)
    }
    
    /// 发送文本（逐字符）
    func sendText(_ text: String) {
        for char in text {
            if let keyCode = charToKeyCode(char) {
                sendKey(keyCode)
                // Each key pair is serialized by the event queue without blocking the caller.
            }
        }
    }
    
    private func charToKeyCode(_ char: Character) -> Int? {
        let lower = char.lowercased().first
        
        switch lower {
        case "a": return kVK_ANSI_A
        case "b": return kVK_ANSI_B
        case "c": return kVK_ANSI_C
        case "d": return kVK_ANSI_D
        case "e": return kVK_ANSI_E
        case "f": return kVK_ANSI_F
        case "g": return kVK_ANSI_G
        case "h": return kVK_ANSI_H
        case "i": return kVK_ANSI_I
        case "j": return kVK_ANSI_J
        case "k": return kVK_ANSI_K
        case "l": return kVK_ANSI_L
        case "m": return kVK_ANSI_M
        case "n": return kVK_ANSI_N
        case "o": return kVK_ANSI_O
        case "p": return kVK_ANSI_P
        case "q": return kVK_ANSI_Q
        case "r": return kVK_ANSI_R
        case "s": return kVK_ANSI_S
        case "t": return kVK_ANSI_T
        case "u": return kVK_ANSI_U
        case "v": return kVK_ANSI_V
        case "w": return kVK_ANSI_W
        case "x": return kVK_ANSI_X
        case "y": return kVK_ANSI_Y
        case "z": return kVK_ANSI_Z
        case " ": return kVK_Space
        default: return nil
        }
    }
}

// 常用按键代码常量
extension KeyboardSimulator {
    static let keyCodes: [String: Int] = [
        "Return": kVK_Return,
        "Tab": kVK_Tab,
        "Space": kVK_Space,
        "Delete": kVK_Delete,
        "Escape": kVK_Escape,
        "Command": kVK_Command,
        "Shift": kVK_Shift,
        "Option": kVK_Option,
        "Control": kVK_Control,
        "LeftArrow": kVK_LeftArrow,
        "RightArrow": kVK_RightArrow,
        "UpArrow": kVK_UpArrow,
        "DownArrow": kVK_DownArrow,
        "F1": kVK_F1,
        "F2": kVK_F2,
        "F3": kVK_F3,
        "F4": kVK_F4,
        "F5": kVK_F5,
        "F6": kVK_F6,
        "F7": kVK_F7,
        "F8": kVK_F8,
        "F9": kVK_F9,
        "F10": kVK_F10,
        "F11": kVK_F11,
        "F12": kVK_F12
    ]
}
