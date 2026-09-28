import CoreGraphics

enum DesktopGeometry {
    static func activeDisplayBounds() -> [CGRect] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displays, &count) == .success else { return [] }
        // 与 CGEvent.location 使用相同的 Quartz 全局坐标，支持负原点和上下排列。
        return displays.prefix(Int(count)).map { CGDisplayBounds($0) }
    }

    static func constrain(_ point: CGPoint, to displays: [CGRect]) -> CGPoint {
        let displays = displays.filter { !$0.isEmpty && !$0.isInfinite && !$0.isNull }
        if displays.contains(where: { $0.contains(point) }) { return point }
        // 只允许实际屏幕区域；整个桌面的包围矩形可能包含没有显示器的空洞。
        return displays.map { bounds in
            CGPoint(x: min(max(point.x, bounds.minX), bounds.maxX - 1),
                    y: min(max(point.y, bounds.minY), bounds.maxY - 1))
        }.min { lhs, rhs in
            squaredDistance(lhs, point) < squaredDistance(rhs, point)
        } ?? point
    }

    private static func squaredDistance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }
}
