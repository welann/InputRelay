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
        rawValue
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
    let value: Float  // 0.0-1.0，按键为 0 或 1，摇杆为 -1.0 到 1.0
    let timestamp: TimeInterval
    
    var isPressed: Bool {
        value > 0.5
    }
}
