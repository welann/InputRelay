import Foundation
import AppKit
import ApplicationServices
import Combine

@MainActor
final class PermissionManager: ObservableObject {
    @Published private(set) var hasAccessibilityPermission = false

    private let accessibilityCheck: () -> Bool
    private var observations = Set<AnyCancellable>()

    init(accessibilityCheck: @escaping () -> Bool = { AXIsProcessTrusted() }) {
        self.accessibilityCheck = accessibilityCheck
        checkPermissions()
    }

    func startMonitoring() {
        guard observations.isEmpty else { return }
        checkPermissions()

        // 授权发生在系统设置中，应用未重新激活时也需要刷新状态。
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.checkPermissions() }
            .store(in: &observations)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.checkPermissions() }
            .store(in: &observations)
    }

    func checkPermissions() {
        let granted = accessibilityCheck()
        if hasAccessibilityPermission != granted {
            hasAccessibilityPermission = granted
        }
    }

    func requestAccessibilityPermission() {
        // 使用系统定义的键名，避开 SDK 将常量导入为可变全局量的并发限制。
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        checkPermissions()
        if !hasAccessibilityPermission {
            openSystemPreferences()
        }
    }

    func openSystemPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func revealRunningApplication() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    var runningApplicationPath: String { Bundle.main.bundleURL.path }
    var allPermissionsGranted: Bool { hasAccessibilityPermission }
}
