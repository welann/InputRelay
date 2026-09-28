import CoreGraphics
import Testing
@testable import InputRelay

struct DesktopGeometryTests {
    private let main = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    @Test func crossesRightAndLeftDisplays() {
        let right = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
        let left = CGRect(x: -1280, y: 100, width: 1280, height: 800)
        for point in [CGPoint(x: 1920, y: 500), CGPoint(x: 2300, y: 700), CGPoint(x: -100, y: 400)] {
            #expect(DesktopGeometry.constrain(point, to: [main, left, right]) == point)
        }
    }

    @Test func crossesVerticallyStackedDisplays() {
        let above = CGRect(x: 100, y: -1200, width: 1920, height: 1200)
        let below = CGRect(x: 0, y: 1080, width: 1280, height: 720)
        for point in [CGPoint(x: 500, y: -300), CGPoint(x: 500, y: 1250)] {
            #expect(DesktopGeometry.constrain(point, to: [main, above, below]) == point)
        }
    }

    @Test func avoidsEmptyDesktopCornersAndClampsOutsideEdges() {
        let right = CGRect(x: 1920, y: 500, width: 1280, height: 720)
        #expect(DesktopGeometry.constrain(CGPoint(x: 2200, y: 100), to: [main, right]) == CGPoint(x: 1919, y: 100))
        #expect(DesktopGeometry.constrain(CGPoint(x: 4000, y: 600), to: [main, right]) == CGPoint(x: 3199, y: 600))
        #expect(DesktopGeometry.constrain(CGPoint(x: -200, y: -300), to: [main]) == .zero)
    }

    @Test func reactsToDisconnectedDisplay() {
        let point = CGPoint(x: 2300, y: 700)
        #expect(DesktopGeometry.constrain(point, to: [main]) == CGPoint(x: 1919, y: 700))
        #expect(DesktopGeometry.constrain(point, to: []) == point)
    }

    @Test func simulatorUsesLiveCursorForCrossingAndClicking() {
        var cursor = CGPoint(x: 1915, y: 400)
        let right = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
        var events: [CGEvent] = []
        let simulator = MouseSimulator(cursorLocation: { cursor }, displayBounds: { [main, right] },
                                       postEvent: { events.append($0) })
        simulator.moveMouse(dx: 20, dy: 0)
        #expect(events.last?.location == CGPoint(x: 1935, y: 400))
        // 用户用真实鼠标换了位置；手柄必须从新位置继续，而不是跳回旧坐标。
        cursor = CGPoint(x: 3000, y: 800)
        simulator.moveMouse(dx: -10, dy: 15)
        #expect(events.last?.location == CGPoint(x: 2990, y: 815))
        cursor = CGPoint(x: 2500, y: 100)
        simulator.click(.left)
        #expect(events.suffix(2).allSatisfy { $0.location == cursor })
        #expect(events.suffix(2).map(\.type) == [.leftMouseDown, .leftMouseUp])
    }
}
