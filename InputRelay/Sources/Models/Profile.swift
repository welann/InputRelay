import Foundation

/// 配置文件 - 包含一组按键映射和应用匹配规则
struct Profile: Codable, Identifiable {
    let id: UUID
    var name: String
    var mappings: [ButtonMapping]
    var appRules: [AppRule]
    var stickSettings: StickSettings
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        mappings: [ButtonMapping] = [],
        appRules: [AppRule] = [],
        stickSettings: StickSettings = StickSettings(),
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mappings = mappings
        self.appRules = appRules
        self.stickSettings = stickSettings
        self.isActive = isActive
    }
    
    /// 编辑当前绑定时排除自身。
    func mappingConflicts(for button: GamepadButton, excluding id: UUID?) -> [ButtonMapping] {
        mappings.filter { $0.button == button && $0.id != id }
    }

    /// 同一配置的同一按键只保留一个绑定，包含已禁用的旧绑定。
    @discardableResult
    mutating func storeMapping(_ mapping: ButtonMapping, replacingConflicts: Bool = false) -> Bool {
        let conflicts = mappingConflicts(for: mapping.button, excluding: mapping.id)
        guard conflicts.isEmpty || replacingConflicts else { return false }
        let insertionIndex = mappings.firstIndex(where: { $0.id == mapping.id || $0.button == mapping.button }) ?? mappings.count
        mappings.removeAll { $0.id == mapping.id || $0.button == mapping.button }
        mappings.insert(mapping, at: min(insertionIndex, mappings.count))
        return true
    }

    /// 检查是否匹配给定的应用
    func matches(bundleID: String, appName: String) -> Bool {
        if appRules.isEmpty {
            return name == "全局配置"
        }

        return appRules.contains { $0.matches(bundleID: bundleID, appName: appName) }
    }

    @discardableResult
    mutating func addAppRule(_ rule: AppRule) -> Bool {
        guard let normalized = rule.normalized,
              !appRules.contains(where: { $0.isEquivalent(to: normalized) }) else { return false }
        appRules.append(normalized)
        return true
    }

    static func preferredProfile(in profiles: [Profile], bundleID: String, appName: String) -> Profile? {
        // 全局配置只兜底，精确 Bundle ID 比名称包含匹配更具体。
        let explicit = profiles.filter { !$0.appRules.isEmpty && $0.matches(bundleID: bundleID, appName: appName) }
        return explicit.first(where: { profile in
            profile.appRules.contains { rule in
                if case .bundleID = rule { return rule.matches(bundleID: bundleID, appName: appName) }
                return false
            }
        }) ?? explicit.first ?? profiles.first(where: { $0.name == "全局配置" })
    }
}

/// 应用匹配规则
enum AppRule: Codable, Equatable {
    case bundleID(String)
    case appName(String)

    var normalized: AppRule? {
        let value: String
        switch self {
        case .bundleID(let id): value = id.trimmingCharacters(in: .whitespacesAndNewlines)
        case .appName(let name): value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !value.isEmpty else { return nil }
        if case .bundleID = self { return .bundleID(value) }
        return .appName(value)
    }

    func isEquivalent(to other: AppRule) -> Bool {
        switch (normalized, other.normalized) {
        case (.bundleID(let lhs)?, .bundleID(let rhs)?), (.appName(let lhs)?, .appName(let rhs)?):
            return lhs.caseInsensitiveCompare(rhs) == .orderedSame
        default: return false
        }
    }

    func matches(bundleID: String, appName: String) -> Bool {
        switch normalized {
        case .bundleID(let id): return bundleID.caseInsensitiveCompare(id) == .orderedSame
        case .appName(let name): return appName.localizedCaseInsensitiveContains(name)
        case nil: return false
        }
    }
    
    var displayString: String {
        switch self {
        case .bundleID(let id):
            return "Bundle ID: \(id)"
        case .appName(let name):
            return "App: \(name)"
        }
    }
}

/// 摇杆设置
struct StickSettings: Codable {
    var leftStickMode: StickMode
    var rightStickMode: StickMode
    var deadzone: Float  // 0.0-1.0
    var sensitivity: Float  // 0.1-5.0
    var accelerationCurve: AccelerationCurve
    
    init(
        leftStickMode: StickMode = .mouse,
        rightStickMode: StickMode = .scroll,
        deadzone: Float = 0.15,
        sensitivity: Float = 1.0,
        accelerationCurve: AccelerationCurve = .linear
    ) {
        self.leftStickMode = leftStickMode
        self.rightStickMode = rightStickMode
        self.deadzone = deadzone
        self.sensitivity = sensitivity
        self.accelerationCurve = accelerationCurve
    }
    
    enum StickMode: String, Codable {
        case mouse = "鼠标移动"
        case scroll = "滚轮"
        case disabled = "禁用"
    }
    
    enum AccelerationCurve: String, Codable, CaseIterable {
        case linear = "线性"
        case accelerated = "加速"
        case precise = "精确"
        
        func apply(_ value: Float) -> Float {
            switch self {
            case .linear:
                return value
            case .accelerated:
                return value * abs(value)  // 平方曲线
            case .precise:
                return value * 0.5  // 降低速度
            }
        }
    }
}
