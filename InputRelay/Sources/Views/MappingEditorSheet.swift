import SwiftUI
import Carbon

struct MappingEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    let mapping: ButtonMapping?
    let existingMappings: [ButtonMapping]
    @ObservedObject var gamepadManager: GamepadManager
    let onSave: (ButtonMapping, Bool) -> Bool

    @State private var capture: MappingInputCapture
    @State private var actionType: ActionType = .keyboard
    @State private var keyCode: Int = kVK_Return
    @State private var modifiers: KeyboardShortcut.ModifierFlags = []
    @State private var mouseAction: MouseAction = .leftClick
    @State private var customScript = ""
    @State private var showingReplaceAlert = false
    @State private var saveRejected = false

    enum ActionType: String, CaseIterable {
        case keyboard = "键盘快捷键"
        case mouse = "鼠标操作"
        case script = "自定义脚本"
    }

    init(mapping: ButtonMapping?, existingMappings: [ButtonMapping], gamepadManager: GamepadManager,
         onSave: @escaping (ButtonMapping, Bool) -> Bool) {
        self.mapping = mapping
        self.existingMappings = existingMappings
        self.gamepadManager = gamepadManager
        self.onSave = onSave
        _capture = State(initialValue: MappingInputCapture(selectedButton: mapping?.button))
        if let mapping {
            switch mapping.action {
            case .keyboardShortcut(let shortcut):
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
        }
    }

    private var conflicts: [ButtonMapping] {
        existingMappings.filter { $0.button == capture.selectedButton && $0.id != mapping?.id }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(mapping == nil ? "新建映射" : "编辑映射")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.text)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("手柄按键")
                            .font(.system(size: 13, weight: .medium))
                        HStack(spacing: 12) {
                            Image(systemName: capture.isWaiting ? "gamecontroller" : "checkmark.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(capture.isWaiting ? (gamepadManager.isConnected ? "请按下要绑定的手柄按键" : "请连接手柄，然后按下要绑定的按键") : (capture.selectedButton.map { "已选择 \($0.displayName)" } ?? "尚未选择按键"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text("一次按一个键；已按住的键请先松开再按。")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppTheme.inset)
                        .cornerRadius(10)

                        HStack {
                            Button(capture.isWaiting ? "停止识别" : "重新识别") {
                                if capture.isWaiting { capture.stop() } else { startWaitingForInput() }
                            }
                            Menu("手动选择") {
                                ForEach(GamepadButton.allCases.filter { !$0.isStickAxis }, id: \.self) { button in
                                    Button(button.displayName) { capture.select(button) }
                                }
                            }
                        }
                        Text("编辑期间暂停手柄控制，避免触发已有操作。摇杆方向请在“摇杆设置”中配置。")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if capture.selectedButton == .homeButton {
                            Text("Xbox 键可能被系统保留，无法保证触发自定义操作。")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.warning)
                        }
                        if capture.selectedButton?.isStickAxis == true {
                            Text("此旧映射使用摇杆方向，请重新选择实体按键；摇杆行为在“摇杆设置”中调整。")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.warning)
                        }
                        if !conflicts.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("此按键在当前配置中已有绑定", systemImage: "exclamationmark.triangle")
                                    .font(.system(size: 13, weight: .medium))
                                ForEach(conflicts) { conflict in
                                    Text("\(conflict.button.displayName) → \(conflict.action.displayName)\(conflict.enabled ? "" : "（已禁用）")")
                                        .font(.system(size: 12))
                                }
                                Text("可以重新选键，或在保存时确认替换。其他配置不受影响。")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(AppTheme.warning)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.warning.opacity(0.08))
                            .cornerRadius(8)
                        }
                    }

                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("映射动作")
                            .font(.system(size: 13, weight: .medium))
                        Picker("映射动作", selection: $actionType) {
                            ForEach(ActionType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    switch actionType {
                    case .keyboard: KeyboardShortcutEditor(keyCode: $keyCode, modifiers: $modifiers)
                    case .mouse: MouseActionEditor(action: $mouseAction)
                    case .script: CustomScriptEditor(script: $customScript)
                    }
                    if saveRejected {
                        Text("绑定发生冲突，未保存。请重新选键或确认替换。")
                            .foregroundStyle(AppTheme.warning)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button(conflicts.isEmpty ? "保存" : "替换并保存…") { saveMapping() }
                    .keyboardShortcut(.return)
                    .disabled(capture.isWaiting || capture.selectedButton == nil || capture.selectedButton?.isStickAxis == true)
            }
        }
        .padding(24)
        .frame(width: 540, height: 620)
        .foregroundStyle(AppTheme.text)
        .background(AppTheme.surface)
        .onAppear {
            gamepadManager.isCapturingInput = true
            if mapping == nil { startWaitingForInput() }
        }
        .onDisappear { gamepadManager.isCapturingInput = false }
        .onReceive(gamepadManager.inputEvents) { capture.receive($0) }
        .alert("替换已有绑定？", isPresented: $showingReplaceAlert) {
            Button("返回选键", role: .cancel) { startWaitingForInput() }
            Button("替换并保存", role: .destructive) { saveMapping(replace: true) }
        } message: {
            Text("将替换当前配置中 \(capture.selectedButton?.displayName ?? "") 的 \(conflicts.count) 条已有绑定。同一按键只执行新操作。")
        }
    }

    private func startWaitingForInput() {
        capture.begin(heldButtons: Set(gamepadManager.buttonStates.filter { $0.value > 0.5 }.map(\.key)))
        saveRejected = false
    }

    private func saveMapping(replace: Bool = false) {
        guard !capture.isWaiting, let button = capture.selectedButton, !button.isStickAxis else { return }
        if !conflicts.isEmpty && !replace {
            showingReplaceAlert = true
            return
        }
        let action: MappingAction
        switch actionType {
        case .keyboard: action = .keyboardShortcut(KeyboardShortcut(keyCode: keyCode, modifiers: modifiers))
        case .mouse: action = .mouseAction(mouseAction)
        case .script: action = .customScript(customScript)
        }
        let newMapping = ButtonMapping(id: mapping?.id ?? UUID(), button: button,
                                       action: action, enabled: mapping?.enabled ?? true)
        if onSave(newMapping, replace) { dismiss() } else { saveRejected = true }
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
                    .foregroundColor(AppTheme.muted)
                
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
        .background(AppTheme.inset)
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
                .foregroundColor(isActive ? AppTheme.onAccent : AppTheme.secondary)
                .frame(width: 44, height: 44)
                .background(isActive ? AppTheme.accent : AppTheme.selection)
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
                            .foregroundColor(AppTheme.accent)
                        Text(mouseAction.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.text)
                        Spacer()
                    }
                    .padding(12)
                    .background(action == mouseAction ? AppTheme.selection : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(AppTheme.inset)
        .cornerRadius(8)
    }
}

struct CustomScriptEditor: View {
    @Binding var script: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shell 命令")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.muted)
            
            TextEditor(text: $script)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(AppTheme.text)
                .frame(height: 100)
                .padding(8)
                .background(AppTheme.background)
                .cornerRadius(6)
        }
        .padding()
        .background(AppTheme.inset)
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
