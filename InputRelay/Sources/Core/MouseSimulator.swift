import Foundation
import AppKit
import CoreGraphics

/// 鼠标模拟器 - 负责模拟鼠标移动和点击
class MouseSimulator {
    private var currentPosition: CGPoint = .zero
    private let cursorLocation: () -> CGPoint?
    private let displayBounds: () -> [CGRect]
    private let postEvent: (CGEvent) -> Void
    
    init(
        cursorLocation: @escaping () -> CGPoint? = { CGEvent(source: nil)?.location },
        displayBounds: @escaping () -> [CGRect] = { DesktopGeometry.activeDisplayBounds() },
        postEvent: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) }
    ) {
        self.cursorLocation = cursorLocation
        self.displayBounds = displayBounds
        self.postEvent = postEvent
        currentPosition = cursorLocation() ?? .zero
    }
    
    /// 移动鼠标（相对移动）
    func moveMouse(dx: CGFloat, dy: CGFloat) {
        let origin = cursorLocation() ?? currentPosition
        let proposed = CGPoint(x: origin.x + dx, y: origin.y + dy)
        currentPosition = DesktopGeometry.constrain(proposed, to: displayBounds())
        
        // 创建鼠标移动事件
        if let event = CGEvent(mouseEventSource: nil,
                              mouseType: .mouseMoved,
                              mouseCursorPosition: currentPosition,
                              mouseButton: .left) {
            postEvent(event)
        }
    }
    
    /// 模拟鼠标点击
    func click(_ button: CGMouseButton, at position: CGPoint? = nil) {
        let pos = position ?? cursorLocation() ?? currentPosition
        currentPosition = pos
        
        let downType: CGEventType
        let upType: CGEventType
        
        switch button {
        case .left:
            downType = .leftMouseDown
            upType = .leftMouseUp
        case .right:
            downType = .rightMouseDown
            upType = .rightMouseUp
        case .center:
            downType = .otherMouseDown
            upType = .otherMouseUp
        @unknown default:
            return
        }
        
        // 按下
        if let downEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: downType,
                                   mouseCursorPosition: pos,
                                   mouseButton: button) {
            postEvent(downEvent)
        }
        
        // 短暂延迟
        usleep(10_000)  // 10ms
        
        // 抬起
        if let upEvent = CGEvent(mouseEventSource: nil,
                                mouseType: upType,
                                mouseCursorPosition: pos,
                                mouseButton: button) {
            postEvent(upEvent)
        }
    }
    
    /// 模拟滚轮滚动
    /// - Parameter deltaY: 滚动量，正数向上、负数向下（单位：像素）
    func scroll(deltaY: Int32) {
        if let event = CGEvent(scrollWheelEvent2Source: nil,
                              units: .pixel,
                              wheelCount: 1,
                              wheel1: deltaY,
                              wheel2: 0,
                              wheel3: 0) {
            postEvent(event)
        }
    }
    
    /// 处理摇杆输入并转换为鼠标移动
    func handleStickInput(x: Float, y: Float, sensitivity: Float, curve: StickSettings.AccelerationCurve, deadzone: Float) {
        // 应用死区
        let magnitude = sqrt(x * x + y * y)
        guard magnitude > deadzone else { return }
        
        // 归一化并重新映射死区外的值
        let normalizedX = x / magnitude
        let normalizedY = y / magnitude
        let adjustedMagnitude = (magnitude - deadzone) / (1.0 - deadzone)
        
        // 应用加速曲线
        let curvedMagnitude = curve.apply(adjustedMagnitude)
        
        // 计算最终速度
        let baseSpeed: CGFloat = 10.0
        let dx = CGFloat(normalizedX * curvedMagnitude) * baseSpeed * CGFloat(sensitivity)
        let dy = CGFloat(normalizedY * curvedMagnitude) * baseSpeed * CGFloat(sensitivity)
        
        // GamepadManager 已按 60 Hz 驱动，避免再次限频丢帧。
        moveMouse(dx: dx, dy: dy)
    }
}
