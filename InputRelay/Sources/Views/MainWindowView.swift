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
            .background(Color(hex: "#0A0D12"))
            
            Divider()
                .background(Color(hex: "#1E2636"))
            
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
        .background(Color(hex: "#05070C"))
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
                .foregroundColor(isSelected ? Color(hex: "#38BDF8") : Color(hex: "#9CA3AF"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    Color(hex: "#1E3A5F").opacity(0.3) :
                    Color.clear
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
