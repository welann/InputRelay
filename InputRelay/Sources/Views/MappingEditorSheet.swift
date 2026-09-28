import SwiftUI
import Carbon

struct MappingEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    let mapping: ButtonMapping?
    @ObservedObject var gamepadManager: GamepadManager
    let onSave: (ButtonMapping) -> Void
    
    @State private var selectedButton: GamepadButton
    @State private var actionType: ActionType = .keyboard
    @State private var keyCode: Int = kVK_Return
    @State private var modifiers: KeyboardShortcut.ModifierFlags = []
    @State private var mouseAction: MouseAction = .leftClick
    @State private var customScript: String = ""
    @State private var isWaitingForInput = false
    
    enum ActionType: String, CaseIterable {
        case keyboard = "键盘快捷键"
        case mouse = "鼠标操作"
        case script = "自定义脚本"
    }
    
    init(mapping: ButtonMapping?, gamepadManager: GamepadManager, onSave: @escaping (ButtonMapping) -> Void) {
        self.mapping = mapping
        self.gamepadManager = gamepadManager
        self.onSave = onSave
        
        if let mapping = mapping {
            _selectedButton = State(initialValue: mapping.button)
            
            switch mapping.action {
            case .keyboardShortcut(let shortcut):
                _actionType = State(initialValue: .keyboard)
                _keyCode = State(initialValue: shortcut.keyCode)
                _modifiers = State(initialValue: shortcut.modifiers)
            case .mouseAction(let action):
                _actionType = State(initialValue: .mouse)
                _mouseAction = State(initialValue: action)
            case .customScript(let script):
                _actionType = State(initialValue: .script)
                _customScript = State(initialValue: script)
            case .mouseMovement:
                _actionType = State(initialValue: .mouse)
            }
        } else {
            _selectedButton = State(initialValue: .buttonA)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(mapping == nil ? "新建映射" : "编辑映射")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#E5E7EB"))
            
            // 选择按键
            VStack(alignment: .leading, spacing: 8) {
                Text("手柄按键")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                if isWaitingForInput {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("按下手柄上的任意按键...")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#38BDF8"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#0F131C"))
                    .cornerRadius(8)
                } else {
                    Button(action: startWaitingForInput) {
                        HStack {
                            Text(selectedButton.displayName)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#E5E7EB"))
                            Spacer()
                            Image(systemName: "gamecontroller")
                                .foregroundColor(Color(hex: "#38BDF8"))
                        }
                        .padding()
                        .background(Color(hex: "#0F131C"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Divider()
                .background(Color(hex: "#1E2636"))
            
            // 选择动作类型
            VStack(alignment: .leading, spacing: 8) {
                Text("映射动作")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Picker("", selection: $actionType) {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 动作配置
            Group {
                switch actionType {
                case .keyboard:
                    KeyboardShortcutEditor(keyCode: $keyCode, modifiers: $modifiers)
                case .mouse:
                    MouseActionEditor(action: $mouseAction)
                case .script:
                    CustomScriptEditor(script: $customScript)
                }
            }
            
            Spacer()
            
            // 按钮
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("保存") {
                    saveMapping()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding(24)
        .frame(width: 500, height: 450)
        .background(Color(hex: "#0A0D12"))
        .onAppear {
            setupGamepadListener()
        }
    }
    
    private func setupGamepadListener() {
        gamepadManager.setEventHandler { [self] event in
            if isWaitingForInput && event.isPressed {
                DispatchQueue.main.async {
                    self.selectedButton = event.button
                    self.isWaitingForInput = false
                }
            }
        }
    }
    
    private func startWaitingForInput() {
        isWaitingForInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isWaitingForInput {
                isWaitingForInput = false
            }
        }
    }
    
    private func saveMapping() {
        let action: MappingAction
        
        switch actionType {
        case .keyboard:
            action = .keyboardShortcut(KeyboardShortcut(keyCode: keyCode, modifiers: modifiers))
        case .mouse:
            action = .mouseAction(mouseAction)
        case .script:
            action = .customScript(customScript)
        }
        
        let newMapping = ButtonMapping(
            id: mapping?.id ?? UUID(),
            button: selectedButton,
            action: action,
            enabled: mapping?.enabled ?? true
        )
        
        onSave(newMapping)
        dismiss()
    }
}

struct KeyboardShortcutEditor: View {
    @Binding var keyCode: Int
    @Binding var modifiers: KeyboardShortcut.ModifierFlags
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 修饰键
            HStack(spacing: 12) {
                ModifierButton(title: "⌃", isActive: modifiers.contains(.control)) {
                    modifiers.toggle(.control)
                }
                ModifierButton(title: "⌥", isActive: modifiers.contains(.option)) {
                    modifiers.toggle(.option)
                }
                ModifierButton(title: "⇧", isActive: modifiers.contains(.shift)) {
                    modifiers.toggle(.shift)
                }
                ModifierButton(title: "⌘", isActive: modifiers.contains(.command)) {
                    modifiers.toggle(.command)
                }
            }
            
            // 按键选择
            VStack(alignment: .leading, spacing: 4) {
                Text("按键")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                
                Picker("", selection: $keyCode) {
                    ForEach(commonKeys, id: \.value) { key in
                        Text(key.name).tag(key.value)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(hex: "#0F131C"))
        .cornerRadius(8)
    }
    
    private let commonKeys: [(name: String, value: Int)] = [
        ("A", kVK_ANSI_A), ("B", kVK_ANSI_B), ("C", kVK_ANSI_C), ("D", kVK_ANSI_D),
        ("E", kVK_ANSI_E), ("F", kVK_ANSI_F), ("G", kVK_ANSI_G), ("H", kVK_ANSI_H),
        ("I", kVK_ANSI_I), ("J", kVK_ANSI_J), ("K", kVK_ANSI_K), ("L", kVK_ANSI_L),
        ("M", kVK_ANSI_M), ("N", kVK_ANSI_N), ("O", kVK_ANSI_O), ("P", kVK_ANSI_P),
        ("Q", kVK_ANSI_Q), ("R", kVK_ANSI_R), ("S", kVK_ANSI_S), ("T", kVK_ANSI_T),
        ("U", kVK_ANSI_U), ("V", kVK_ANSI_V), ("W", kVK_ANSI_W), ("X", kVK_ANSI_X),
        ("Y", kVK_ANSI_Y), ("Z", kVK_ANSI_Z),
        ("Return ↩", kVK_Return), ("Tab ⇥", kVK_Tab), ("Space", kVK_Space),
        ("Delete ⌫", kVK_Delete), ("Escape ⎋", kVK_Escape),
        ("← Left", kVK_LeftArrow), ("→ Right", kVK_RightArrow),
        ("↑ Up", kVK_UpArrow), ("↓ Down", kVK_DownArrow),
        ("F1", kVK_F1), ("F2", kVK_F2), ("F3", kVK_F3), ("F4", kVK_F4),
        ("F5", kVK_F5), ("F6", kVK_F6), ("F7", kVK_F7), ("F8", kVK_F8)
    ]
}

struct ModifierButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isActive ? Color(hex: "#05070C") : Color(hex: "#9CA3AF"))
                .frame(width: 44, height: 44)
                .background(isActive ? Color(hex: "#38BDF8") : Color(hex: "#161D2B"))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MouseActionEditor: View {
    @Binding var action: MouseAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach([MouseAction.leftClick, .rightClick, .middleClick, .scrollUp, .scrollDown], id: \.self) { mouseAction in
                Button(action: { action = mouseAction }) {
                    HStack {
                        Image(systemName: action == mouseAction ? "circle.fill" : "circle")
                            .foregroundColor(Color(hex: "#38BDF8"))
                        Text(mouseAction.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#E5E7EB"))
                        Spacer()
                    }
                    .padding(12)
                    .background(action == mouseAction ? Color(hex: "#161D2B") : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(hex: "#0F131C"))
        .cornerRadius(8)
    }
}

struct CustomScriptEditor: View {
    @Binding var script: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shell 命令")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
            
            TextEditor(text: $script)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(hex: "#E5E7EB"))
                .frame(height: 100)
                .padding(8)
                .background(Color(hex: "#05070C"))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(hex: "#0F131C"))
        .cornerRadius(8)
    }
}

extension KeyboardShortcut.ModifierFlags {
    mutating func toggle(_ flag: KeyboardShortcut.ModifierFlags) {
        if contains(flag) {
            remove(flag)
        } else {
            insert(flag)
        }
    }
}
