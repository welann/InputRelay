import AppKit
import Carbon

struct KeyboardShortcut: Codable, Equatable {
    let keyCodes: [Int]
    let modifiers: ModifierFlags

    init(keyCode: Int, modifiers: ModifierFlags) {
        self.init(keyCodes: [keyCode], modifiers: modifiers)
    }

    init(keyCodes: [Int], modifiers: ModifierFlags) {
        var seen = Set<Int>()
        self.keyCodes = keyCodes.filter { seen.insert($0).inserted }
        self.modifiers = modifiers
    }

    var isValid: Bool {
        (!keyCodes.isEmpty || !modifiers.isEmpty) && keyCodes.allSatisfy { UInt16(exactly: $0) != nil }
    }

    private enum CodingKeys: String, CodingKey { case keyCode, keyCodes, modifiers }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let keys: [Int]
        if let multiple = try values.decodeIfPresent([Int].self, forKey: .keyCodes) {
            keys = multiple
        } else {
            keys = [try values.decode(Int.self, forKey: .keyCode)]
        }
        self.init(keyCodes: keys, modifiers: try values.decode(ModifierFlags.self, forKey: .modifiers))
        guard isValid else {
            throw DecodingError.dataCorruptedError(forKey: .keyCodes, in: values, debugDescription: "Invalid keyboard shortcut")
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        // 单键继续使用旧字段，已有配置无需迁移。
        if keyCodes.count == 1 {
            try values.encode(keyCodes[0], forKey: .keyCode)
        } else {
            try values.encode(keyCodes, forKey: .keyCodes)
        }
        try values.encode(modifiers, forKey: .modifiers)
    }

    struct ModifierFlags: OptionSet, Codable, Equatable, Sendable {
        let rawValue: UInt32
        init(rawValue: UInt32) { self.rawValue = rawValue }

        static let command = ModifierFlags(rawValue: 1 << 0)
        static let shift = ModifierFlags(rawValue: 1 << 1)
        static let option = ModifierFlags(rawValue: 1 << 2)
        static let control = ModifierFlags(rawValue: 1 << 3)

        init(eventFlags: NSEvent.ModifierFlags) {
            self = []
            if eventFlags.contains(.command) { insert(.command) }
            if eventFlags.contains(.shift) { insert(.shift) }
            if eventFlags.contains(.option) { insert(.option) }
            if eventFlags.contains(.control) { insert(.control) }
        }

        var cgEventFlags: CGEventFlags {
            var flags: CGEventFlags = []
            if contains(.command) { flags.insert(.maskCommand) }
            if contains(.shift) { flags.insert(.maskShift) }
            if contains(.option) { flags.insert(.maskAlternate) }
            if contains(.control) { flags.insert(.maskControl) }
            return flags
        }

        static let keyCodes: [(flag: Self, code: Int)] = [
            (.control, kVK_Control), (.option, kVK_Option),
            (.shift, kVK_Shift), (.command, kVK_Command)
        ]

        var displayString: String {
            [(Self.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
                .filter { contains($0.0) }.map(\.1).joined()
        }
    }

    var displayString: String {
        modifiers.displayString + keyCodes.map { Self.keyName($0) }.joined(separator: " + ")
    }

    static func keyName(_ code: Int) -> String {
        keyNames[code] ?? "Key\(code)"
    }

    static let keyNames: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=", kVK_ANSI_LeftBracket: "[",
        kVK_ANSI_RightBracket: "]", kVK_ANSI_Backslash: "\\", kVK_ANSI_Semicolon: ";",
        kVK_ANSI_Quote: "'", kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".",
        kVK_ANSI_Slash: "/", kVK_ANSI_Grave: "`", kVK_ISO_Section: "§",
        kVK_Return: "Return ↩", kVK_Tab: "Tab ⇥", kVK_Space: "Space",
        kVK_Delete: "Delete ⌫", kVK_ForwardDelete: "Forward Delete ⌦", kVK_Escape: "Esc",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "Home", kVK_End: "End", kVK_PageUp: "Page Up", kVK_PageDown: "Page Down",
        kVK_Help: "Help", kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9",
        kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13",
        kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17",
        kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
        kVK_ANSI_Keypad0: "Num 0", kVK_ANSI_Keypad1: "Num 1", kVK_ANSI_Keypad2: "Num 2",
        kVK_ANSI_Keypad3: "Num 3", kVK_ANSI_Keypad4: "Num 4", kVK_ANSI_Keypad5: "Num 5",
        kVK_ANSI_Keypad6: "Num 6", kVK_ANSI_Keypad7: "Num 7", kVK_ANSI_Keypad8: "Num 8",
        kVK_ANSI_Keypad9: "Num 9", kVK_ANSI_KeypadDecimal: "Num .",
        kVK_ANSI_KeypadMultiply: "Num *", kVK_ANSI_KeypadPlus: "Num +",
        kVK_ANSI_KeypadClear: "Num Clear", kVK_ANSI_KeypadDivide: "Num /",
        kVK_ANSI_KeypadEnter: "Num Enter", kVK_ANSI_KeypadMinus: "Num -", kVK_ANSI_KeypadEquals: "Num ="
    ]
}
