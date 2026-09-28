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
    
    /// 检查是否匹配给定的应用
    func matches(bundleID: String, appName: String) -> Bool {
        if appRules.isEmpty {
            return name == "全局配置"
        }
        
        return appRules.contains { rule in
            switch rule {
            case .bundleID(let pattern):
                return bundleID.localizedCaseInsensitiveContains(pattern)
            case .appName(let pattern):
                return appName.localizedCaseInsensitiveContains(pattern)
            }
        }
    }
}

/// 应用匹配规则
enum AppRule: Codable, Equatable {
    case bundleID(String)
    case appName(String)
    
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
