import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 权限状态
                VStack(alignment: .leading, spacing: 16) {
                    Text("系统权限")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                    
                    PermissionCard(
                        title: "辅助功能",
                        description: "允许 InputRelay 模拟键盘和鼠标操作",
                        isGranted: permissionManager.hasAccessibilityPermission,
                        onRequest: {
                            permissionManager.requestAccessibilityPermission()
                        }
                    )
                    
                    if !permissionManager.allPermissionsGranted {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("缺少必要权限，应用功能将受限")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        .padding()
                        .background(Color(hex: "#0F131C"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(hex: "#0A0D12"))
                .cornerRadius(12)
                
                // 关于
                VStack(alignment: .leading, spacing: 16) {
                    Text("关于")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "版本", value: "1.0.0")
                        InfoRow(label: "构建", value: "2024.001")
                        InfoRow(label: "支持的设备", value: "冰原狼 4 代及兼容手柄")
                    }
                    
                    Divider()
                        .background(Color(hex: "#1E2636"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("配置文件位置")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        
                        Text("~/Library/Application Support/InputRelay/Profiles")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#0F131C"))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(hex: "#0A0D12"))
                .cornerRadius(12)
                
                // 使用提示
                VStack(alignment: .leading, spacing: 16) {
                    Text("使用提示")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#E5E7EB"))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(
                            icon: "1.circle.fill",
                            text: "在配置管理中创建针对不同应用的专用配置"
                        )
                        TipRow(
                            icon: "2.circle.fill",
                            text: "使用左摇杆控制鼠标，右摇杆可设置为滚轮"
                        )
                        TipRow(
                            icon: "3.circle.fill",
                            text: "点击映射列表中的按键可以快速编辑"
                        )
                        TipRow(
                            icon: "4.circle.fill",
                            text: "配置会根据前台应用自动切换"
                        )
                    }
                }
                .padding()
                .background(Color(hex: "#0A0D12"))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#05070C"))
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isGranted ? "checkmark.shield.fill" : "shield.slash.fill")
                .font(.system(size: 32))
                .foregroundColor(isGranted ? Color(hex: "#6EE7B7") : Color(hex: "#F59E0B"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#E5E7EB"))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                if !isGranted {
                    Button(action: onRequest) {
                        Text("授予权限")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#38BDF8"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            Text(isGranted ? "已授权" : "未授权")
                .font(.system(size: 12))
                .foregroundColor(isGranted ? Color(hex: "#6EE7B7") : Color(hex: "#F59E0B"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isGranted ?
                    Color(hex: "#6EE7B7").opacity(0.15) :
                    Color(hex: "#F59E0B").opacity(0.15)
                )
                .cornerRadius(999)
        }
        .padding()
        .background(Color(hex: "#0F131C"))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#9CA3AF"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#E5E7EB"))
        }
        .padding(.vertical, 4)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#38BDF8"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#E5E7EB"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
