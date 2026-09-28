import SwiftUI

struct ProfileDetailView: View {
    var profile: Profile
    @ObservedObject var gamepadManager: GamepadManager
    let onUpdate: (Profile) -> Void
    let onDelete: () -> Void
    
    @State private var editingProfile: Profile
    @State private var showingMappingEditor = false
    @State private var editingMapping: ButtonMapping?
    @State private var showingDeleteAlert = false
    
    init(profile: Profile, gamepadManager: GamepadManager, onUpdate: @escaping (Profile) -> Void, onDelete: @escaping () -> Void) {
        self.profile = profile
        self.gamepadManager = gamepadManager
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editingProfile = State(initialValue: profile)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 标题栏
                HStack {
                    TextField("配置名称", text: $editingProfile.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    Spacer()
                    
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color(hex: "#EF4444"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 应用匹配规则
                VStack(alignment: .leading, spacing: 12) {
                    Text("应用匹配规则")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(editingProfile.appRules.indices, id: \.self) { index in
                            HStack {
                                Text(editingProfile.appRules[index].displayString)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#E5E7EB"))
                                
                                Spacer()
                                
                                Button(action: {
                                    editingProfile.appRules.remove(at: index)
                                    saveChanges()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(hex: "#6B7280"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(10)
                            .background(Color(hex: "#0F131C"))
                            .cornerRadius(6)
                        }
                        
                        Button(action: addAppRule) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("添加规则")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#38BDF8"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(hex: "#0A0D12"))
                .cornerRadius(12)
                
                // 摇杆设置
                StickSettingsSection(settings: $editingProfile.stickSettings, onChange: saveChanges)
                
                // 按键映射列表
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("按键映射")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        
                        Spacer()
                        
                        Button(action: { showingMappingEditor = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("添加映射")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#38BDF8"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if editingProfile.mappings.isEmpty {
                        Text("暂无映射，点击上方按钮添加")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(editingProfile.mappings) { mapping in
                                MappingRow(mapping: mapping) {
                                    editingMapping = mapping
                                    showingMappingEditor = true
                                } onToggle: {
                                    toggleMapping(mapping)
                                } onDelete: {
                                    deleteMapping(mapping)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(hex: "#0A0D12"))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(hex: "#05070C"))
        .sheet(isPresented: $showingMappingEditor) {
            MappingEditorSheet(
                mapping: editingMapping,
                gamepadManager: gamepadManager,
                onSave: { newMapping in
                    if let index = editingProfile.mappings.firstIndex(where: { $0.id == newMapping.id }) {
                        editingProfile.mappings[index] = newMapping
                    } else {
                        editingProfile.mappings.append(newMapping)
                    }
                    saveChanges()
                    editingMapping = nil
                }
            )
        }
        .alert("删除配置", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除配置 \"\(profile.name)\" 吗？此操作不可撤销。")
        }
    }
    
    private func saveChanges() {
        onUpdate(editingProfile)
    }
    
    private func addAppRule() {
        // 简单实现：添加当前前台应用
        if let app = NSWorkspace.shared.frontmostApplication,
           let name = app.localizedName {
            editingProfile.appRules.append(.appName(name))
            saveChanges()
        }
    }
    
    private func toggleMapping(_ mapping: ButtonMapping) {
        if let index = editingProfile.mappings.firstIndex(where: { $0.id == mapping.id }) {
            editingProfile.mappings[index].enabled.toggle()
            saveChanges()
        }
    }
    
    private func deleteMapping(_ mapping: ButtonMapping) {
        editingProfile.mappings.removeAll { $0.id == mapping.id }
        saveChanges()
    }
}

struct MappingRow: View {
    let mapping: ButtonMapping
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 按键名称
            Text(mapping.button.displayName)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#38BDF8"))
                .frame(width: 60, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#6B7280"))
            
            // 映射动作
            Text(actionDescription)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#E5E7EB"))
            
            Spacer()
            
            // 启用/禁用
            Toggle("", isOn: Binding(
                get: { mapping.enabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#38BDF8")))
            .labelsHidden()
            
            // 编辑
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            .buttonStyle(PlainButtonStyle())
            
            // 删除
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(Color(hex: "#EF4444"))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color(hex: "#0F131C"))
        .cornerRadius(8)
        .opacity(mapping.enabled ? 1.0 : 0.5)
    }
    
    private var actionDescription: String {
        switch mapping.action {
        case .keyboardShortcut(let shortcut):
            return shortcut.displayString
        case .mouseAction(let action):
            return action.rawValue
        case .customScript(let script):
            return "脚本: \(script.prefix(30))..."
        case .mouseMovement(let axis, _):
            return "鼠标\(axis == .horizontal ? "水平" : "垂直")移动"
        }
    }
}

struct StickSettingsSection: View {
    @Binding var settings: StickSettings
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("摇杆设置")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            VStack(spacing: 16) {
                // 左摇杆模式
                HStack {
                    Text("左摇杆")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                        .frame(width: 80, alignment: .leading)
                    
                    Picker("", selection: $settings.leftStickMode) {
                        ForEach([StickSettings.StickMode.mouse, .scroll, .disabled], id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settings.leftStickMode) { onChange() }
                }
                
                // 右摇杆模式
                HStack {
                    Text("右摇杆")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                        .frame(width: 80, alignment: .leading)
                    
                    Picker("", selection: $settings.rightStickMode) {
                        ForEach([StickSettings.StickMode.mouse, .scroll, .disabled], id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settings.rightStickMode) { onChange() }
                }
                
                // 灵敏度
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("灵敏度")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#E5E7EB"))
                        Spacer()
                        Text(String(format: "%.1f", settings.sensitivity))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    Slider(value: $settings.sensitivity, in: 0.1...5.0, step: 0.1)
                        .onChange(of: settings.sensitivity) { onChange() }
                }
                
                // 死区
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("死区")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#E5E7EB"))
                        Spacer()
                        Text(String(format: "%.2f", settings.deadzone))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    Slider(value: $settings.deadzone, in: 0.0...0.5, step: 0.01)
                        .onChange(of: settings.deadzone) { onChange() }
                }
                
                // 加速曲线
                HStack {
                    Text("加速曲线")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                        .frame(width: 80, alignment: .leading)
                    
                    Picker("", selection: $settings.accelerationCurve) {
                        ForEach(StickSettings.AccelerationCurve.allCases, id: \.self) { curve in
                            Text(curve.rawValue).tag(curve)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settings.accelerationCurve) { onChange() }
                }
            }
        }
        .padding()
        .background(Color(hex: "#0A0D12"))
        .cornerRadius(12)
    }
}
