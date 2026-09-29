import Combine
import Foundation
import AppKit
import CoreGraphics

/// 鼠标模拟器 - 负责模拟鼠标移动和点击
class MouseSimulator {
    private var currentPosition: CGPoint = .zero
    private let cursorLocation: () -> CGPoint?
    private let displayBounds: () -> [CGRect]
    private let postEvent: (CGEvent) -> Void
    private let postSequence: ([CGEvent], Int) -> Void
    private var screenObservation: AnyCancellable?
    private var cachedDisplayBounds: [CGRect]
    private var displayBoundsDirty = false
    private var movementRemainder = CGPoint.zero
    private var scrollRemainder: Double = 0
    
    init(
        cursorLocation: @escaping () -> CGPoint? = { CGEvent(source: nil)?.location },
        displayBounds: @escaping () -> [CGRect] = { DesktopGeometry.activeDisplayBounds() },
        postEvent: ((CGEvent) -> Void)? = nil
    ) {
        self.cursorLocation = cursorLocation
        self.displayBounds = displayBounds
        self.cachedDisplayBounds = displayBounds()
        self.postEvent = postEvent ?? { $0.post(tap: .cghidEventTap) }
        self.postSequence = postEvent.map { sink in { events, _ in events.forEach(sink) } }
            ?? { InputEventSequence.post($0, pauseBefore: $1) }
        currentPosition = cursorLocation() ?? .zero
        screenObservation = NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.invalidateDisplayBounds() }
    }

    func invalidateDisplayBounds() { displayBoundsDirty = true }

    func resetMotion() {
        movementRemainder = .zero
        scrollRemainder = 0
    }
    
    /// 移动鼠标（相对移动）
    func moveMouse(dx: CGFloat, dy: CGFloat) {
        // 系统光标位置可能被取整；累积不足一个坐标单位的位移，避免低速输入丢失。
        let totalX = dx + movementRemainder.x
        let totalY = dy + movementRemainder.y
        let stepX = totalX.rounded(.towardZero)
        let stepY = totalY.rounded(.towardZero)
        movementRemainder = CGPoint(x: totalX - stepX, y: totalY - stepY)
        guard stepX != 0 || stepY != 0 else { return }
        let origin = cursorLocation() ?? currentPosition
        let proposed = CGPoint(x: origin.x + stepX, y: origin.y + stepY)
        if displayBoundsDirty {
            cachedDisplayBounds = displayBounds()
            displayBoundsDirty = false
        }
        currentPosition = DesktopGeometry.constrain(proposed, to: cachedDisplayBounds)
        
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
        
        // Create the pair before posting so allocation failure cannot leave a held button.
        guard let down = CGEvent(mouseEventSource: nil, mouseType: downType,
                                 mouseCursorPosition: pos, mouseButton: button),
              let up = CGEvent(mouseEventSource: nil, mouseType: upType,
                               mouseCursorPosition: pos, mouseButton: button) else { return }
        postSequence([down, up], 1)
    }
    
    /// 模拟滚轮滚动
    /// - Parameter deltaY: 滚动量，正数向上、负数向下（单位：像素）
    func scroll(deltaY: Double) {
        guard deltaY.isFinite else { return }
        if deltaY == 0 {
            scrollRemainder = 0
            return
        }
        if scrollRemainder * deltaY < 0 { scrollRemainder = 0 }
        let total = deltaY + scrollRemainder
        let pixels = total.rounded(.towardZero)
        scrollRemainder = total - pixels
        guard pixels != 0 else { return }
        if let event = CGEvent(scrollWheelEvent2Source: nil,
                              units: .pixel,
                              wheelCount: 1,
                              wheel1: Int32(clamping: Int64(pixels)),
                              wheel2: 0,
                              wheel3: 0) {
            event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
            postEvent(event)
        }
    }
    
    /// 处理摇杆输入并转换为鼠标移动
    func handleStickInput(x: Float, y: Float, sensitivity: Float, curve: StickSettings.AccelerationCurve, deadzone: Float, elapsed: TimeInterval = 1.0 / 60.0) {
        // 应用死区
        let magnitude = sqrt(x * x + y * y)
        guard magnitude > deadzone else {
            movementRemainder = .zero
            return
        }
        
        // 归一化并重新映射死区外的值
        let normalizedX = x / magnitude
        let normalizedY = y / magnitude
        let adjustedMagnitude = (min(magnitude, 1) - deadzone) / (1.0 - deadzone)
        
        // 应用加速曲线
        let curvedMagnitude = curve.apply(adjustedMagnitude)
        
        // 计算最终速度
        let baseSpeed: CGFloat = 600.0 * CGFloat(elapsed)
        let dx = CGFloat(normalizedX * curvedMagnitude) * baseSpeed * CGFloat(sensitivity)
        let dy = CGFloat(normalizedY * curvedMagnitude) * baseSpeed * CGFloat(sensitivity)
        
        // 保持原先满速 600 单位/秒，不随采样频率变化。
        moveMouse(dx: dx, dy: dy)
    }
}
