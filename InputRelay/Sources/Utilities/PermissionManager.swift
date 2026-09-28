import Foundation
import AppKit
import ApplicationServices

/// 权限管理器 - 检查和请求系统权限
@MainActor
class PermissionManager: ObservableObject {
    @Published var hasAccessibilityPermission = false
    @Published var hasInputMonitoringPermission = false
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasInputMonitoringPermission = checkInputMonitoringPermission()
    }
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func checkInputMonitoringPermission() -> Bool {
        // 输入监控权限无法直接查询，只能通过事件监听探测；
        // 此处以辅助功能权限作为代理指标。
        return hasAccessibilityPermission
    }
    
    func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        
        // 延迟检查，给用户时间授权
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkPermissions()
        }
    }
    
    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    var allPermissionsGranted: Bool {
        hasAccessibilityPermission
    }
    
    var missingPermissions: [String] {
        var missing: [String] = []
        if !hasAccessibilityPermission {
            missing.append("辅助功能")
        }
        return missing
    }
}
