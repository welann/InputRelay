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
                        .foregroundColor(AppTheme.text)
                    
                    PermissionCard(
                        title: "辅助功能",
                        description: "允许 InputRelay 模拟键盘和鼠标操作",
                        isGranted: permissionManager.hasAccessibilityPermission,
                        onRequest: {
                            permissionManager.requestAccessibilityPermission()
                        }
                    )

                    HStack {
                        Button("重新检测") { permissionManager.checkPermissions() }
                        Button("定位当前应用") { permissionManager.revealRunningApplication() }
                    }

                    Text("当前运行：\(permissionManager.runningApplicationPath)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(AppTheme.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !permissionManager.allPermissionsGranted {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.warning)
                            Text("授权后会自动刷新。如果系统设置已开启但这里仍未授权，请移除旧条目，再添加上方路径的 InputRelay；更新本地构建后可能需要重新授权并重启应用。")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(AppTheme.inset)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(12)
                
                // 关于
                VStack(alignment: .leading, spacing: 16) {
                    Text("关于")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "版本", value: "1.0.0")
                        InfoRow(label: "构建", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "开发版本")
                        InfoRow(label: "按键布局", value: "Xbox · A / B / X / Y · LB / RB · LT / RT")
                        InfoRow(label: "支持的设备", value: "macOS 可识别的扩展游戏手柄")
                    }
                    
                    Divider()
                        .background(AppTheme.border)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("配置文件位置")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.secondary)
                        
                        Text("~/Library/Application Support/InputRelay/Profiles")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(AppTheme.muted)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.inset)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(12)
                
                // 使用提示
                VStack(alignment: .leading, spacing: 16) {
                    Text("使用提示")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    
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
                .background(AppTheme.surface)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
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
                .foregroundColor(isGranted ? AppTheme.success : AppTheme.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondary)
                
                if !isGranted {
                    Button(action: onRequest) {
                        Text("授予权限")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            Text(isGranted ? "已授权" : "未授权")
                .font(.system(size: 12))
                .foregroundColor(isGranted ? AppTheme.success : AppTheme.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isGranted ?
                    AppTheme.success.opacity(0.15) :
                    AppTheme.warning.opacity(0.15)
                )
                .cornerRadius(999)
        }
        .padding()
        .background(AppTheme.inset)
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
                .foregroundColor(AppTheme.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.text)
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
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
