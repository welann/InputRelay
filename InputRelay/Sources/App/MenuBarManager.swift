import AppKit
import SwiftUI

/// 菜单栏管理器 - 负责状态栏图标、下拉菜单和主窗口生命周期
@MainActor
final class MenuBarManager: NSObject {
    private let configEngine: ConfigurationEngine
    private let gamepadManager: GamepadManager
    private let permissionManager: PermissionManager

    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?

    init(
        configEngine: ConfigurationEngine,
        gamepadManager: GamepadManager,
        permissionManager: PermissionManager
    ) {
        self.configEngine = configEngine
        self.gamepadManager = gamepadManager
        self.permissionManager = permissionManager
        super.init()
    }

    // MARK: - Setup

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = icon(for: .idle)
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        statusItem = item

        updateIcon()

        // 手柄连接状态变化时刷新图标
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(gamepadConnectionChanged),
            name: Notification.Name("GamepadConnectionChanged"),
            object: nil
        )
    }

    // MARK: - Icon

    private enum IconState {
        case idle
        case connected
    }

    private func icon(for state: IconState) -> NSImage? {
        let name = state == .connected ? "gamecontroller.fill" : "gamecontroller"
        return NSImage(systemSymbolName: name, accessibilityDescription: "InputRelay")
    }

    @objc private func gamepadConnectionChanged() {
        updateIcon()
    }

    private func updateIcon() {
        statusItem?.button?.image = icon(for: gamepadManager.isConnected ? .connected : .idle)
    }

    // MARK: - Menu

    @objc private func statusItemClicked() {
        guard let statusItem else { return }

        let menu = NSMenu()

        // 当前配置
        if let activeProfile = configEngine.activeProfile {
            let item = NSMenuItem(title: "当前配置: \(activeProfile.name)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }

        // 快速切换配置
        let recentProfiles = configEngine.profiles.prefix(3)
        if !recentProfiles.isEmpty {
            for profile in recentProfiles {
                let item = NSMenuItem(title: profile.name, action: #selector(switchProfile(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = profile.id
                item.state = profile.id == configEngine.activeProfile?.id ? .on : .off
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }

        // 手柄状态
        let statusText = gamepadManager.isConnected ? "✓ 手柄已连接" : "✗ 手柄未连接"
        let connectionItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu.addItem(connectionItem)
        menu.addItem(.separator())

        // 暂停/恢复映射
        let toggleTitle = configEngine.isEnabled ? "暂停映射" : "恢复映射"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleMapping), keyEquivalent: "p")
        toggleItem.target = self
        menu.addItem(toggleItem)

        // 打开设置
        let settingsItem = NSMenuItem(title: "打开设置...", action: #selector(openSettings), keyEquivalent: "s")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // 用 popUpMenu 显示，避免污染 statusItem.menu 的持久状态
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func switchProfile(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let profile = configEngine.profiles.first(where: { $0.id == id }) else {
            return
        }
        configEngine.activateProfile(profile)
    }

    @objc private func toggleMapping() {
        configEngine.isEnabled.toggle()
        updateIcon()
    }

    @objc func openSettings() {
        if mainWindow == nil {
            createMainWindow()
        }

        permissionManager.checkPermissions()
        mainWindow?.deminiaturize(nil)
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Main Window

    private func createMainWindow() {
        let contentView = MainWindowView(
            configEngine: configEngine,
            permissionManager: permissionManager,
            gamepadManager: gamepadManager
        )
        .preferredColorScheme(.light)
        .tint(AppTheme.accent)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "InputRelay"
        window.appearance = NSAppearance(named: .aqua)
        window.contentMinSize = NSSize(width: 900, height: 600)
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false

        mainWindow = window
    }
}
