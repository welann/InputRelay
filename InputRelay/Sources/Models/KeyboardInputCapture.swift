import AppKit

struct KeyboardInputCapture {
    private var heldKeys: Set<Int>
    private var heldModifiers: KeyboardShortcut.ModifierFlags
    private var keys: [Int] = []
    private var modifiers: KeyboardShortcut.ModifierFlags = []
    private var isFinishing = false
    private(set) var isWaitingForRelease: Bool

    init(heldKeys: Set<Int> = [], heldModifiers: KeyboardShortcut.ModifierFlags = []) {
        self.heldKeys = heldKeys
        self.heldModifiers = heldModifiers
        isWaitingForRelease = !heldKeys.isEmpty || !heldModifiers.isEmpty
    }

    var preview: KeyboardShortcut? {
        let shortcut = KeyboardShortcut(keyCodes: keys, modifiers: modifiers)
        return shortcut.isValid ? shortcut : nil
    }

    mutating func receive(_ event: NSEvent) -> KeyboardShortcut? {
        let code = Int(event.keyCode)
        let previousModifiers = heldModifiers
        heldModifiers = .init(eventFlags: event.modifierFlags)
        switch event.type {
        case .keyDown: heldKeys.insert(code)
        case .keyUp: heldKeys.remove(code)
        case .flagsChanged: break
        default: return nil
        }

        if isWaitingForRelease {
            isWaitingForRelease = !heldKeys.isEmpty || !heldModifiers.isEmpty
            return nil
        }
        // 第一次松键后只等待剩余按键释放，不把下一组输入合并成宏。
        if (event.type == .keyUp && keys.contains(code)) || !previousModifiers.subtracting(heldModifiers).isEmpty {
            isFinishing = true
        }
        if !isFinishing {
            modifiers.formUnion(heldModifiers)
            if event.type == .keyDown && !event.isARepeat && !keys.contains(code) {
                keys.append(code)
            }
        }
        return heldKeys.isEmpty && heldModifiers.isEmpty ? preview : nil
    }
}
