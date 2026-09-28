import AppKit
import SwiftUI

struct MainWindowView: View {
    @ObservedObject var configEngine: ConfigurationEngine
    @ObservedObject var permissionManager: PermissionManager
    @ObservedObject var gamepadManager: GamepadManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标签栏
            HStack(spacing: 20) {
                HStack(spacing: 7) {
                    Image(nsImage: AppMark.image(size: 19))
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 19, height: 19)
                    Text("InputRelay")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                }
                .padding(.trailing, 16)
                TabButton(title: "配置管理", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "手柄状态", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "高级设置", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                Spacer()
            }
            .padding()
            .background(AppTheme.surface)
            
            Divider()
                .background(AppTheme.border)

            if !permissionManager.hasAccessibilityPermission {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundStyle(AppTheme.warning)
                    Text("需要辅助功能权限才能控制键盘和鼠标")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Button("查看权限") { selectedTab = 2 }
                    Button("打开系统设置") { permissionManager.requestAccessibilityPermission() }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppTheme.warning.opacity(0.08))
            }
            
            // 内容区域
            Group {
                switch selectedTab {
                case 0:
                    ProfileManagementView(
                        configEngine: configEngine,
                        gamepadManager: gamepadManager
                    )
                case 1:
                    GamepadStatusView(gamepadManager: gamepadManager)
                case 2:
                    AdvancedSettingsView(permissionManager: permissionManager)
                default:
                    EmptyView()
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(AppTheme.background)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppTheme.accent : AppTheme.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    AppTheme.selection :
                    Color.clear
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
