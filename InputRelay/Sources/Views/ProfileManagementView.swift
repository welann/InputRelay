import SwiftUI

struct ProfileManagementView: View {
    @ObservedObject var configEngine: ConfigurationEngine
    @ObservedObject var gamepadManager: GamepadManager
    
    @State private var selectedProfile: Profile?
    @State private var showingNewProfileSheet = false
    @State private var editingMapping: ButtonMapping?
    
    var body: some View {
        HSplitView {
            // 左侧：配置列表
            VStack(alignment: .leading, spacing: 12) {
                Text("配置文件")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(configEngine.profiles) { profile in
                            ProfileCard(
                                profile: profile,
                                isSelected: selectedProfile?.id == profile.id,
                                isActive: configEngine.activeProfile?.id == profile.id
                            ) {
                                selectedProfile = profile
                            } onActivate: {
                                configEngine.activateProfile(profile)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: { showingNewProfileSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("新建配置")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.inset)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(width: 280)
            .background(AppTheme.surface)
            
            // 右侧：映射编辑
            if let profile = selectedProfile {
                ProfileDetailView(
                    profile: profile,
                    gamepadManager: gamepadManager,
                    onUpdate: { updated in
                        configEngine.saveProfile(updated)
                        selectedProfile = updated
                    },
                    onDelete: {
                        configEngine.deleteProfile(profile)
                        selectedProfile = nil
                    }
                )
                .id(profile.id)
            } else {
                VStack {
                    Spacer()
                    Text("选择一个配置文件以编辑")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.muted)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
            }
        }
        .sheet(isPresented: $showingNewProfileSheet) {
            NewProfileSheet { name in
                let newProfile = Profile(name: name)
                configEngine.saveProfile(newProfile)
                selectedProfile = newProfile
            }
        }
        .onAppear {
            if selectedProfile == nil {
                selectedProfile = configEngine.activeProfile ?? configEngine.profiles.first
            }
        }
    }
}

struct ProfileCard: View {
    let profile: Profile
    let isSelected: Bool
    let isActive: Bool
    let onSelect: () -> Void
    let onActivate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧指示器
            if isActive {
                Rectangle()
                    .fill(AppTheme.accent)
                    .frame(width: 4)
                    .cornerRadius(2)
            } else {
                Color.clear.frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                
                Text("\(profile.mappings.count) 个映射")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.muted)
                
                if !profile.appRules.isEmpty {
                    Text(profile.appRules.map { rule in
                        switch rule {
                        case .appName(let name): return name
                        case .bundleID(let id): return id.components(separatedBy: ".").last ?? id
                        }
                    }.joined(separator: ", "))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.secondary)
                    .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.accent)
            }
        }
        .padding(12)
        .background(isSelected ? AppTheme.selection : AppTheme.inset)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button(isActive ? "当前配置" : "激活此配置") {
                if !isActive {
                    onActivate()
                }
            }
        }
    }
}

struct NewProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var profileName = ""
    let onCreate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新建配置")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.text)
            
            TextField("配置名称", text: $profileName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(AppTheme.inset)
                .cornerRadius(8)
                .foregroundColor(AppTheme.text)
            
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("创建") {
                    guard !profileName.isEmpty else { return }
                    onCreate(profileName)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(profileName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(AppTheme.surface)
    }
}
