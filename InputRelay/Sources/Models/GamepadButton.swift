import Foundation

/// 定义手柄上的所有可用按键和轴
enum GamepadButton: String, Codable, CaseIterable {
    // 面键
    case buttonA = "A"
    case buttonB = "B"
    case buttonX = "X"
    case buttonY = "Y"
    
    // 肩键
    case leftShoulder = "L1"
    case rightShoulder = "R1"
    
    // 扳机键
    case leftTrigger = "L2"
    case rightTrigger = "R2"
    
    // 方向键
    case dpadUp = "D-Up"
    case dpadDown = "D-Down"
    case dpadLeft = "D-Left"
    case dpadRight = "D-Right"
    
    // 摇杆按下
    case leftStickButton = "L3"
    case rightStickButton = "R3"
    
    // 系统按键
    case selectButton = "Select"
    case startButton = "Start"
    case homeButton = "Home"
    
    // 摇杆轴（虚拟按键，用于配置）
    case leftStickUp = "LS-Up"
    case leftStickDown = "LS-Down"
    case leftStickLeft = "LS-Left"
    case leftStickRight = "LS-Right"
    case rightStickUp = "RS-Up"
    case rightStickDown = "RS-Down"
    case rightStickLeft = "RS-Left"
    case rightStickRight = "RS-Right"
    
    var displayName: String {
        // 保留旧 rawValue，已有 JSON 配置无需迁移。
        switch self {
        case .leftShoulder: return "LB"
        case .rightShoulder: return "RB"
        case .leftTrigger: return "LT"
        case .rightTrigger: return "RT"
        case .leftStickButton: return "LS"
        case .rightStickButton: return "RS"
        case .selectButton: return "View"
        case .startButton: return "Menu"
        case .homeButton: return "Xbox"
        default: return rawValue
        }
    }
    
    var isStickAxis: Bool {
        switch self {
        case .leftStickUp, .leftStickDown, .leftStickLeft, .leftStickRight,
             .rightStickUp, .rightStickDown, .rightStickLeft, .rightStickRight:
            return true
        default:
            return false
        }
    }
}

/// 手柄输入事件
struct GamepadEvent {
    let button: GamepadButton
    let value: Float  // 0.0-1.0；摇杆方向拆成各自的正向幅度。
    let timestamp: TimeInterval
    
    var isPressed: Bool {
        value > 0.5
    }
}
