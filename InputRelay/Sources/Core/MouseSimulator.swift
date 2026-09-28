import Foundation
import AppKit
import CoreGraphics

/// 鼠标模拟器 - 负责模拟鼠标移动和点击
class MouseSimulator {
    private var currentPosition: CGPoint = .zero
    private var lastUpdateTime: TimeInterval = 0
    
    init() {
        // 获取当前鼠标位置
        if let event = CGEvent(source: nil) {
            currentPosition = event.location
        }
    }
    
    /// 移动鼠标（相对移动）
    func moveMouse(dx: CGFloat, dy: CGFloat) {
        currentPosition.x += dx
        currentPosition.y += dy
        
        // 限制在屏幕范围内，避免指针漂移到屏幕外后失去响应
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let frame = screen.frame
            currentPosition.x = max(0, min(currentPosition.x, frame.width))
            currentPosition.y = max(0, min(currentPosition.y, frame.height))
        }
        
        // 创建鼠标移动事件
        if let event = CGEvent(mouseEventSource: nil,
                              mouseType: .mouseMoved,
                              mouseCursorPosition: currentPosition,
                              mouseButton: .left) {
            event.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }
    
    /// 模拟鼠标点击
    func click(_ button: CGMouseButton, at position: CGPoint? = nil) {
        let pos = position ?? currentPosition
        
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
            downEvent.post(tap: .cghidEventTap)
        }
        
        // 短暂延迟
        usleep(10_000)  // 10ms
        
        // 抬起
        if let upEvent = CGEvent(mouseEventSource: nil,
                                mouseType: upType,
                                mouseCursorPosition: pos,
                                mouseButton: button) {
            upEvent.post(tap: .cghidEventTap)
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
            event.post(tap: .cghidEventTap)
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
        
        // 限制更新频率（60 FPS）
        let now = Date().timeIntervalSince1970
        if now - lastUpdateTime >= 1.0 / 60.0 {
            moveMouse(dx: dx, dy: dy)
            lastUpdateTime = now
        }
    }
}
