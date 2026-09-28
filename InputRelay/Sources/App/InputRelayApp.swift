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
        NSApp.setActivationPolicy(.regular)
        permissionManager.startMonitoring()

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
        manager.openSettings()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBarManager?.openSettings()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
