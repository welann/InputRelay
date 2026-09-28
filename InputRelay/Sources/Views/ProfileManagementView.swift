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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#E5E7EB"))
                    .padding(.horizontal)
                
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
                    .foregroundColor(Color(hex: "#38BDF8"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#0F131C"))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(width: 280)
            .background(Color(hex: "#0A0D12"))
            
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
            } else {
                VStack {
                    Spacer()
                    Text("选择一个配置文件以编辑")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6B7280"))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#05070C"))
            }
        }
        .sheet(isPresented: $showingNewProfileSheet) {
            NewProfileSheet { name in
                let newProfile = Profile(name: name)
                configEngine.saveProfile(newProfile)
                selectedProfile = newProfile
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
                    .fill(Color(hex: "#38BDF8"))
                    .frame(width: 4)
                    .cornerRadius(2)
            } else {
                Color.clear.frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#E5E7EB"))
                
                Text("\(profile.mappings.count) 个映射")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                
                if !profile.appRules.isEmpty {
                    Text(profile.appRules.map { rule in
                        switch rule {
                        case .appName(let name): return name
                        case .bundleID(let id): return id.components(separatedBy: ".").last ?? id
                        }
                    }.joined(separator: ", "))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "#38BDF8"))
            }
        }
        .padding(12)
        .background(isSelected ? Color(hex: "#161D2B") : Color(hex: "#0F131C"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(hex: "#38BDF8").opacity(0.3) : Color.clear, lineWidth: 1)
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
                .foregroundColor(Color(hex: "#E5E7EB"))
            
            TextField("配置名称", text: $profileName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color(hex: "#0F131C"))
                .cornerRadius(8)
                .foregroundColor(Color(hex: "#E5E7EB"))
            
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
        .background(Color(hex: "#0A0D12"))
    }
}
