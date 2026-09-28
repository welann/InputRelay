import SwiftUI
import AppKit

@main
struct InputRelayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?

    private let gamepadManager = GamepadManager()
    private let mouseSimulator = MouseSimulator()
    private let keyboardSimulator = KeyboardSimulator()
    private let permissionManager = PermissionManager()

    private lazy var configEngine = ConfigurationEngine(
        gamepadManager: gamepadManager,
        mouseSimulator: mouseSimulator,
        keyboardSimulator: keyboardSimulator
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 不显示 Dock 图标，仅作为菜单栏应用运行
        NSApp.setActivationPolicy(.accessory)

        // 检查权限
        if !permissionManager.allPermissionsGranted {
            showPermissionAlert()
        }

        // 配置引擎需要先初始化，以加载并激活默认配置
        _ = configEngine
        gamepadManager.start()

        let manager = MenuBarManager(
            configEngine: configEngine,
            gamepadManager: gamepadManager,
            permissionManager: permissionManager
        )
        manager.setup()
        menuBarManager = manager
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "InputRelay 需要辅助功能权限才能模拟键盘和鼠标操作。请在系统设置中授予权限。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            permissionManager.openSystemPreferences()
        }
    }
}
