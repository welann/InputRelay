import Foundation
import Carbon

/// 映射动作类型
enum MappingAction: Codable, Equatable {
    case keyboardShortcut(KeyboardShortcut)
    case mouseAction(MouseAction)
    case customScript(String)
    case mouseMovement(axis: MouseAxis, sensitivity: Float)
    
    enum MouseAxis: String, Codable {
        case horizontal
        case vertical
    }

    var displayName: String {
        switch self {
        case .keyboardShortcut(let shortcut): return shortcut.displayString
        case .mouseAction(let action): return action.rawValue
        case .customScript(let script): return "脚本: \(script.prefix(30))"
        case .mouseMovement(let axis, _): return "鼠标\(axis == .horizontal ? "水平" : "垂直")移动"
        }
    }
}

/// 鼠标动作
enum MouseAction: String, Codable {
    case leftClick = "Left Click"
    case rightClick = "Right Click"
    case middleClick = "Middle Click"
    case scrollUp = "Scroll Up"
    case scrollDown = "Scroll Down"
}

/// 单个按键的映射配置
struct ButtonMapping: Codable, Identifiable {
    let id: UUID
    let button: GamepadButton
    var action: MappingAction
    var enabled: Bool
    
    init(id: UUID = UUID(), button: GamepadButton, action: MappingAction, enabled: Bool = true) {
        self.id = id
        self.button = button
        self.action = action
        self.enabled = enabled
    }
}
