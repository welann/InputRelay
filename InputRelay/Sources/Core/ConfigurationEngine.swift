import Foundation
import AppKit
import Carbon

/// 配置引擎 - 管理配置文件的加载、切换和应用
@MainActor
class ConfigurationEngine: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    /// 映射总开关，由菜单栏的"暂停/恢复映射"控制
    @Published var isEnabled = true
    
    private let gamepadManager: GamepadManager
    private let mouseSimulator: MouseSimulator
    private let keyboardSimulator: KeyboardSimulator
    private var workspaceObserver: NSObjectProtocol?
    // 观察者清理放在独立盒子里：deinit 是 nonisolated 的，不能访问 actor 隔离属性
    private let observerBox = ObserverBox()
    
    // 配置文件存储路径
    private let profilesDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("InputRelay/Profiles")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    init(gamepadManager: GamepadManager, mouseSimulator: MouseSimulator, keyboardSimulator: KeyboardSimulator) {
        self.gamepadManager = gamepadManager
        self.mouseSimulator = mouseSimulator
        self.keyboardSimulator = keyboardSimulator
        
        loadProfiles()
        setupGamepadHandler()
        setupAppObserver()
        
        // 激活默认配置
        if let global = profiles.first(where: { $0.name == "全局配置" }) {
            activateProfile(global)
        }
    }
    
    deinit {
        // 由 ObserverBox 负责注销
    }
    
    // MARK: - Profile Management
    
    func loadProfiles() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: profilesDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            
            profiles = jsonFiles.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let profile = try? JSONDecoder().decode(Profile.self, from: data) else {
                    return nil
                }
                return profile
            }
            
            // 如果没有配置文件，创建默认配置
            if profiles.isEmpty {
                createDefaultProfiles()
            }
            
        } catch {
            print("Failed to load profiles: \(error)")
            createDefaultProfiles()
        }
    }
    
    func saveProfile(_ profile: Profile) {
        let url = profilesDirectory.appendingPathComponent("\(profile.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: url)
            
            // 更新内存中的配置
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
            } else {
                profiles.append(profile)
            }
            if activeProfile?.id == profile.id {
                activeProfile = profile
            }
            
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    func deleteProfile(_ profile: Profile) {
        let url = profilesDirectory.appendingPathComponent("\(profile.id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
        
        profiles.removeAll { $0.id == profile.id }
        
        // 如果删除的是当前激活的配置，切换到全局配置
        if activeProfile?.id == profile.id {
            if let global = profiles.first(where: { $0.name == "全局配置" }) {
                activateProfile(global)
            }
        }
    }
    
    func activateProfile(_ profile: Profile) {
        // 取消之前配置的激活状态
        if let oldProfile = activeProfile {
            var updated = oldProfile
            updated.isActive = false
            saveProfile(updated)
        }
        
        // 激活新配置
        var newProfile = profile
        newProfile.isActive = true
        saveProfile(newProfile)
        
        activeProfile = newProfile
        print("Activated profile: \(newProfile.name)")
    }
    
    private func createDefaultProfiles() {
        // 全局配置
        let globalProfile = Profile(
            name: "全局配置",
            mappings: [
                ButtonMapping(button: .buttonA, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_Return, modifiers: []))),
                ButtonMapping(button: .buttonB, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_Escape, modifiers: []))),
                ButtonMapping(button: .leftShoulder, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_LeftBracket, modifiers: .command))),
                ButtonMapping(button: .rightShoulder, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_RightBracket, modifiers: .command))),
                ButtonMapping(button: .leftTrigger, action: .mouseAction(.leftClick)),
                ButtonMapping(button: .rightTrigger, action: .mouseAction(.rightClick)),
                ButtonMapping(button: .dpadUp, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_UpArrow, modifiers: []))),
                ButtonMapping(button: .dpadDown, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_DownArrow, modifiers: []))),
                ButtonMapping(button: .dpadLeft, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_LeftArrow, modifiers: []))),
                ButtonMapping(button: .dpadRight, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_RightArrow, modifiers: [])))
            ],
            appRules: [],
            stickSettings: StickSettings()
        )
        
        // 浏览器配置
        let browserProfile = Profile(
            name: "浏览器专用",
            mappings: [
                ButtonMapping(button: .buttonA, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_Return, modifiers: []))),
                ButtonMapping(button: .buttonB, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_W, modifiers: .command))),
                ButtonMapping(button: .buttonX, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_T, modifiers: .command))),
                ButtonMapping(button: .buttonY, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_R, modifiers: .command))),
                ButtonMapping(button: .leftShoulder, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_LeftBracket, modifiers: .command))),
                ButtonMapping(button: .rightShoulder, action: .keyboardShortcut(KeyboardShortcut(keyCode: kVK_ANSI_RightBracket, modifiers: .command))),
                ButtonMapping(button: .leftTrigger, action: .mouseAction(.leftClick)),
                ButtonMapping(button: .rightTrigger, action: .mouseAction(.rightClick))
            ],
            appRules: [
                .appName("Safari"),
                .appName("Chrome"),
                .appName("Firefox"),
                .bundleID("com.apple.Safari")
            ],
            stickSettings: StickSettings(rightStickMode: .scroll)
        )
        
        saveProfile(globalProfile)
        saveProfile(browserProfile)
    }
    
    // MARK: - Event Handling
    
    private func setupGamepadHandler() {
        gamepadManager.setEventHandler { [weak self] event in
            self?.handleGamepadEvent(event)
        }
        gamepadManager.setStickHandler { [weak self] elapsed in
            guard let self else { return }
            guard self.isEnabled, let profile = self.activeProfile else {
                self.mouseSimulator.scroll(deltaY: 0)
                return
            }
            let leftScroll = self.handleStickMovement(isLeftStick: true, settings: profile.stickSettings, elapsed: elapsed)
            let rightScroll = self.handleStickMovement(isLeftStick: false, settings: profile.stickSettings, elapsed: elapsed)
            self.mouseSimulator.scroll(deltaY: leftScroll + rightScroll)
        }
    }
    
    private func handleGamepadEvent(_ event: GamepadEvent) {
        guard isEnabled else { return }
        guard let profile = activeProfile else { return }
        
        // 连续摇杆动作由每帧回调处理；方向事件只用于识别和显示。
        guard !event.button.isStickAxis else { return }
        
        // 查找对应的映射
        guard let mapping = profile.mappings.first(where: { $0.button == event.button && $0.enabled }),
              event.isPressed else {
            return
        }
        
        // 执行映射动作
        executeAction(mapping.action)
    }
    
    private func handleStickMovement(isLeftStick: Bool, settings: StickSettings, elapsed: TimeInterval) -> Double {
        let mode = isLeftStick ? settings.leftStickMode : settings.rightStickMode
        
        guard mode != .disabled else { return 0 }
        
        // 摇杆是二维输入，必须同时取两个轴，否则斜向移动会退化成分轴抖动
        let axes = gamepadManager.getStickAxes(isLeft: isLeftStick)
        let (x, y) = (axes.x, axes.y)
        
        if mode == .mouse {
            mouseSimulator.handleStickInput(
                x: x,
                y: -y,
                sensitivity: settings.sensitivity,
                curve: settings.accelerationCurve,
                deadzone: settings.deadzone,
                elapsed: elapsed
            )
        } else if mode == .scroll {
            // 从死区边缘平滑起步，保留小数滚动量；GameController 的 Y 轴向上为正。
            let amount = CurveCalculator.applyDeadzone(y, deadzone: settings.deadzone)
            return Double(amount * settings.sensitivity) * 600 * elapsed
        }
        return 0
    }
    
    private func executeAction(_ action: MappingAction) {
        switch action {
        case .keyboardShortcut(let shortcut):
            keyboardSimulator.sendShortcut(shortcut)
            
        case .mouseAction(let mouseAction):
            switch mouseAction {
            case .leftClick:
                mouseSimulator.click(.left)
            case .rightClick:
                mouseSimulator.click(.right)
            case .middleClick:
                mouseSimulator.click(.center)
            case .scrollUp:
                mouseSimulator.scroll(deltaY: 10)
            case .scrollDown:
                mouseSimulator.scroll(deltaY: -10)
            }
            
        case .customScript(let script):
            executeCustomScript(script)
            
        case .mouseMovement:
            break  // 由 handleStickMovement 处理
        }
    }
    
    private func executeCustomScript(_ script: String) {
        // 执行 AppleScript 或 Shell 命令
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script]
        
        do {
            try process.run()
        } catch {
            print("Failed to execute script: \(error)")
        }
    }
    
// MARK: - App Observer
    
    private func setupAppObserver() {
        let observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // 只取出需要的基本类型，避免跨隔离域传递 Notification / NSRunningApplication
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier,
                  let appName = app.localizedName else {
                return
            }

            Task { @MainActor [weak self] in
                self?.handleAppSwitch(bundleID: bundleID, appName: appName)
            }
        }

        workspaceObserver = observer
        observerBox.observer = observer
    }
    
    private func handleAppSwitch(bundleID: String, appName: String) {
        if let matchedProfile = Profile.preferredProfile(in: profiles, bundleID: bundleID, appName: appName) {
            if activeProfile?.id != matchedProfile.id {
                activateProfile(matchedProfile)
                print("Switched to profile: \(matchedProfile.name) for app: \(appName)")
            }
        } else if var previous = activeProfile {
            previous.isActive = false
            saveProfile(previous)
            activeProfile = nil
        }
    }
}

/// 持有通知观察者并在析构时自动注销
///
/// `deinit` 无法访问 actor 隔离的属性，因此把注销逻辑移到一个独立对象中，
/// 由它的生命周期保证观察者一定被移除。
private final class ObserverBox: @unchecked Sendable {
    var observer: NSObjectProtocol?

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
